require 'date'
require 'yaml'

module Rys
  module Bundler
    module Commands
      class Build < Base

        COMMENT_PREFIX = '# RYS_BUILDER #'

        attr_reader :options

        def self.run(args)
          options = OpenStruct.new
          options.deployment = false
          options.submodules = false
          options.redmine_plugin = nil

          OptionParser.new do |opts|
            opts.banner = 'Usage: bundle rys build [options]'

            opts.on('-d', '--deployment', 'Prepare gems for deployment') do |value|
              options.deployment = value
            end

            # Quite a dangerous switch so do not add a short switch!!!
            opts.on('--revert', 'Revert build (dangerous operation)') do |value|
              options.revert = value
            end

            opts.on('-s', '--submodules', 'Add gems as submodules (experimental)') do |value|
              options.submodules = value
              abort('Not yet implemented')
            end

            opts.on('-r', '--redmine-plugin PATH', 'Redmine plugin for rys gems') do |value|
              options.redmine_plugin = Pathname.new(value)
            end

            opts.on_tail('-h', '--help', 'Show this message') do
              puts opts
              exit
            end

            opts.on_tail('-v', '--version', 'Show version') do
              puts ::Rys::Bundler::VERSION
              exit
            end
          end.parse(args)

          if options.deployment
            klass = BuildDeployment
          else
            klass = BuildLocal
          end

          instance = klass.new(options)

          if options.revert
            instance.run_revert
          else
            instance.run
          end
        end

        def initialize(options)
          @options = options
        end

        def run
          prepare_target
          prepare_to_copy
          copy_dependencies
          comment_copied
          save_report

          ui.info ''
          ui.info 'You may want run bundle install again (just for sure)'
        end

        def run_revert
          prepare_target
          prepare_to_delete
          delete_dependencies
          uncomment_deleted
          delete_report
        end

        private

          def short_filename(path)
            path.each_filename.to_a.last(2).join('/')
          end

          def build_yml
            @target.join('build.yml')
          end

          def print_gem_status(name, status)
            ui.info (name + ' ').ljust(@dependency_ljust, '.') + " #{status}"
          end

          def prepare_target
            if options.redmine_plugin&.directory?
              @redmine_plugin = options.redmine_plugin
            else
              @redmine_plugin = get_redmine_plugin!
            end

            @target = @redmine_plugin.join(default_target_dir)
            FileUtils.mkdir_p(@target)
          end

          def prepare_to_copy
            all_dependencies = ::Bundler.load.dependencies
            @dependencies = all_dependencies.select do |dependency|
              dependency.groups.include?(:rys)
            end
            @dependency_ljust = @dependencies.map{|d| d.name.size }.max.to_i + 4
          end

          def prepare_to_delete
            @dependency_ljust = build_report.keys.map{|d| d.size }.max.to_i + 4
          end

          # Copy/clone/symlink/... all dependencies into proper directory
          def copy_dependencies
            @copied_gems = []

            @dependencies.each do |dependency|
              source = dependency.source
              path = @target.join(dependency.name)

              # This could happend if gem is loaded from `@target`
              if path.directory?
                print_gem_status(dependency.name, 'already exist')
                next
              end

              case source
              when ::Bundler::Source::Git
                build_gem_from_git(dependency, source, path)
                @copied_gems << dependency.name

              when ::Bundler::Source::Path
                build_gem_from_path(dependency, source, path)
                @copied_gems << dependency.name

              else
                print_gem_status(dependency.name, 'be resolved automatically')
              end
            end
          end

          def delete_dependencies
            build_report.each do |gem_name, options|
              path = @target.join(gem_name)

              if File.symlink?(path)
                FileUtils.rm(path)
                print_gem_status(gem_name, 'symlink removed')
              elsif File.directory?(path)
                FileUtils.rm_rf(path)
                print_gem_status(gem_name, 'directory removed')
              else
                print_gem_status(gem_name, 'not symlink or directory')
              end
            end
          end

          def comment_copied
            if @copied_gems.size == 0
              return
            end

            ui.info ''
            ui.info pastel.bold('Commenting gems')
            ::Bundler.definition.gemfiles.each do |gemfile|
              gem_names = comment_gems_in(gemfile)

              if gem_names.size > 0
                gemfile_relative = gemfile.relative_path_from(::Bundler.root)
                gem_names.each do |name|
                  build_report[name] = { 'origin' => gemfile_relative.to_s }
                end
              end

              ui.info "* #{short_filename(gemfile)}: #{gem_names.size} occurrences"
            end
          end

          def uncomment_deleted
            ui.info ''
            ui.info pastel.bold('Uncommenting gems')

            all_origins = Hash.new { |hash, origin| hash[origin] = [] }

            build_report.each do |gem_name, options|
              all_origins[options['origin']] << gem_name
            end

            all_origins.each do |origin, gem_names|
              origin_gemfile = ::Bundler.root.join(origin)

              if origin_gemfile.exist?
                gem_names = uncomment_gems_in(origin_gemfile, gem_names)
                ui.info "* #{short_filename(origin_gemfile)}: #{gem_names.size} occurrences"
              else
                ui.info "* #{short_filename(origin_gemfile)}: not exist"
              end
            end
          end

          def build_report
            @build_report ||= begin
              if build_yml.exist?
                YAML.load_file(build_yml)
              else
                {}
              end
            end
          end

          def save_report
            report  = %{# This file was generated by Rys::Bundler at #{Time.now}\n}
            report << %{# Modify file at your own risk\n}
            report << build_report.to_yaml

            build_yml.write(report)
          end

          def delete_report
            build_yml.exist? && build_yml.delete
          end

          def comment_gems_in(path)
            @comment_gems_pattern ||= /^(\s*)([^#|\n]*gem[ ]+["'](#{@copied_gems.join('|')})["'])/

            names = []
            content = File.binread(path)
            content.gsub!(@comment_gems_pattern) do
              names << $3
              %{#{$1}#{COMMENT_PREFIX} #{$2}}
            end

            File.open(path, 'wb') { |file| file.write(content) }
            names.uniq!
            names
          end

          def uncomment_gems_in(path, gem_names)
            pattern = /^(\s*)#{COMMENT_PREFIX}[ ]*(gem[ ]+["'](#{gem_names.join('|')})["'])/

            names = []
            content = File.binread(path)
            content.gsub!(pattern) do
              names << $3
              %{#{$1}#{$2}}
            end

            File.open(path, 'wb') { |file| file.write(content) }
            names.uniq!
            names
          end

      end
    end
  end
end

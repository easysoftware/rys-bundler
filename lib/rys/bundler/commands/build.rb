module Rys
  module Bundler
    module Commands
      class Build < Base

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
            BuildDeployment.new(options).run
          else
            BuildLocal.new(options).run
          end
        end

        def initialize(options)
          @options = options
        end

        def run
          prepare_target
          prepare_dependencies
          build
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

        def prepare_dependencies
          @dependencies = ::Bundler.load.dependencies.select do |dependency|
            dependency.groups.include?(:rys)
          end

          @gem_name_ljust = @dependencies.map{|d| d.name.size }.max + 4
        end

        def print_dependency_status(dependency, status)
          ui.info (dependency.name + ' ').ljust(@gem_name_ljust, '.') + " #{status}"
        end

        def build
          new_gems_names = []

          @dependencies.each do |dependency|
            source = dependency.source
            path = @target.join(dependency.name)

            if path.directory?
              print_dependency_status(dependency, 'already exist')
              next
            end

            case source
            when ::Bundler::Source::Git
              build_gem_from_git(dependency, source, path)
              new_gems_names << dependency.name

            when ::Bundler::Source::Path
              build_gem_from_path(dependency, source, path)
              new_gems_names << dependency.name

            else
              print_dependency_status(dependency, 'be resolved automatically')
            end
          end

          if new_gems_names.any?
            patterns = []
            new_gems_names.each do |name|
              patterns << %{gem "#{name}"}
              patterns << %{gem '#{name}'}
            end
            patterns = /(#{patterns.join('|')})/

            ui.info ''
            ui.info pastel.bold('Commenting gems')
            ::Bundler.definition.gemfiles.each do |gemfile|
              count = comment_lines(gemfile, patterns)
              gemfile_name = gemfile.each_filename.to_a.last(2).join('/')
              ui.info "* #{gemfile_name}: #{count} occurrences"
            end
          end

          ui.info ''
          ui.info 'You may want run bundle install again (just for sure)'
        end

      end
    end
  end
end

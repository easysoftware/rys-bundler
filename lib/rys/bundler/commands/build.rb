module Rys
  module Bundler
    module Commands
      class Build < Base

        def run
          options.local = true
          options.deployment = false
          options.submodules = false
          options.redmine_plugin = nil

          @option_parser = OptionParser.new do |opts|
            opts.banner = 'Usage: bundle rys build [options]'

            opts.on('-l', '--local', 'Place gems into local/ (git-ignored)') do |value|
              options.local = value
            end

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
          end
          @option_parser.parse(@args)

          if options.redmine_plugin&.directory?
            @redmine_plugin = options.redmine_plugin
          else
            @redmine_plugin = get_redmine_plugin!
          end

          if options.deployment
            @target = @redmine_plugin.join('gems')
          elsif options.local
            @target = @redmine_plugin.join('local')
          else
            abort('You have to choose --local or --deployment')
          end

          FileUtils.mkdir_p(@target)

          @dependencies = ::Bundler.load.dependencies.select do |dependency|
            dependency.groups.include?(:rys)
          end

          @gem_name_ljust = @dependencies.map{|d| d.name.size }.max + 4

          build
        end

        def gem_from_git(dependency, source, path)
          if options.deployment
            if source.send(:local?)
              FileUtils.cp_r(source.path, path)
              print_dependency_status(dependency, 'copied')
            else
              command %{git clone --depth=1 --branch="#{source.branch}" "#{source.uri}" "#{path}"}
              print_dependency_status(dependency, 'clonned')
            end

            FileUtils.rm_rf(path.join('.git'))
          else
            if source.send(:local?)
              path.make_symlink(source.path)
              print_dependency_status(dependency, 'symlinked')
            else
              command %{git clone --branch="#{source.branch}" "#{source.uri}" "#{path}"}
              print_dependency_status(dependency, 'clonned')
            end
          end
        end

        def gem_from_path(dependency, source, path)
          if options.deployment
            FileUtils.cp_r(source.path, path)
            print_dependency_status(dependency, 'copied')
          else
            path.make_symlink(source.path)
            print_dependency_status(dependency, 'symlinked')
          end
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
              gem_from_git(dependency, source, path)
              new_gems_names << dependency.name

            when ::Bundler::Source::Path
              gem_from_path(dependency, source, path)
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
              ui.info "* #{gemfile.basename}: #{count} occurrences"
            end
          end

          ui.info ''
          ui.info 'You may want run bundle install again (just for sure)'
        end

      end
    end
  end
end

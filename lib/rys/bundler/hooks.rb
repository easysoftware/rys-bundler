##
# Dependencies tree can look like this
# (except it is even worse)
#
# You have to ensure that local dependencies (gemfile: `path: '...'`) are
# resolved prior to remote dependencies (gemfile: `git: '...'`) because not
# all users have rights for the repository (that is why packages are created).
#
#   gems.rb
#   |-- easy_twofa (local)
#   |   |-- rys (remote)
#   |   `-- easy_core (remote)
#   |-- easy_contacts (local)
#   |   |-- easy_query (remote)
#   |   |   |-- rys (remote)
#   |   |   `-- easy_core(remote)
#   |   |-- rys (remote)
#   |   `-- easy_core (remote)
#   |-- rys (local)
#   |-- easy_core (local)
#   |   `-- rys (remote)
#   |-- tty-prompt (remote)
#   `-- easy_query (local)
#       |-- easy_core (remote)
#       `-- rys (remote)
#
module Rys
  module Bundler
    module Hooks

      # Recursively searches for dependencies
      # If there will be same dependencies => first won
      #
      # == Arguments:
      # dependencies:: Array of dependencies which should be resolved
      # new_dependencies:: All dependencies from resolving
      #                    Array is in-place modified
      # resolved_dependencies:: Already resolved dependencies
      #                        For preventing loops
      #
      def self.resolve_rys_dependencies(dependencies, new_dependencies, resolved_dependencies)
        dependencies = prepare_dependencies_for_next_round(dependencies, resolved_dependencies)

        # Resolving is done in next round
        next_dependencies_to_resolve = []

        dependencies.each do |dependency|
          # To allow resolving
          dependency.source.remote!

          # Ensure gem (downloaded if necessary)
          dependency.source.specs

          # Get dependencies from this file using rys group
          dependencies_rb = dependency.source.path.join('dependencies.rb')

          if dependencies_rb.exist?
            definition = ::Bundler::Dsl.evaluate(dependencies_rb, ::Bundler.default_lockfile, true)
            rys_group_dependencies = definition.dependencies.select{|dep| dep.groups.include?(:rys) }

            new_dependencies.concat(rys_group_dependencies)
            next_dependencies_to_resolve.concat(rys_group_dependencies)
          end

          resolved_dependencies << dependency
          # add_source_definition(dependency, ::Bundler.definition)
        end

        if next_dependencies_to_resolve.size > 0
          resolve_rys_dependencies(next_dependencies_to_resolve, new_dependencies, resolved_dependencies)
        end
      end

      # Be careful!!!
      # There is a lot of possibilities for gem definition
      #
      #   1. Normal gem
      #   2. Gem on git (download)
      #   3. Gem on git (not-downloaded)
      #   4. Gem on git locally overriden
      #   5. Gem on local disk
      #
      def self.before_install_all(dependencies)
        new_dependencies = []
        resolved_dependencies = []

        # To avoid multiple `git clone` on the same folder
        ::Bundler::ProcessLock.lock do
          resolve_rys_dependencies(dependencies, new_dependencies, resolved_dependencies)
        end

        # Select only missing dependencies so user can
        # rewrite each dependecny in main gems.rb
        new_dependencies = new_dependencies.uniq(&:name)
        new_dependencies.reject! do |dep1|
          dependencies.any? do |dep2|
            dep1.name == dep2.name && !dep2.groups.include?(:__dependencies__)
          end
        end

        # Adding sources from new dependecies
        # Needef for Path or Git
        new_dependencies.each do |dependency|
          next if !dependency.source
          sources = ::Bundler.definition.send(:sources).send(:source_list_for, dependency.source)
          sources << dependency.source
        end

        ::Bundler.ui.info "Added #{new_dependencies.size} new dependencies"

        # Concat them to main Bundler.definition.dependencies
        dependencies.concat(new_dependencies)

        # Save them for Bundler.require (rails config/boot.rb)
        save_new_dependencies(new_dependencies)

        # To ensure main bundler download plugins
        ::Bundler.definition.instance_eval do
          @dependency_changes = true
          # @local_changes = converge_locals
        end
      end

      def self.rys_gemfile(dsl)
        # Loading dependencies brings some troubles. For example if main
        # app add a gem which already exist as dependencies. There could
        # be conflicts. To avoid some of problems - dependencies are
        # loaded only if there is not a lock file (bundler wasn't
        # launched or user want force install).
        return if !::Bundler.root.join('gems.locked').exist? && !::Bundler.root.join('Gemfile.lock').exist?

        if gems_dependencies_rb.exist?
          # Mark gems as dependencies to be rewritten in a hook
          # Because you dont know if:
          #   - gems are loaded for rails
          #   - running bundle install
          #   - bundle exec
          #   - or something else
          dsl.group(:__dependencies__) do
            dsl.eval_gemfile(gems_dependencies_rb)
          end
        end
      end

      # Load gems from dummy path
      # Conflicts are ingnored
      #
      def self.rys_load_dummy(dsl, dummy_path=nil)
        possible_app_dirs = [
          dummy_path,
          ENV['DUMMY_PATH'],
          ::Bundler.root.join('test/dummy')
        ]

        possible_app_dirs.each do |dir|
          next if !dir
          next if !File.directory?(dir)

          ['Gemfile', 'gems.rb'].each do |gems_rb|
            gems_rb = File.expand_path(File.join(dir, gems_rb))

            if File.exist?(gems_rb)
              dsl.instance_eval do

                # Patch method `gem` to avoid duplicit definition
                # For example you can test rys 'ondra' but its
                # already included in main app gemfile.
                if is_a?(::Bundler::Plugin::DSL)
                  # gem methods is not defined here
                else
                  singleton_class.class_eval do
                    alias_method :original_gem, :gem
                  end

                  def gem(name, *args)
                    if @dependencies.any? {|d| d.name == name }
                      ::Bundler.ui.info "Skipping gem '#{name}' because already exist"
                    else
                      original_gem(name, *args)
                    end
                  end
                end

                eval_gemfile(gems_rb)
              end

              return
            end
          end
        end
      end

      def self.gems_dependencies_rb
        ::Bundler.root.join('gems.dependencies.rb')
      end

      def self.prepare_dependencies_for_next_round(dependencies, resolved_dependencies)
        dependencies = dependencies.dup

        # Prepare dependencies
        dependencies.keep_if do |dependency|
          dependency.groups.include?(:rys) &&
          dependency.source &&
          resolved_dependencies.none?{|rd| rd.name == dependency.name }
        end

        # Sort them to prior local dependencies
        dependencies.sort_by! do |dependency|
          case dependency.source
          # Git should be first because its inherit from Path
          when ::Bundler::Source::Git
            if dependency.source.send(:local?)
              1
            else
              3
            end
          # Local path
          when ::Bundler::Source::Path
            0
          # Rubygems, gemspec, metadata
          else
            2
          end
        end

        # More dependencies can depend on the same dependencies :-)
        dependencies.uniq!(&:name)

        return dependencies
      end

      def self.merge_definition_sources(from_definition, to_definition)
        to_sources = to_definition.send(:sources)

        from_definition.send(:sources).all_sources.map do |source|
          begin
            to_sources.send(:source_list_for, source) << source
          rescue
          end
        end
      end

      def self.add_source_definition(dependency, to_definition)
        sources = to_definition.send(:sources).send(:source_list_for, dependency.source)

        if sources.include?(dependency.source)
          # Already there
        else
          sources << dependency.source
        end
      rescue
        # Bundler could raise an ArgumentError
      end

      def self.save_new_dependencies(dependencies)
        File.open(gems_dependencies_rb, 'w') do |f|
          f.puts %{# This file was generated by Rys::Bundler at #{Time.now}}
          f.puts %{# Dependencies are generated after every `bundle` command}
          f.puts %{# Modify file at your own risk}
          f.puts

          dependencies.each do |dep|
            options = {}

            source = dep.source
            case source
            when ::Bundler::Source::Git
              options[:git] = source.uri
              options[:branch] = source.branch
              options[:ref] = source.ref
            when NilClass
              # Regular gem
            else
              raise "Unknow source '#{source.class}'"
            end

            args = []
            args << dep.name
            args.concat(dep.requirement.as_list)

            options[:groups] = dep.groups
            options[:require] = dep.autorequire if dep.autorequire

            gem_args = args.map{|arg| '"' + arg + '"' }.join(', ')

            f.puts %{if dependencies.none?{|dep| dep.name.to_s == "#{dep.name}" }}
            f.puts %{  gem #{gem_args}, #{options}}
            f.puts %{end}
            f.puts
          end
        end
      end

    end
  end
end

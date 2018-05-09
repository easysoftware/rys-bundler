module Rys
  module Bundler
    module Hooks

      # Recursively searches for dependencies
      # If there will be same dependecies => first won
      def self.dependencies_from_dependencies(dependencies, new_dependencies, resolved_dependecies)
        dependencies.each do |dependency|
          next if !dependency.groups.include?(:rys)
          next if !dependency.source

          # Main gemfile could contains gems which depends on the same dependecies
          if resolved_dependecies.any?{|nd| nd.name == dependency.name }
            next
          end

          # To allow resolving
          dependency.source.remote!

          # Ensure gem
          dependency.source.specs

          # Get dependecies from this file using rys group
          dependencies_rb = dependency.source.path.join('dependencies.rb')

          if dependencies_rb.exist?
            definition = ::Bundler::Dsl.evaluate(dependencies_rb, ::Bundler.default_lockfile, true)
            rys_dependecies = definition.dependencies.select{|dep| dep.groups.include?(:rys) }

            rys_dependecies.reject! do |rys_dependecy|
              new_dependencies.any?{|nd| nd.name == rys_dependecy.name }
            end

            new_dependencies.concat(rys_dependecies)
            resolved_dependecies << dependency
            dependencies_from_dependencies(rys_dependecies, new_dependencies, resolved_dependecies)

            # TODO: Maybe this should be done after `dependencies.concat`
            # merge_definition_sources(definition, ::Bundler.definition)

            add_source_definition(dependency, ::Bundler.definition)
          end
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
        resolved_dependecies = []
        dependencies_from_dependencies(dependencies, new_dependencies, resolved_dependecies)

        # Select only missing dependecies so user can
        # rewrite each dependecny in main gems.rb
        new_dependencies = new_dependencies.uniq(&:name)
        new_dependencies.reject! do |dep1|
          dependencies.any? do |dep2|
            dep1.name == dep2.name && !dep2.groups.include?(:__dependecies__)
          end
        end

        ::Bundler.ui.info "Added #{new_dependencies.size} new dependencies"

        # Concat them to main Bundler.definition.dependecies
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
        # Loading dependecies brings some troubles. For example if main
        # app add a gem which already exist as dependecies. There could
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
          dsl.group(:__dependecies__) do
            dsl.eval_gemfile(gems_dependencies_rb)
          end
        end
      end

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
              dsl.eval_gemfile(gems_rb)
              return
            end
          end
        end
      end

      def self.gems_dependencies_rb
        ::Bundler.root.join('gems.dependencies.rb')
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
        # Bunlder could raise an ArgumentError
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

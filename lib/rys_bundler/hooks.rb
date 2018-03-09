module RysBundler
  module Hooks

    def self.before_install_all(dependencies)
      plugin_dependencies = []

      dependencies.each do |dependency|
        next if !dependency.groups.include?(:rys)

        # To allow resolving
        dependency.source.remote!

        # Ensure gem
        dependency.source.specs

        # Get dependecies from this file using rys group
        gems_rb = dependency.source.path.join('gems.rb')

        if gems_rb.exist?
          definition = Bundler::Dsl.evaluate(gems_rb, Bundler.default_lockfile, true)
          plugin_dependencies.concat(definition.dependencies)
        end
      end

      plugin_dependencies = plugin_dependencies.uniq(&:name)
      plugin_dependencies.reject! do |dep1|
        dependencies.exist? do |dep2|
          dep1.name == dep2.name
        end
      end

      dependencies.concat(plugin_dependencies)

      # To ensure main budler download plugins
      # Bundler.definition.instance_eval{ @dependency_changes = true }
    end

  end
end

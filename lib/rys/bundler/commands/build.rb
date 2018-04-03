require 'open3'
require 'tty-prompt'

module Rys
  module Bundler
    module Commands
      class Build < Base

        def build_local
          ensure_redmine_plugin
          @target = @redmine_plugin.join('local')
          FileUtils.mkdir_p(@target)

          added_gems_names = []

          ::Bundler.load.dependencies.each do |dependency|
            next if !dependency.groups.include?(:rys)

            source = dependency.source
            path = @target.join(dependency.name)

            if path.directory?
              next
            end

            case source
            when ::Bundler::Source::Git
              if source.send(:local?)
                path.make_symlink(source.path)
                added_gems_names << dependency.name
                ui.info "#{dependency.name} ... symlinked"
              else
                run "git clone #{source.uri} #{path}"
                Dir.chdir(path) do
                  run "git checkout #{source.branch}"
                end
                added_gems_names << dependency.name
                ui.info "#{dependency.name} ... clonned"
              end

            when ::Bundler::Source::Path
              path.make_symlink(source.path)
              added_gems_names << dependency.name
              ui.info "#{dependency.name} ... symlinked"
            end
          end

          ui.info ''
          ui.info pastel.bold('Commenting gems')
          ::Bundler.definition.gemfiles.each do |gemfile|
            count = 0
            added_gems_names.each do |name|
              gem_pattern = /(gem "#{name}"|gem '#{name}')/
              count += comment_lines(gemfile, gem_pattern)
            end
            ui.info "* #{gemfile.basename}: #{count} occurrences"
          end
        end

      end
    end
  end
end

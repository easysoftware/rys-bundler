module Rys
  module Bundler
    module Commands
      class Rys
        include ::Rys::Bundler::Helper

        def exec(command, args)
          require 'open3'
          require 'tty-prompt'

          # To avoid deleting options
          if args.first.to_s.start_with?('-')
            action = ''
          else
            action = args.shift.to_s
          end

          case action
          when 'build'
            build_local(args)
          when ''
            build_local(args)
          else
            raise "Unknow action '#{action}'"
          end
        end

        private

          def prompt
            @prompt ||= TTY::Prompt.new
          end

          def pastel
            @pastel ||= Pastel.new
          end

          def run(command)
            output, status = Open3.capture2e(command)

            if !status.success?
              ui.error output
              exit 1
            end
          end

          def build_local(args)
            target = Pathname.new("plugins/easysoftware/local")
            FileUtils.mkdir_p(target)

            added_gems_names = []

            ::Bundler.load.dependencies.each do |dependency|
              next if !dependency.groups.include?(:rys)

              source = dependency.source
              path = target.join(dependency.name)

              case source
              when ::Bundler::Source::Git
                if path.directory?
                  # Already exist
                elsif source.send(:local?)
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

          def ui
            ::Bundler.ui
          end

      end
    end
  end
end

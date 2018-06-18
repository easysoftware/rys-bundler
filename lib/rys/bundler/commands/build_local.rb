module Rys
  module Bundler
    module Commands
      class BuildLocal < Build

        def default_target_dir
          'local'
        end

        def build_gem_from_git(dependency, source, path)
          if source.send(:local?)
            path.make_symlink(source.path)
            print_gem_status(dependency.name, 'symlinked')
          else
            command %{git clone --branch="#{source.branch}" "#{source.uri}" "#{path}"}
            print_gem_status(dependency.name, 'clonned')
          end
        end

        def build_gem_from_path(dependency, source, path)
          path.make_symlink(source.path)
          print_gem_status(dependency.name, 'symlinked')
        end

      end
    end
  end
end

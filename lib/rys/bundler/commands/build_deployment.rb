module Rys
  module Bundler
    module Commands
      class BuildDeployment < Build

        def default_target_dir
          'gems'
        end

        def build_gem_from_git(dependency, source, path)
          if source.send(:local?)
            FileUtils.cp_r(source.path, path)
            print_dependency_status(dependency, 'copied')
          else
            command %{git clone --depth=1 --branch="#{source.branch}" "#{source.uri}" "#{path}"}
            print_dependency_status(dependency, 'clonned')
          end

          FileUtils.rm_rf(path.join('.git'))
        end

        def build_gem_from_path(dependency, source, path)
          FileUtils.cp_r(source.path, path)
          print_dependency_status(dependency, 'copied')
        end

      end
    end
  end
end

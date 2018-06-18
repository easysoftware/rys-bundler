require 'rys/bundler/version'

module Rys
  module Bundler
    autoload :Hooks,   'rys/bundler/hooks'
    autoload :Command, 'rys/bundler/command'

    module Commands
      autoload :Base,               'rys/bundler/commands/base'
      autoload :Add,                'rys/bundler/commands/add'
      autoload :Build,              'rys/bundler/commands/build'
      autoload :BuildLocal,         'rys/bundler/commands/build_local'
      autoload :BuildDeployment,    'rys/bundler/commands/build_deployment'
      autoload :BuildInteractively, 'rys/bundler/commands/build_interactively'
    end
  end
end

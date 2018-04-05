require 'rys/bundler/version'

module Rys
  module Bundler
    autoload :Hooks,   'rys/bundler/hooks'
    autoload :Helper,  'rys/bundler/helper'
    autoload :Command, 'rys/bundler/command'

    module Commands
      autoload :Base,            'rys/bundler/commands/base'
      autoload :Build,           'rys/bundler/commands/build'
      autoload :BuildLocal,      'rys/bundler/commands/build_local'
      autoload :BuildDeployment, 'rys/bundler/commands/build_deployment'
    end
  end
end

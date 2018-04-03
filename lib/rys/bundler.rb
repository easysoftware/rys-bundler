require 'rys/bundler/version'

module Rys
  module Bundler
    autoload :Hooks,  'rys/bundler/hooks'
    autoload :Helper, 'rys/bundler/helper'

    module Commands
      autoload :Base,  'rys/bundler/commands/base'
      autoload :Rys,   'rys/bundler/commands/rys'
      autoload :Build, 'rys/bundler/commands/build'
    end
  end
end

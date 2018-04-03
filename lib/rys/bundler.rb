require 'rys/bundler/version'

module Rys
  module Bundler
    autoload :Hooks, 'rys/bundler/hooks'
    autoload :Helper, 'rys/bundler/helper'

    module Commands
      autoload :Rys, 'rys/bundler/commands/rys'
    end
  end
end

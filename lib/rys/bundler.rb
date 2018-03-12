require 'rys/bundler/version'

module Rys
  module Bundler
    autoload :Hooks, 'rys/bundler/hooks'

    module Commands
      autoload :Rys, 'rys/bundler/commands/rys'
    end
  end
end

require 'rys_bundler/version'

module RysBundler
  autoload :Hooks, 'rys_bundler/hooks'

  module Commands
    autoload :Rys, 'rys_bundler/commands/rys'
  end
end

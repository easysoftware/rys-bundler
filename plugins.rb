$:.push File.expand_path('lib', __dir__)
require 'rys_bundler'

# Commands
Bundler::Plugin.add_command('rys', RysBundler::Commands::Rys)

# Hooks
Bundler::Plugin.add_hook('before-install-all') do |dependencies|
  RysBundler::Hooks.before_install_all(dependencies)
end

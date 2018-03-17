$:.push File.expand_path('lib', __dir__)
require 'rys/bundler'

# Commands
Bundler::Plugin.add_command('rys', Rys::Bundler::Commands::Rys)

# Hooks
Bundler::Plugin.add_hook('before-install-all') do |dependencies|
  Rys::Bundler::Hooks.before_install_all(dependencies)
end

Bundler::Plugin.add_hook('rys-gemfile') do |dsl|
  Rys::Bundler::Hooks.rys_gemfile(dsl)
end

Bundler::Plugin.add_hook('rys-load-dummy') do |dsl|
  Rys::Bundler::Hooks.rys_load_dummy(dsl)
end

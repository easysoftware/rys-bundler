$:.push File.expand_path('lib', __dir__)
require 'rys/bundler'

# Commands
Bundler::Plugin.add_command('rys', Rys::Bundler::Command)

# Hooks
Bundler::Plugin.add_hook('before-install-all') do |dependencies|
  Rys::Bundler::Hooks.before_install_all(dependencies)
end

# Because of bundler >= 1.17
if defined?(Bundler::Plugin::Events)
  Bundler::Plugin::Events.send(:define, :RYS_GEMFILE, 'rys-gemfile')
  Bundler::Plugin::Events.send(:define, :RYS_LOAD_DUMMY, 'rys-load-dummy')
end

Bundler::Plugin.add_hook('rys-gemfile') do |dsl|
  Rys::Bundler::Hooks.rys_gemfile(dsl)
end

Bundler::Plugin.add_hook('rys-load-dummy') do |dsl|
  Rys::Bundler::Hooks.rys_load_dummy(dsl)
end

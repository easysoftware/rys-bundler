# Comming soon
# Bundler::Plugin.add_command('rys', RysBundler::Commands::Rys)

Bundler::Plugin.add_hook('before-install-all') do |dependencies|
  RysBundler::Hooks.before_install_all(dependencies)
end

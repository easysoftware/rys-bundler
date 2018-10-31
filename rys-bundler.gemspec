# encoding: utf-8

$:.push File.expand_path('lib', __dir__)

require 'rys/bundler/version'

Gem::Specification.new do |spec|
  spec.name    = 'rys-bundler'
  spec.version = Rys::Bundler::VERSION
  spec.authors = ['Ondřej Moravčík']
  spec.summary = 'Recursively resolving rys dependencies'

  lib_files = Dir.chdir(__dir__){ Dir.glob('lib/**/*') }
  spec.files = lib_files + ['README.md', 'plugins.rb']

  spec.add_dependency 'tty-prompt'
end

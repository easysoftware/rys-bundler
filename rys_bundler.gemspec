$:.push File.expand_path('lib', __dir__)

require 'rys_bundler/version'

Gem::Specification.new do |spec|
  spec.name    = 'rys_bundler'
  spec.version = RysBundler::VERSION
  spec.authors = ['Ondřej Moravčík']
  spec.summary = 'Recursively resolving rys dependencies'

  lib_files = Dir.chdir(__dir__){ Dir.glob('lib/**/*') }
  spec.files = lib_files + ['README.md']
end

# Rys::Bundler

The best way how to install dependecies from Rys plugins.

## Install

Add this line to your application's Gemfile or gems.rb:

```ruby
plugin 'rys-bundler'

Plugin.hook('rys-gemfile', self)
```

And then execute:

```
$ bundle
``` 
    
Bundle command will create `gems.dependencies.rb` at your application root.

## Usage

Application's **Gemfile** or **gems.rb** file.

All gems which should be resolved for dependencies must be in group `rys`.

```ruby
plugin 'rys-bundler'
Plugin.hook('rys-gemfile', self)

group :default, :rys do
  gem 'rys_plugin', ...
end

```

Gem's dependencies are defined in **dependecies.rb** file. If dependecny should be further resolved put it into group `rys` as well.

```ruby
group :rys do
  group :default do
    gem 'rys'
    gem 'easy_core'
  end

  group :development do
    gem 'tty'
  end

  group :test do
    gem 'rspec'
  end
end

```


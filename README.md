# Rys::Bundler

The way how to install dependecies from Rys plugins.

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
    
Bundle command will create `dependencies.rb` at your application root

## Usage

**Application** gems file

```ruby
group :default, :rys do
  gem 'first_gem', ...
end

```

**first_gem** gems file

```ruby
group :default, :rys do
  gem 'second_gem', ...
end
```


require 'open3'
require 'ostruct'
require 'optparse'
require 'tty-prompt'

module Rys
  module Bundler
    module Commands
      class Base

        def self.run(args)
          raise NotImplementedError
        end

        def prompt
          @prompt ||= TTY::Prompt.new
        end

        def pastel
          @pastel ||= Pastel.new
        end

        def ui
          ::Bundler.ui
        end

        def run
          raise NotImplementedError
        end

        def command(command)
          output, status = Open3.capture2e(command)

          if !status.success?
            ui.error output
            exit 1
          end
        end

        def get_redmine_plugin!
          plugins_dir = Pathname.pwd.join('plugins')
          plugins = Pathname.glob(plugins_dir.join('*/rys.rb'))

          case plugins.size
          when 0
            raise 'There is no redmine plugin for rys gems. Please run "rails generate rys:redmine:plugin NAME"'
          when 1
            return plugins.first.dirname
          else
            raise 'There are more than one redmine plugin for rys plugins.'
          end
        end

      end
    end
  end
end

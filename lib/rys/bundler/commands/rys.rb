module Rys
  module Bundler
    module Commands
      class Rys

        def exec(command, args)
          # To avoid deleting options
          if args.first.to_s.start_with?('-')
            action = ''
          else
            action = args.shift.to_s
          end

          case action
          when 'build'
            Build.new(args).run
          # when 'add'
          #   Add.new(args).run
          when ''
            Build.new(args).run
          else
            raise "Unknow action '#{action}'"
          end
        end

      end
    end
  end
end

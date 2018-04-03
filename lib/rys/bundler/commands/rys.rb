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
            build_local(args)
          # when 'add'
          #   Add.new(args).run
          when ''
            build_local(args)
          else
            raise "Unknow action '#{action}'"
          end
        end

        private

          def build_local(args)
            Build.new(args).build_local
          end

      end
    end
  end
end

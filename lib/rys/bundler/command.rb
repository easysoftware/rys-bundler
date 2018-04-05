module Rys
  module Bundler
    class Command

      # For now only "rys" command is available
      def exec(command, args)
        # To avoid deleting options
        if args.first.to_s.start_with?('-')
          action = ''
        else
          action = args.shift.to_s
        end

        case action
        when 'add'
          Commands::Add.run(args)
        when 'build'
          Commands::Build.run(args)
        when ''
          Commands::Build.run(args)
        else
          raise "Unknow action '#{action}'"
        end
      end

    end
  end
end

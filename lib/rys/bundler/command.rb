module Rys
  module Bundler
    class Command

      # For now only "rys" command is available
      def exec(command, args)
        if args.include?('-h') || args.include?('--help')
          print_help_and_exit
        end

        # To avoid deleting options
        if args.first.to_s.start_with?('-')
          action = ''
        else
          action = args.shift.to_s
        end

        case action
        when 'add'
          Commands::Add.run(args)
        when 'build', ''
          Commands::Build.run(args)
        when 'ibuild'
          Commands::BuildInteractively.run(args)
        when 'help'
          print_help_and_exit
        else
          raise "Unknow action '#{action}'"
        end
      end

      private

        def print_help_and_exit
          puts %{USAGE: bundle rys ACTION [options]}
          puts %{}
          puts %{COMMANDS:}
          puts %{   add      Add a rys gem}
          puts %{   build    Build rys gems (download for development or deployment)}
          puts %{   ibuild   Build rys gems interactively}
          puts %{}
          puts %{OPTIONS:}
          puts %{   -h, --help}
          puts %{       Print this help}
          puts %{}
          exit
        end

    end
  end
end

module VPS
  # The CLI is the entry point into the application. It loads the configuration,
  # parses command line arguments runs the show.
  class Cli
    def initialize(config_file = Configuration::DEFAULT_FILE, state_file = State::DEFAULT_FILE)
      @configuration = Configuration.load(config_file)
      @state = State.load(state_file, @configuration)
      @output_formatter = OutputFormatter::Console
      @parser = option_parser
    end

    # Builds an option parser for the program arguments.
    # @return [OptionParser]
    def option_parser
      OptionParser.new do |parser|
        parser.banner = 'Usage: vps [options] <type> <command> [arguments]'
        parser.program_name = 'vps'
        parser.version = VPS::VERSION
        parser.on('-a', '--[no-]alfred', 'Generate output in Alfred format') do |alfred|
          @output_formatter = if alfred
                                OutputFormatter::Alfred
                              else
                                OutputFormatter::Console
                              end
        end
        parser.on('-f', '--focus [AREA]', 'Force the focus to the specified area temporarily') do |area|
          @state.change_focus(area, @configuration)
        end
        parser.on('-v', '--version', 'Show the version number and exit') do
          puts VPS::VERSION
          exit
        end
        parser.separator ''
        parser.separator 'To get information on all available plugins: vps help'
      end
    end

    # Runs the application based on the arguments provided.
    #
    # @param arguments [Array<String>] the program arguments.
    # @param environment [Hash<String, String>] the environment variables.
    # @return void
    def run(arguments = ARGV, environment = ENV)
      @parser.order!(arguments)
      if arguments.empty?
        puts @parser.help
        return
      end
      if arguments.first == 'help'
        run_help(arguments.drop(1))
      else
        run_command(arguments, environment)
      end
    end

    # Shows help information; either overall help or plugin-specific help.
    #
    # @param arguments [Array<String>] the program arguments.
    # @return void
    def run_help(arguments)
      if arguments.size < 2
        show_overall_help
      else
        runner = CommandRunner.new(@configuration, @state, arguments, {})
        show_command_help(runner)
      end
    end

    # Runs a command, provided that one can be derived from the program arguments.
    #
    # @param arguments [Array<String>] the program arguments.
    # @param environment [Hash<String, String>] the environment variables.
    # @return void
    def run_command(arguments, environment)
      if arguments.size < 2
        show_overall_help
      else
        runner = CommandRunner.new(@configuration, @state, arguments, environment)
        output = runner.execute
        print @output_formatter.format(output)
      end
    end

    # Shows overall help information, including information on each individual plugin.
    # @return void
    def show_overall_help
      @parser.separator ''
      @parser.separator 'Where <type> and <command> are one of: '
      @parser.separator ''
      @configuration.available_commands(@state.focus).each_pair do |entity_type, commands|
        @parser.separator "  #{entity_type.entity_type_name}"
        commands.each do |command|
          help = command.option_parser.banner || '(Sorry, no information provided)'
          @parser.separator "    #{command.name.ljust(10)}: #{help}"
        end
      end
      @parser.separator ''
      @parser.separator '  help <type> <command>: show help on a specific command'
      @parser.separator ''
      @parser.separator 'Note that the types and commands available depend on the focused area.'
      puts @parser.help
    end

    # Shows help information on a single command.
    # @param runner [CommandRunner]
    # @return void
    def show_command_help(runner)
      if runner.help_available?
        puts runner.help
        return
      end
      warn 'No help information is available for this command'
      warn
      warn 'Dear developer,'
      warn
      warn "Please implement the method 'option_parser' in class #{runner.command.class.name}"
      warn
      warn 'The user of your software thanks you!'
    end
  end
end

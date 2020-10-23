module VPS
  ## The CLI is the entry point into the application. It loads the configuration,
  # parses command line arguments and acts upon those.
  class Cli
    def initialize(config_file = Configuration::DEFAULT_FILE, state_file = State::DEFAULT_FILE)
      @configuration = configuration = Configuration::load(config_file)
      @state = State::load(state_file, configuration)
      @output_formatter = OutputFormatter::Console
      @parser = option_parser
    end

    ##
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

    ##
    # Runs the application based on the arguments provided.
    #
    # @param arguments [Array] the program arguments.
    # @param environment [Hash] the environment variables.
    def run(arguments = ARGV, environment = ENV)
      @parser.order!(arguments)
      if arguments.size < 1
        puts @parser.help
        return
      end
      if arguments[0] == 'help'
        run_help(arguments.drop(1))
      else
        run_command(arguments, environment)
      end
    end

    ##
    # Shows help information; either overall help or plugin-specific help.
    #
    # @param arguments [Array] the program arguments.
    def run_help(arguments)
      if arguments.size < 2
        show_overall_help
      else
        command = resolve_command(arguments)
        show_command_help(command)
      end
    end

    ##
    # Runs a command, provided that one can be derived from the program arguments.
    #
    # @param arguments [Array] the program arguments.
    # @param environment [Hash] the environment variables.
    def run_command(arguments, environment)
      if arguments.size < 2
        show_overall_help
      else
        command = resolve_command(arguments)
        execute_command(command, arguments, environment)
      end
    end

    ##
    # Shows overall help information, including information on each individual plugin.
    def show_overall_help
      @parser.separator ''
      @parser.separator 'Where <type> and <command> are one of: '
      @parser.separator ''
      @configuration.supported_entity_types(@state.focus).each do |entity_type|
        @parser.separator "  #{entity_type.entity_type_name}"
        @configuration.supported_commands(@state.focus, entity_type).each do |command|
          help = command.option_parser.banner || '(Sorry, no information provided)'
          @parser.separator "    #{command.name.ljust(10)}: #{help}"
        end
      end
      @parser.separator ''
      @parser.separator '  help <plugin> <command>: show help on a specific command'
      @parser.separator ''
      @parser.separator 'Note that the plugins and commands available depend on the focused area.'
      puts @parser.help
    end

    ##
    # Shows help information on a single command.
    #
    # @param command [VPS::Plugin::Command] the command to show information on.
    def show_command_help(command)
      option_parser = command.option_parser
      if !option_parser.nil?
        puts option_parser.help
      else
        $stderr.puts 'No help information is available for this command'
        $stderr.puts
        $stderr.puts 'Dear developer,'
        $stderr.puts
        $stderr.puts "Please implement the method 'option_parser' in class #{clazz}"
        $stderr.puts
        $stderr.puts 'The user of your software thanks you!'
      end
    end

    def resolve_command(arguments)
      type_name = arguments.shift
      command_name = arguments.shift
      command = @configuration.resolve_command(@state.focus, type_name, command_name)
      if command.nil?
        raise "Invalid command '#{command_name}' for '#{type_name}'"
      end
      command
    end

    ##
    # Executes a command.
    #
    # @param command [VPS::Plugin::BaseCommand] the command to execute.
    # @param arguments [Array] the program arguments.
    # @param environment [Hash] the environment variables.
    def execute_command(command, arguments, environment)
      configuration = @configuration.command_config(@state.focus, command)
      repository = @configuration.repository_for_entity_type(@state.focus, command.supported_entity_type)
      context = Context.new(configuration, repository, arguments, environment)
      if command.can_run?(context)
        output = @output_formatter.format { command.run(context) }
        puts output unless output.nil?
      else
        puts 'Command execution failed. Sorry!'
        exit(-1)
      end
    end
  end
end
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
        parser.banner = 'Usage: vps [options] <plugin> <command> [arguments]'
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
        plugin = entity_manager(arguments.shift)
        command = command(plugin, arguments.shift)
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
        plugin_name = arguments.shift
        plugin = entity_manager(plugin_name)
        command = command(plugin, arguments.shift)
        execute_command(command, arguments, environment)
      end
    end

    ##
    # Shows overall help information, including information on each individual plugin.
    def show_overall_help
      @parser.separator ''
      @parser.separator 'Where <plugin> and <command> are one of: '
      @parser.separator ''
      @configuration.entity_managers(@state.focus).each do |plugin|
        @parser.separator "  #{plugin.entity_class_name}"
        plugin.commands.each_pair do |name, command|
          # TODO: filter out all commands that are collaborators for entities that are
          # not available This is not so simple, as this information is not really
          # easily accessible. This requires some more refactoring first...
          banner = if command.command_class.respond_to? 'option_parser'
                     command.command_class.option_parser.banner
                   else
                     '(Sorry, no information provided)'
                   end
          @parser.separator "    #{name.to_s.ljust(10)}: #{banner}"
        end
      end
      @parser.separator ''
      @parser.separator '  help <plugin> <command>: show help on a specific command'
      @parser.separator ''
      @parser.separator 'Note that the plugins and commands available depend on the focused area.'
      # Now print the full help information.
      puts @parser.help
    end

    ##
    # Shows help information on a single command.
    #
    # @param command [VPS::Plugin::Command] the command to show information on.
    def show_command_help(command)
      clazz = command.command_class
      if clazz.respond_to? 'option_parser'
        puts clazz.option_parser.help
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

    ##
    # Executes a command.
    #
    # @param command [VPS::Plugin::Command] the command to execute.
    # @param arguments [Array] the program arguments.
    # @param environment [Hash] the environment variables.
    def execute_command(command, arguments, environment)
      context = Context.new(@configuration, @state, arguments, environment)
      instance = command.command_class.new(context)
      can_run = if instance.respond_to?('can_run?')
                  instance.can_run?
                else
                  true
                end
      if can_run
        output = @output_formatter.format { instance.run }
        puts output unless output.nil?
      else
        puts 'Command execution failed. Sorry!'
        exit(-1)
      end
    end

    ##
    # Locates the plugin that manages entities with name +entity_name+
    #
    # @param entity_name [String] short name of the entity class, e.g. +project+.
    # @return [VPS::Plugin]
    def entity_manager(entity_name)
      plugin = @configuration.entity_manager_for(@state.focus, entity_name)
      if plugin.nil?
        puts "Entity '#{entity_name}' is not supported in this area."
        exit(-1)
      end
      plugin
    end

    ##
    # Retrieves a command from a plugin.
    #
    # @param plugin [Plugin] the plugin to get the command from.
    # @param command_name [String] short name of the command class, e.g. +list+.
    # @return [VPS::Command]
    def command(plugin, command_name)
      command = plugin.commands[command_name]
      if command.nil?
        puts "Unsupported command: #{command_name}"
        exit(-1)
      end
      command
    end
  end
end
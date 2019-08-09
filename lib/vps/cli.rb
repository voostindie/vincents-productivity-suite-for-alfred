module VPS
  class Cli

    DEFAULT_CONFIG_FILE = File.join(Dir.home, '.vpsrc').freeze
    DEFAULT_STATE_FILE = (DEFAULT_CONFIG_FILE + '.state').freeze

    def initialize(config_file = DEFAULT_CONFIG_FILE, state_file = DEFAULT_STATE_FILE)
      @configuration = configuration = Configuration::load(config_file)
      @state = State::load(state_file, configuration)
      @output = Output::Console
      @parser = option_parser
    end

    def option_parser
      OptionParser.new do |parser|
        parser.banner = 'Usage: vps [options] <plugin> <command> [arguments]'
        parser.program_name = 'vps'
        parser.version = VPS::VERSION
        parser.on('-a', '--[no-]alfred', 'Generate output in Alfred format') do |alfred|
          @output = if alfred
                      Output::Alfred
                    else
                      Output::Console
                    end
        end
        parser.on('-f', '--focus [AREA]', 'Force the focus to the specified area temporarily') do |area|
          @state.change_focus(area, configuration)
        end
        parser.on('-v', '--version', 'Show the version number and exit') do
          puts VPS::VERSION
          exit
        end
        parser.separator ''
        parser.separator 'Where <plugin> and <command> are one of: '
        parser.separator ''
        Registry.commands.each_pair do |plugin, definition|
          parser.separator "  #{plugin.to_s}"
          definition[:commands].each_pair do |command, definition|
            banner = if definition[:class].respond_to? 'option_parser'
                       definition[:class].option_parser.banner
                     else
                       '(Sorry, no information provided)'
                     end
            parser.separator "    #{command.to_s.ljust(10)}: #{banner}"
          end
        end
        parser.separator ''
        parser.separator '  help <plugin> <command>: show help on a specific command'
        parser.separator ''
        parser.separator 'Note that the commands available depend on the configuration and the focused area.'
      end
    end

    def run(arguments = ARGV)
      @parser.order!(arguments)
      if arguments.size < 2
        puts @parser.help
        return
      end
      plugin = arguments.shift
      if plugin == 'help'
        if arguments.size < 2
          puts @parser.help
          return
        end
        plugin_def = plugin_definition(arguments.shift)
        command_def = command_definition(plugin_def, arguments.shift)
        show_command_help(command_def)
      else
        plugin_def = plugin_definition(plugin)
        command_def = command_definition(plugin_def, arguments.shift)
        run_command(command_def, arguments)
      end
    end

    def show_command_help(command_def)
      clazz = command_def[:class]
      if clazz.respond_to? 'option_parser'
        puts clazz.option_parser.help
      else
        puts 'No help information is available for this command'
        puts
        puts 'Dear developer,'
        puts
        puts "Please implement the method 'option_parser' in class #{clazz}"
        puts
        puts 'The user of your software thanks you!'
      end
    end

    def run_command(command_definition, arguments)
      command = command_definition[:class].new(@configuration, @state)
      can_run = if command.respond_to?('can_run?')
                  command.can_run?
                else
                  true
                end
      if can_run
        @output.format do
          command.run(arguments)
        end
      else
        puts "The command is not available in this context."
      end
    end

    def plugin_definition(plugin_name)
      plugin_def = Registry.commands[plugin_name.to_sym]
      if plugin_def.nil?
        puts "Unsupported plugin: #{plugin_name}"
        puts
        puts @parser.help
        exit(-1)
      end
      plugin_def
    end

    def command_definition(plugin_definition, command_name)
      command_def = plugin_definition[:commands][command_name.to_sym]
      if command_def.nil?
        puts "Unsupported subcommand: #{command_name}"
        puts
        puts @parser.help
        exit(-1)
      end
      command_def
    end
  end
end
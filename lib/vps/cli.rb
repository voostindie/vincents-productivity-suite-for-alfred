module VPS
  class Cli

    def initialize(config_file = Configuration::DEFAULT_FILE, state_file = State::DEFAULT_FILE)
      @configuration = configuration = Configuration::load(config_file)
      @state = State::load(state_file, configuration)
      @output_formatter = OutputFormatter::Console
      @parser = option_parser
    end

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
        parser.separator 'Where <type> and <command> are one of: '
        parser.separator ''
        @configuration.available_managers(@state.focus).each_pair  do |_, definition|
          parser.separator "  #{definition[:manages].to_s}"
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
        parser.separator '  help <type> <command>: show help on a specific command'
        parser.separator ''
        parser.separator 'Note that the commands available depend on the configuration and the focused area.'
      end
    end

    def run(arguments = ARGV, environment = ENV)
      @parser.order!(arguments)
      if arguments.size < 2
        puts @parser.help
        return
      end
      type = arguments.shift
      if type == 'help'
        if arguments.size < 2
          puts @parser.help
          return
        end
        type_def = type_definition(arguments.shift)
        command_def = command_definition(type_def, arguments.shift)
        show_command_help(command_def)
      else
        type_def = type_definition(type)
        command_def = command_definition(type_def, arguments.shift)
        run_command(command_def, arguments, environment)
      end
    end

    def show_command_help(command_def)
      clazz = command_def[:class]
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

    def run_command(command_definition, arguments, environment)
      command = command_definition[:class].new(@configuration, @state)
      can_run = if command.respond_to?('can_run?')
                  command.can_run?(arguments, environment)
                else
                  true
                end
      if can_run
        output = @output_formatter.format { command.run(arguments, environment) }
        puts output unless output.nil?
      else
        puts 'Command execution failed. Sorry!'
        exit(-1)
      end
    end

    def type_definition(type)
      type_def = @configuration.manager(@state.focus, type.to_sym)
      if type_def.nil?
        puts "Type '#{type}' is not supported in this area."
        $stderr.puts @parser.help
        exit(-1)
      end
      type_def
    end

    def command_definition(type_definition, command_name)
      command_def = type_definition[:commands][command_name.to_sym]
      if command_def.nil?
        puts "Unsupported command: #{command_name}"
        $stderr.puts @parser.help
        exit(-1)
      end
      command_def
    end
  end
end
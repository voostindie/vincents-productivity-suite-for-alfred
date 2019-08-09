module VPS
  module PluginSupport

    ##
    # Creates a new command. This happens whenever the command is executed through the CLI.
    #
    # Every command MUST implement this initializer.
    #
    # @param configuration [Configuration] the application configuration
    # @param state [State] the application state
    def initialize(configuration, state)
      @configuration = configuration
      @state = state
    end

    def is_plugin_enabled?(key)
      if @state.focus[key].nil?
        $stderr.puts "Plugin #{key} is not enabled in area #{@state.focus[:name]}"
        false
      else
        true
      end
    end

    def has_arguments?(arguments, count_required = 1)
      if arguments.size != count_required
        $stderr.puts "Invalid number of arguments"
        $stderr.puts
        $stderr.puts "Here are the help notes for this command:"
        $stderr.puts
        $stderr.puts self.class.option_parser.help
        false
      else
        true
      end
    end

    def is_manager_available?(type)
      manager = @configuration.manager(@state.focus, type)
      if manager.nil?
        $stderr.puts "No manager found that supports #{type}"
        false
      else
        true
      end
    end

    def manager_module(type)
      @configuration.manager(@state.focus, :type)[:module]
    end
  end
end
module VPS
  module PluginSupport

    ##
    # Creates a new command. This happens whenever the command is executed through the CLI.
    #
    # Every command MUST implement this initializer.
    #
    # @param context [Context] the application context
    def initialize(context)
      @context = context
    end

    def is_entity_present?(entity_class)
      entity_name = entity_class.name.split('::').last
      variable = entity_name.upcase + '_ID'
      if @context.environment[variable].nil?
        if @context.arguments.size != 1
          $stderr.puts "Missing ID to the #{entity_name}. This must be passed as the one and only argument"
          $stderr.puts
          $stderr.puts "Here are the help notes for this command:"
          $stderr.puts
          $stderr.puts self.class.option_parser.help
          return false
        end
      end
      true
    end

    def is_entity_manager_available?(entity_class)
      plugin = @context.configuration.entity_manager_for_class(@context.focus, entity_class)
      if plugin.nil?
        $stderr.puts "No manager found that supports #{entity_class}"
        false
      else
        true
      end
    end

    def entity_manager_for(entity_class)
      @context.configuration.entity_manager_for_class(@context.focus, entity_class)
    end

    def triggered_as_snippet?
      if @context.environment['TRIGGERED_AS_SNIPPET'].nil?
        false
      else
        @context.environment['TRIGGERED_AS_SNIPPET'] == 'true'
      end
    end

    def strip_emojis(string)
      # Not doing anything yet...
      string
    end
  end
end
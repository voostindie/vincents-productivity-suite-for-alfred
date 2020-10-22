module VPS

  ##
  # To create a plugin for VPS, do the following:
  #
  # 1. Create a file in lib/vps/plugins
  # 2. Define a new module within the module VPS::Plugins
  # 3. Include this module
  #
  # For example in {my_plugin.rb}:
  #
  #   module VPS
  #     module Plugins
  #       module MyPlugin
  #         include Plugin
  #
  #       end
  #     end
  #   end
  #
  # This gives you an empty plugin. For any functionality that you wish to provide, extend the
  # appropriate classes in this module:
  #
  # - BaseConfigurator: to configure the plugin from the configuration file.
  # - BaseRepository: for a repository for a specific Type
  # - TypeCommand: for a command that acts on a specific Type
  # - InstanceCommand: for a command that acts on instances of a specific Type
  # - CollaborationCommand: for a command that acts on instances of a specific Type against a different Type
  # - BaseAction: for an action
  #
  # You can all but two classes as often as you want: the BaseConfigurator and BaseAction should
  # only be extended at most once.
  #
  module Plugin

    class BaseConfigurator

      ##
      # @return the name of the plugin; defaults to the name of the plugin module, in lower case.
      def plugin_name
        nil
      end

      def process_area_configuration(area, hash)
        {}
      end

      def process_action_configuration(hash)
        {}
      end

      def force_string(hash_value)
        hash_value if hash_value.is_a?(String)
      end

      def force_string_array(hash_value)
        hash_value if hash_value.is_a?(Array) && hash_value.all? { |e| e.is_a?(String) }
      end
    end

    class BaseRepository
      def type?
        nil
      end

      # TODO: the repository commands need access to the configuration of the plugin they're part of
      # So, I somehow have to pass this as an argument, in such a way that callers don't know it. Hmmm....
      def list
        []
      end
    end

    class BaseCommand
      def name
        self.class.name.split('::').last.downcase
      end

      def acts_on_type?
        nil
      end

      def option_parser
        nil
      end

      def can_run?(context)
        true
      end

      def run(context)
        nil
      end
    end

    class TypeCommand < BaseCommand

    end

    class InstanceCommand < BaseCommand

    end

    class CollaborationCommand < BaseCommand

    end

    class BaseAction

    end
    ##
    # Creates a new command. This happens whenever the command is executed through the CLI.
    #
    # Every command MUST implement this initializer.
    #
    # @param context [Context] the application context
    #   def initialize(context)
    #     @context = context
    #   end
    #
    #   def is_entity_present?(entity_class)
    #     entity_name = entity_class.name.split('::').last
    #     variable = entity_name.upcase + '_ID'
    #     if @context.environment[variable].nil?
    #       if @context.arguments.size != 1
    #         $stderr.puts "Missing ID to the #{entity_name}. This must be passed as the one and only argument"
    #         $stderr.puts
    #         $stderr.puts "Here are the help notes for this command:"
    #         $stderr.puts
    #         $stderr.puts self.class.option_parser.help
    #         return false
    #       end
    #     end
    #     true
    #   end
    #
    #   def is_entity_manager_available?(entity_class)
    #     plugin = @context.configuration.entity_manager_for_class(@context.focus, entity_class)
    #     if plugin.nil?
    #       $stderr.puts "No manager found that supports #{entity_class}"
    #       false
    #     else
    #       true
    #     end
    #   end
    #
    #   def entity_manager_for(entity_class)
    #     @context.configuration.entity_manager_for_class(@context.focus, entity_class)
    #   end
    #
    #   def triggered_as_snippet?
    #     if @context.environment['TRIGGERED_AS_SNIPPET'].nil?
    #       false
    #     else
    #       @context.environment['TRIGGERED_AS_SNIPPET'] == 'true'
    #     end
    #   end
    #
    #   def strip_emojis(string)
    #     # Not doing anything yet...
    #     string
    #   end
  end
end
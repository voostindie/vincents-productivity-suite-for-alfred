module VPS

  ##
  # To create a plugin for VPS, do the following:
  #
  # 1. Create a file in lib/vps/plugins
  # 2. Define a new module within the module VPS::Plugins
  # 3. Include this module
  #
  # For example in +my_plugin.rb+:
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
  # You can implement all but two classes as often as you want: the BaseConfigurator and BaseAction may
  # only be extended at most once. If you do it more than once, VPS will pick the first of each.
  #
  module Plugin

    class BaseConfigurator

      ##
      # @return the name of the plugin; defaults to the name of the plugin module in lower case if this
      #         method returns nil.
      def plugin_name
        nil
      end

      ##
      # Constructs the configuration for this plugin from the configuration hash.
      # What you create here you get back as part of the Context in the various commands.
      #
      # Be strict in what you accept, and feel free to use $stderr to notify the user of issues.
      #
      # @return The configuration for this plugin in this area; typically a hash.
      # @param area The area in the configuration being processed, a hash with :key, :name and :root
      # @param hash The configuration for this plugin as defined in the configuration.
      def process_area_configuration(area, hash)
        {}
      end

      ##
      # Constructs the action configuration for this plugin from the configuration hash.
      # What you create here you get back as part of the Context in the action class.
      #
      # Be strict in what you accept, and feel free to use $stderr to notify the user of issues.
      #
      # @return The configuration for this plugin when executing the action; typically a hash.
      # @param hash The configuration for this plugin as defined in the configuration.
      def process_action_configuration(hash)
        {}
      end

      ##
      # Support method: make sure the value is a String, otherwise return nil.
      # @param hash_value [Object] value to enforce to a String
      def force_string(hash_value)
        hash_value if hash_value.is_a?(String)
      end

      ##
      # Support method: make sure the value is a an array of Strings, otherwise return nil.
      # @param hash_value Value to enforce to an Array of Strings
      def force_string_array(hash_value)
        hash_value if hash_value.is_a?(Array) && hash_value.all? { |e| e.is_a?(String) }
      end
    end

    class BaseRepository
      def supported_entity_type
        raise "#{self.class.name}.supported_entity_type is not yet implemented!"
      end

      ##
      # Lists all entities in this repository
      #
      # @param context [VPS::Context]
      def find_all(context)
        raise "#{self.class.name}.find_all is not yet implemented!"
      end

      ##
      # @param context [VPS::Context]
      def load(context)
        raise "#{self.class.name}.load is not yet implemented!"
      end

      ##
      # @param context [VPS::Context]
      # @param instance [VPS::EntityTypes::BaseType]
      def create_or_find(context, instance)
        raise "#{self.class.name}.create_or_find is not yet implemented!"
      end
    end

    class BaseCommand
      def name
        self.class.name.split('::').last.downcase
      end

      def supported_entity_type
        raise "#{self.class.name}.supported_entity_type is not yet implemented!"
      end

      ##
      # @return [OptionParser]
      def option_parser
        raise "#{self.class.name}.option_parser is not yet implemented!"
      end

      ##
      # @param context [VPS::Context]
      def run(context)
        nil
      end
    end

    class EntityTypeCommand < BaseCommand

    end

    class EntityInstanceCommand < BaseCommand

    end

    class CollaborationCommand < BaseCommand

    end

    class BaseAction

    end
  end
end
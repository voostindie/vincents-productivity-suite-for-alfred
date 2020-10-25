module VPS
  # == Start here if you want to create your own plugin!
  #
  # To create a plugin for VPS, do the following:
  #
  # 1. Create a file in +lib/vps/plugins+
  # 2. Define a new module within the module {VPS::Plugins}
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
  # This gives you an empty plugin. For any functionality that you wish to provide, subclass the
  # appropriate classes in this module.
  #
  # There are 4 types of things you can provide:
  #
  # 1. A configurator
  # 2. Repositories
  # 3. Commands
  # 4. An Action
  #
  # You have to use subclasses, sorry. Only then will the configurators, repositories, commands
  # and actions be automatically discovered.
  #
  # You can implement all but two classes as often as you want: the {Configurator} and {Action} may
  # be extended at most once. If you do it more than once, VPS will pick the first of each.
  #
  # == Configurator
  #
  # Extend {Configurator} to be able to process plugin configuration in the user's configuration
  # file. This is entirely optional. If you have nothing to configure, don't bother.
  #
  # A plugin should have no more than 1 configuration. If there are more, only the first will be
  # used.
  #
  # == Repository
  #
  # A repository manages exactly one {VPS::EntityType} in the system. Each type can have at
  # most one repository in a single area. If a user's configuration has multiple plugins that
  # offer repositories for the same entity type, then only the first plugin is used.
  #
  # In other words: don't stick too many repositories in a single plugin if you plan to scale it up.
  #
  # Class {Repository} is the class to subclass.
  #
  # == Command
  #
  # A command is a piece of code that is made available through the CLI. A command is always bound to
  # an entity type. Within an area, only those commands show up that work on an entity type that
  # also has a repository available. If not, the command will simply not be available, even though
  # its plugin might be.
  #
  # There are four different types of command; these are all subclasses of the {VPS::Plugin::Command}
  # class. Subclasses any of these four; don't subclass {Command} yourself! The four are:
  #
  # 1. {EntityTypeCommand}
  # 2. {EntityInstanceCommand}
  # 3. {CollaborationCommand}
  # 4. {SystemCommand}
  #
  # == Action
  #
  # A plugin can have at most one action class. This is because the action is referenced by the
  # plugin name in the configuration file. Multiple actions would clash.
  #
  # Actions get triggered when the focus changes. See {VPS::Plugins::Area::Focus}
  #
  # Class {Action} is your friend!
  #
  module Plugin

    # Configures a plugin from the user's configuration.
    class Configurator
      ##
      # @return the name of the plugin; defaults to the name of the plugin module in lower case if this
      #         method returns nil.
      def plugin_name
        nil
      end

      ##
      # Constructs the configuration for this plugin from the configuration hash.
      # What you create here you get back as part of the context in the various commands.
      #
      # Be strict in what you accept, and feel free to use +$stderr+ to notify the user of issues.
      #
      # @param area [Hash] The area in the configuration being processed,
      #             a hash with +:key+, +:name+ and +:root+
      # @param hash [Hash] The configuration for this plugin as defined in the configuration.
      # @return [Hash] the configuration for this plugin in this area; typically a hash.
      def process_area_configuration(area, hash)
        {}
      end

      ##
      # Constructs the action configuration for this plugin from the configuration hash.
      # What you create here you get back as part of the context in the action class.
      #
      # Be strict in what you accept, and feel free to use +$stderr+ to notify the user of issues.
      #
      # @return [Hash] the configuration for this plugin when executing the action; typically a hash.
      # @param hash [Hash] The configuration for this plugin as defined in the configuration.
      def process_action_configuration(hash)
        {}
      end

      # Helper methpd: accept +value+ only if it is a +clazz+, +nil+ otherwise.
      # @param value [Object]
      # @param clazz [Class]
      # @return [Object, nil]
      def force(value, clazz)
        value if value.is_a?(clazz)
      end

      # Helper method: make sure +value+ is a an array of +clazz+, +nil+ otherwise.
      # @param value [Object]
      # @param clazz [Class]
      # @return [Array<Object>, nil]
      def force_array(value, clazz)
        value if value.is_a?(Array) && value.all? { |e| e.is_a?(clazz) }
      end
    end

    # Manages an entity of a specific {VPS::EntityType}
    #
    # None of the methods in this class has a default implementation!
    #
    # @abstract
    class Repository
      # @return [Class<VPS::EntityType::BaseType>]
      # @abstract
      def supported_entity_type
        raise "#{self.class.name}.supported_entity_type is not yet implemented!"
      end

      # Lists all entities in this repository, or as many as can be handled.
      #
      # @param context [VPS::RepositoryContext]
      # @return [Array<VPS::EntityType::BaseType>]
      # @abstract
      def find_all(context)
        raise "#{self.class.name}.find_all is not yet implemented!"
      end

      # Loads a single entity instance from the context
      #
      # For invocations from the command line, the ID of the instance to load can be pulled
      # from the program arguments. For invocations by Alfred, an instance used earlier in
      # the same workflow might be available in the environment. In the latter case it might
      # not be necessary to fetch the instance from the application that is managed by the
      # plugin.
      #
      # @param context [VPS::RepositoryContext]
      # @return [VPS::EntityType::BaseType, nil]
      # @abstract
      def load_instance(context)
        raise "#{self.class.name}.load is not yet implemented!"
      end

      # Persists an instance, or, if this would lead to a duplicate, return the original.
      #
      # @param context [VPS::RepositoryContext]
      # @param instance [VPS::EntityType::BaseType] Instance to persist
      # @abstract
      def create_or_find(context, instance)
        raise "#{self.class.name}.create_or_find is not yet implemented!"
      end
    end

    # Base class for other commands
    # @abstract
    class Command
      # @return [String] the name of this commands, defaults to the short class name.
      def name
        self.class.name.split('::').last.downcase
      end

      # @return [Class<VPS::EntityType::BaseType>]
      # @abstract
      def supported_entity_type
        raise "#{self.class.name}.supported_entity_type is not yet implemented!"
      end

      # @return [OptionParser]
      # @abstract
      def option_parser
        raise "#{self.class.name}.option_parser is not yet implemented!"
      end

      # @param context [VPS::CommandContext]
      # @return [String, Array, nil]
      # @abstract
      def run(context)
        raise "#{self.class.name}.run is not yet implemented!"
      end
    end

    # Command that acts on an entity type, not on a specific instance.
    #
    # Examples: "list all projects", "create a new note"
    # @abstract
    class EntityTypeCommand < Command
    end

    # Command that acts on a specific instance of an entity type.
    #
    # Examples: "view this contact", "edit this note"
    # @abstract
    class EntityInstanceCommand < Command
    end

    # Command that acts on an instance of one entity type, for another entity type.
    #
    # Example: "create a note for this project"
    # @abstract
    class CollaborationCommand < Command
      # @return [Class<VPS::EntityType::BaseType>]
      # @abstract
      def collaboration_entity_type
        raise "#{self.class.name}.collaboration_entity_type is not yet implemented!"
      end
    end

    # Command that acts on the complete VPS internal system. See {VPS::Plugin::Area}.
    # Normally you shouldn't need to implement a command such as this yourself.
    # @abstract
    class SystemCommand < Command
      # @param context [VPS::SystemContext]
      # @return [String, Array, nil]
      # @abstract
      def run(context)
        raise "#{self.class.name}.run is not yet implemented!"
      end
    end

    ##
    # An action that gets triggered when the focus changes.
    # @abstract
    class Action
      # @param context [VPS::SystemContext]
      # @return void
      # @abstract
      def run(context)
        raise "#{self.class.name}.run is not yet implemented!"
      end
    end
  end
end
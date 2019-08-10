module VPS
  ##
  # Registration of all plugins, the commands they support, and so on.
  # Any new plugin needs to be added here.
  module Registry

    module WithName
      def to_short_name(clazz)
        clazz.name.split('::').last.downcase
      end

      def name
        to_short_name(name_class)
      end
    end

    class Command
      include WithName

      attr_reader :command_class, :type

      def initialize(command_class, type)
        @command_class = command_class
        @type = type
      end

      def name_class
        @command_class
      end
    end

    class Plugin
      include WithName

      attr_reader :plugin_module, :entity_class, :collaborates_with, :commands, :action_class

      def initialize(plugin_module)
        @plugin_module = plugin_module
        @entity_class = nil
        @collaborates_with = []
        @commands = {}
        @action_class = nil
      end

      def name_class
        @plugin_module
      end

      def entity_class_name
        raise "You shouldn't be calling this" if @entity_class.nil?
        to_short_name(@entity_class)
      end

      def for_entity(entity_class)
        @entity_class = entity_class
      end

      def add_command(command_class, type)
        command = Command.new(command_class, type)
        @commands[command.name] = command
      end

      def with_action(action_class)
        @action_class = action_class
      end

      def add_collaboration(entity_class)
        @collaborates_with << entity_class
      end
    end

    @@plugins = {}

    def self.register(plugin_module)
      plugin = Plugin.new(plugin_module)
      yield plugin
      @@plugins[plugin.name] = plugin
    end

    def self.commands
      @@plugins.reject do |_, plugin|
        plugin.commands.empty?
      end
    end

    def self.plugins
      @@plugins
    end

    def self.entity_managers
      @@plugins.values.reject do |plugin|
        plugin.entity_class.nil?
      end
    end

    def self.entity_managers_for(entity_name)
      @@plugins.values.select do |plugin|
        plugin.entity_class != nil && plugin.entity_class_name == entity_name
      end
    end

    def self.collaborators(entity_class)
      @@plugins.values.select do |plugin|
        plugin.collaborates_with.include?(entity_class)
      end
    end
  end
end
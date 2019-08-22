module VPS
  ##
  # Registration of all plugins, the commands they support, and so on.
  # Any new plugin needs to be added here.
  class Registry

    module WithName
      def to_short_name(clazz)
        clazz.name.split('::').last.downcase
      end
    end

    class Command
      include WithName

      attr_reader :command_class, :type

      def initialize(command_class, type)
        @command_class = command_class
        @type = type
      end

      def name
        to_short_name(@command_class)
      end
    end

    class Plugin
      include WithName

      attr_reader :plugin_module, :entity_class, :collaborates_with, :commands, :action_class

      attr_reader :name, :repositories
      attr_accessor :configurator

      def initialize(plugin_module)
        @plugin_module = plugin_module
        @entity_class = nil
        @collaborates_with = []
        @commands = {}
        @action_class = nil

        @name = to_short_name(plugin_module)
        @repositories = {}
        @configurator = PluginSupport::Configurator.new
      end

      def name_class
        @plugin_module
      end

      def entity_class_name
        raise "You shouldn't be calling this" if @entity_class.nil?
        to_short_name(@entity_class)
      end

      def add_repository(entity_class, repository)
        repositories[entity_class] = repository
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

    attr_reader :plugins

    def initialize
      @plugins = VPS::Plugins.constants(false)
                   .map { |c| VPS::Plugins.const_get(c) }
                   .select { |c| c.is_a?(Module) && c.singleton_methods(false).include?(:configure_plugin) }
                   .map { |m| p = Plugin.new(m); m.configure_plugin(p); [p.name, p] }
                   .to_h
    end

    def entity_managers
      @plugins.values.reject do |plugin|
        plugin.entity_class.nil?
      end
    end

    def entity_managers_for(entity_name)
      @plugins.values.select do |plugin|
        plugin.entity_class != nil && plugin.entity_class_name == entity_name
      end
    end

    def collaborators(entity_class)
      @plugins.values.select do |plugin|
        plugin.collaborates_with.include?(entity_class)
      end
    end
  end
end
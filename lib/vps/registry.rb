module VPS
  ##
  # Registration of all plugins, the commands they support, and so on.
  # Any new plugin needs to be added here.
  class Registry

    module WithKey
      def to_key(clazz)
        clazz.name.split('::').last.downcase
      end
    end

    class Command
      include WithKey

      attr_reader :command_class, :type

      def initialize(command_class, type)
        @command_class = command_class
        @type = type
      end

      def key
        to_key(@command_class)
      end
    end

    class Plugin
      include WithKey

      attr_reader :plugin_module, :entity_class, :collaborates_with, :repositories, :commands, :action_class

      attr_reader :key
      attr_accessor :configurator_class

      def initialize(plugin_module)
        @plugin_module = plugin_module
        @collaborates_with = []
        @repositories = []
        @commands = {}
        @action_class = nil

        @key = to_key(plugin_module)
        @configurator_class = nil
      end

      def configurator
        if @configurator_class.nil?
          PluginSupport::Configurator.new
        else
          @configurator_class.new
        end
      end

      def name_class
        @plugin_module
      end

      def entity_class_name
        raise "You shouldn't be calling this" if @entity_class.nil?
        to_key(@entity_class)
      end

      def for_entity(entity_class)
        @entity_class = entity_class
      end

      def add_repository(repository_class)
        @repositories << repository_class
      end

      def add_command(command_class, type)
        command = Command.new(command_class, type)
        @commands[command.key] = command
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
                   .map { |m| p = Plugin.new(m); m.configure_plugin(p); [p.key, p] }
                   .to_h
    end

    def repositories
      @plugins.values.filter_map { |plugin| plugin.repositories }.flatten
    end

    def repositories_for
      repositories.select { |r| r.entity_class == entity_class }
    end

    def collaborators(entity_class)
      @plugins.values.select do |plugin|
        plugin.collaborates_with.include?(entity_class)
      end
    end
  end
end
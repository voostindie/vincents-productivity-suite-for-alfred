module VPS

  ##
  # Registry of all plugins in the system.
  class Registry
    include Singleton

    attr_reader :plugins

    def initialize
      @plugins = VPS::Plugins.constants(false)
                   .map { |c| VPS::Plugins.const_get(c) }
                   .select { |c| c.is_a?(Module) && c.include?(VPS::Plugin) }
                   .map { |m| Plugin.new(m) }
                   .map { |p| [p.name, p] }
                   .to_h
                   .freeze
    end

    def for_command(command)
      @plugins.values.select { |p| p.commands.include?(command) }.first
    end

    def for_repository(repository)
      @plugins.values.select { |p| p.repositories.include?(repository) }.first
    end

    class Plugin
      attr_reader :name, :configurator, :repositories, :commands, :action

      def initialize(plugin_module)
        @configurator = new_configurator(plugin_module)
        @name = @configurator.plugin_name || plugin_module.name.split('::').last.downcase
        @repositories = new_repositories(plugin_module)
        @commands = new_commands(plugin_module)
        @action = new_action(plugin_module)
      end

      private

      def new_configurator(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::BaseConfigurator).first ||
          VPS::Plugin::BaseConfigurator.new
      end

      def new_repositories(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::BaseRepository)
      end

      def new_commands(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::BaseCommand)
      end

      def new_action(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::BaseAction).first
      end

      def instantiate_classes(plugin, super_class)
        plugin.constants(false)
          .map { |c| plugin.const_get(c) }
          .select { |c| c.is_a?(Class) && c < super_class }
          .map { |c| c.new }
      end
    end
  end
end

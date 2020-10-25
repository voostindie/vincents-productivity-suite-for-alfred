module VPS
  # Registry of all plugins in the system. All plugins are discovered automatically, as long as they
  # are defined as modules within the {VPS::Plugins}} module.
  class Registry
    include Singleton

    # @return [Hash<String,Plugin>] Map of all plugins
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

    # @param command [VPS::Plugin::Command]
    # @return [Plugin,nil] The plugin that defines the command
    def for_command(command)
      @plugins.values.select { |p| p.commands.include?(command) }.first
    end

    # @param repository [VPS::Plugin::repository]
    # @return [Plugin,nil] The plugin that defines the repository
    def for_repository(repository)
      @plugins.values.select { |p| p.repositories.include?(repository) }.first
    end

    # Collects all information on a single plugin
    class Plugin
      # @return [String] name of the plugin
      attr_reader :name
      # @return [VPS::Plugin::Configurator] plugin configurator
      attr_reader :configurator
      # @return [Array<VPS::Plugin::Configurator>] all repositories from the plugin
      attr_reader :repositories
      # @return [Array<VPS::Plugin::Command>] all commands from the plugin
      attr_reader :commands
      # @return [Array<VPS::Plugin::Action>] all actions from the plugin
      attr_reader :action

      def initialize(plugin_module)
        @configurator = new_configurator(plugin_module)
        @name = @configurator.plugin_name || plugin_module.name.split('::').last.downcase
        @repositories = new_repositories(plugin_module)
        @commands = new_commands(plugin_module)
        @action = new_action(plugin_module)
      end

      private

      def new_configurator(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::Configurator).first ||
          VPS::Plugin::Configurator.new
      end

      def new_repositories(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::Repository)
      end

      def new_commands(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::Command)
      end

      def new_action(plugin_module)
        instantiate_classes(plugin_module, VPS::Plugin::Action).first
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

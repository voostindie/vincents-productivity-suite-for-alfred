module VPS
  class Context
    # @return [Hash<String, Object>]
    attr_reader :area
    # @return [Array<String>]
    attr_reader :arguments
    # @return [Hash<String, String>]
    attr_reader :environment

    def initialize(area, arguments, environment)
      @area = area
      @arguments = arguments
      @environment = environment
    end

    def area_key
      @area[:key]
    end

    def resolve_command(entity_type_name, command_name)
      @area.keys
           .filter_map { |name| Registry.instance.plugins[name] }
           .map { |plugin| plugin.commands }
           .flatten
           .select { |command| command.supported_entity_type.entity_type_name == entity_type_name }
           .select { |command| command.name == command_name }
           .first
    end

    def resolve_repository(entity_type_name)
      @area.keys
           .filter_map { |name| Registry.instance.plugins[name] }
           .map { |plugin| plugin.repositories }
           .flatten
           .select { |repository| repository.supported_entity_type.entity_type_name == entity_type_name }
           .first
    end

    # @param repository [Repository] repository to create the context for.
    # @return [RepositoryContext] new context for the given repository
    def for_repository(repository)
      plugin = Registry.instance.for_repository(repository)
      plugin_configuration = @area[plugin.name]
      RepositoryContext.new(self, plugin_configuration)
    end

    # @param command [Command] command to create the context for.
    # @return [CommandContext] new context for the given command.
    def for_command(command, entity_type_contexts = {})
      plugin = Registry.instance.for_command(command)
      plugin_configuration = @area[plugin.name]
      CommandContext.new(self, plugin_configuration, entity_type_contexts)
    end

    # @return [SystemContext] new system context.
    def for_system(configuration, state)
      SystemContext.new(self, configuration, state)
    end
  end

  class RepositoryContext < Context
    # @return Hash
    attr_reader :configuration

    # Creates a new repository context. Don't call this method directly. Instead, use Context#for_repository.
    def initialize(context, plugin_configuration)
      super(context.area, context.arguments, context.environment)
      @configuration = plugin_configuration
    end
  end

  class CommandContext < RepositoryContext
    # Creates a new repository context. Don't call this method directly. Instead, use Context#for_command.
    def initialize(context, plugin_configuration, entity_type_contexts = {})
      super(context, plugin_configuration)
      @entity_type_contexts = entity_type_contexts
      @entity_instance = nil
    end

    # @return [Boolean]
    def triggered_as_snippet?
      environment['TRIGGERED_AS_SNIPPET'] == 'true'
    end

    # Methods below are from {VPS::Plugin::Repository}, but without context.
    # Through this context we ensure that each repository is passed the correct context.

    # @return [Array<VPS::EntityType::BaseType>]
    def find_all(entity_type = @entity_type_contexts.keys.first)
      entity_type_context = @entity_type_contexts[entity_type]
      entity_type_context[:repository].find_all(entity_type_context[:context])
    end

    ##
    # @return [VPS::EntityType::BaseType, nil]
    def load_instance
      entity_type_context = @entity_type_contexts[@entity_type_contexts.keys.first]
      @entity_instance ||= entity_type_context[:repository].load_instance(entity_type_context[:context])
    end

    ##
    # @param instance [VPS::EntityType::BaseType]
    def create_or_find(instance, entity_type = @entity_type_contexts.keys.first)
      entity_type_context = @entity_type_contexts[entity_type]
      entity_type_context[:repository].create_or_find(entity_type_context[:context], instance)
    end
  end

  class SystemContext < Context
    # @return [Configuration]
    attr_reader :configuration
    # @return [State]
    attr_reader :state

    # Creates a new system context. Don't call this method directly. Instead, use Context#for_system
    def initialize(context, configuration, state)
      super(context.area, context.arguments, context.environment)
      @configuration = configuration
      @state = state
    end

    # Changes the focus to the specified area. The new focus is persisted.
    # @param area [Hash] the area to focus on.
    def change_focus(area)
      @state.change_focus(area[:key], @configuration)
      @state.persist
      @area = @state.focus
    end
  end
end
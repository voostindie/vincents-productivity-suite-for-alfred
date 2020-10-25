module VPS
  class RepositoryContext
    # @return [String]
    attr_reader :area_key
    # @return [Configuration]
    attr_reader :configuration
    # @return [Array<String>]
    attr_reader :arguments
    # @return [Hash<String, String>]
    attr_reader :environment

    def initialize(area, plugin_name, arguments, environment)
      @area_key = area[:key]
      @configuration = area[plugin_name]
      @arguments = arguments
      @environment = environment
    end
  end

  class CommandContext < RepositoryContext
    def initialize(area, plugin_name, arguments, environment, entity_type_contexts = {})
      super(area, plugin_name, arguments, environment)
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

  class SystemContext
    # @return [Configuration]
    attr_reader :configuration
    # @return [Hash<String, Object>]
    attr_reader :area
    # @return [State]
    attr_reader :state
    # @return [Array<String>]
    attr_reader :arguments

    def initialize(configuration, state, arguments)
      @configuration = configuration
      @state = state
      @area = @state.focus
      @arguments = arguments
    end
  end
end
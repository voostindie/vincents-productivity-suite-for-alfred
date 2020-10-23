module VPS
  class Context
    attr_reader :configuration, :repository, :arguments, :environment

    def initialize(configuration, arguments, environment, repository = nil, repository_context = nil)
      @configuration = configuration
      @arguments = arguments
      @environment = environment
      @repository = repository
      @repository_context = repository_context
      @instance = nil
    end

    def triggered_as_snippet?
      environment['TRIGGERED_AS_SNIPPET'] == 'true'
    end

    # Methods below are from BaseRepository, without context. Here we ensure the correct context is passed.

    ##
    # @return [VPS::EntityTypes::BaseType]+
    def find_all
      @repository.find_all(@repository_context)
    end

    ##
    # @return [VPS::EntityTypes::BaseType]
    def load
      @instance ||= @repository.load(@repository_context)
    end

    ##
    # @param instance [VPS::EntityTypes::BaseType]
    def create_or_find(instance)
      @repository.create_or_find(@repository_context, instance)
    end
  end
end
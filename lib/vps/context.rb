module VPS
  class Context
    attr_reader :configuration, :repository
    attr_accessor :arguments, :environment

    def initialize(configuration, repository, arguments, environment)
      @configuration = configuration
      @repository = repository
      @arguments = arguments
      @environment = environment
    end

    def triggered_as_snippet?
      environment['TRIGGERED_AS_SNIPPET'] == 'true'
    end
  end
end
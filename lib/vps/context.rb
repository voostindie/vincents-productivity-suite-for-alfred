module VPS
  class Context
    attr_reader :configuration, :state
    attr_accessor :arguments, :environment

    def initialize(configuration, state, arguments, environment)
      @configuration = configuration
      @state = state
      @arguments = arguments
      @environment = environment
    end

    def focus
      @state.focus
    end

    def load_entity(entitu_class)
      @configuration.entity_manager_for_class(@state.focus, entitu_class).plugin_module.load_entity(self)
    end

    def collaborator_commands(entity)
      commands = []
      collaborators = @configuration.collaborators(@state.focus, entity.class)
      collaborators.each do |collaborator|
        commands << collaborator.plugin_module.commands_for(@state.focus, entity)
      end
      commands.flatten
    end
  end
end
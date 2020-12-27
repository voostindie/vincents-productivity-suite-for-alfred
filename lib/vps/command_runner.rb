module VPS
  # Runs a command. Before a command can be executed, its context first has to configured.
  # This context depends on the type of command that's going to run.
  class CommandRunner
    attr_reader :command

    def initialize(configuration, state, arguments, environment)
      @configuration = configuration
      @state = state
      @area = @state.focus
      entity_type_name = arguments.shift
      command_name = arguments.shift
      @context = Context.new(@area, arguments, environment)
      @command = @context.resolve_command(entity_type_name, command_name)
      raise "Invalid command '#{command_name}' for command group '#{entity_type_name}'" if @command.nil?
    end

    def help_available?
      !@command.option_parser.nil?
    end

    # @return [OptionParser]
    def help
      @command.option_parser
    end

    # Sets up the command context and executes the command
    # @return void
    def execute
      command_context = create_context
      if @command.is_a?(VPS::Plugin::EntityInstanceCommand) || @command.is_a?(VPS::Plugin::CollaborationCommand)
        instance = command_context.load_instance
        raise 'Aborting. Could not load entity instance. Did you specify an identifier?' if instance.nil?
      end
      @command.run(command_context)
    end

    private

    def create_context
      if @command.is_a?(VPS::Plugin::SystemCommand)
        @context.for_system(@configuration, @state)
      else
        # Set up the repositories and their contexts for use by the command
        entity_types = [@command.supported_entity_type]
        entity_types << @command.collaboration_entity_type if @command.is_a?(VPS::Plugin::CollaborationCommand)
        entity_type_contexts = entity_types.map do |entity_type|
          repository = @context.resolve_repository(entity_type.entity_type_name)
          [entity_type, { repository: repository, context: @context.for_repository(repository) }]
        end.to_h
        @context.for_command(@command, entity_type_contexts)
      end
    end
  end
end

module VPS

  class CommandRunner
    def initialize(area, arguments, environment)
      @area = area
      @arguments = arguments
      @environment = environment
      entity_type_name = @arguments.shift
      command_name = @arguments.shift
      @command = resolve_command(entity_type_name, command_name)
      @command = resolve_command(entity_type_name, command_name)
      if @command.nil?
        raise "Invalid command '#{command_name}' for command group '#{entity_type_name}'"
      end
    end

    def help_available?
      !@command.option_parser.nil?
    end

    def help
      @command.option_parser
    end

    def execute
      repository = resolve_repository(@command.supported_entity_type)
      repository_plugin = Registry.instance.for_repository(repository)
      repository_context = Context.new(@area[repository_plugin.name], @arguments, @environment)

      command_plugin = Registry.instance.for_command(@command)
      command_context = Context.new(@area[command_plugin.name], @arguments, @environment, repository, repository_context)
      if @command.is_a?(VPS::Plugin::EntityInstanceCommand)
        instance = command_context.load
        if instance.nil?
          raise "Aborting. Could not load entity instance!"
        end
      end
      @command.run(command_context)
    end

    private

    def resolve_command(entity_type_name, command_name)
      @area.keys
        .filter_map { |name| Registry.instance.plugins[name] }
        .map { |plugin| plugin.commands }
        .flatten
        .select { |command| command.supported_entity_type.entity_type_name == entity_type_name }
        .select { |command| command.name == command_name }
        .first
    end

    def resolve_repository(entity_type)
      @area.keys
        .filter_map { |name| Registry.instance.plugins[name] }
        .map { |plugin| plugin.repositories }
        .flatten
        .select { |repository| repository.supported_entity_type == entity_type }
        .first
    end
  end
end
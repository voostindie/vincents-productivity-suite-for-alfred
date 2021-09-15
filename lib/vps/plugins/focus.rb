module VPS
  module Plugins
    # Plugin that can "focus" on an entity instance by executing multiple commands on
    # a single instance consecutively. Which commands to execute is set in the configuration.
    # Supported entities are "project", "contact" and "event". Other entities are easily
    # supported as well (see the code below), but I didn't see the point yet.
    module Focus
      include Plugin

      class FocusConfigurator < Configurator
        def process_area_configuration(_area, hash)
          {
            project: force_array(hash['project'], String) || [],
            contact: force_array(hash['contact'], String) || [],
            event: force_array(hash['event'], String) || []
          }
        end
      end

      module FocusCommand

        def name
          'focus'
        end

        def commands(context)
          context.configuration[supported_entity_type.entity_type_name.to_sym] || []
        end

        def enabled?(context, _instance)
          !commands(context).empty?
        end

        def option_parser
          entity = supported_entity_type.entity_type_name
          OptionParser.new do |parser|
            parser.banner = "Focus on this #{entity}"
            parser.separator "Usage: {entity} focus <#{entity}Id>"
            parser.separator ''
            parser.separator "Runs several commands on the same #{entity} at once"
            parser.separator 'Set the commands to run in the configuration'
          end
        end

        def run(context)
          commands(context).map do |command_name|
            next if command_name == 'focus' # Prevent an endless loop...
            command = context.resolve_command(supported_entity_type.entity_type_name, command_name)
            next if command.nil?
            next unless command.is_a?(Plugin::EntityInstanceCommand) || command.is_a?(Plugin::CollaborationCommand)
            puts command_name
            command_context = if command.is_a?(Plugin::CollaborationCommand)
                                entity_type = command.collaboration_entity_type
                                repository = context.resolve_repository(entity_type.entity_type_name)
                                context.for_command(command, { entity_type => { repository: repository, context: context.for_repository(repository) } })
                              else
                                context.for_command(command)
                              end
            command.run(command_context) if command.enabled?(command_context, context.load_instance)
          end
          entity = supported_entity_type.entity_type_name
          instance = context.load_instance
          "Focused on #{entity} #{instance.name}"
        end
      end

      class ProjectFocus < EntityInstanceCommand
        include FocusCommand

        def supported_entity_type
          EntityType::Project
        end
      end

      class ContactFocus < EntityInstanceCommand
        include FocusCommand

        def supported_entity_type
          EntityType::Contact
        end
      end

      class EventFocus < EntityInstanceCommand
        include FocusCommand

        def supported_entity_type
          EntityType::Event
        end
      end
    end
  end
end

module VPS
  module Plugins
    # Plugin that paste values from entities to the front-most app. This plugin is automatically
    # enabled. It has no configuration, so that's easy. You get these commands for free with each
    # entity that has a supporting repository.
    #
    # (To see how this plugin is automatically enabled: see {Configuration})
    module Paste
      include Plugin

      # Support module for commands that paste values from entities.
      module PasteTemplate
        def name
          'paste'
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = "Paste #{description} to the frontmost app"
            parser.separator "Usage: #{entity_name} paste <#{entity_name}Id>"
            parser.separator ''
            parser.separator "Where <#{entity_name}Id> is the ID of the #{entity_name} to paste."
            parser.separator ''
            parser.separator 'This plugin obviously has very little use outside of Alfred...'
          end
        end

        def entity_name
          supported_entity_type.entity_type_name
        end

        def description
          entity_name
        end

        def run(context, runner = JxaRunner.new('alfred'))
          entity = context.load_instance
          text = text_from(entity)
          runner.execute('paste', text)
          nil
        end

        # @param _entity [VPS::EntityType::BaseType]
        # @return [String]
        # @abstract
        def text_from(_entity)
          raise NotImplementedError
        end
      end

      # Command to paste a note title as a [[WikiLink]] to the front-most app
      class Note < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityType::Note
        end

        def text_from(note)
          aliaz = note.title
          name = File.basename(note.path, '.md')
          path = if note.is_unique
                   name
                 else
                   note.path[..-3]
                 end
          if name == aliaz
            "[[#{path}]]"
          else
            "[[#{path}|#{aliaz}]]"
          end
        end
      end

      # Command to paste a project name to the front-most app
      class Project < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityType::Project
        end

        def text_from(project)
          project.name
        end
      end

      ## Command to paste a contact name to the front-most app
      class Contact < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityType::Contact
        end

        def text_from(contact)
          contact.name
        end
      end

      # Command to paste an event title to the front-most app
      class Event < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityType::Event
        end

        def text_from(event)
          event.title
        end
      end

      # Command to paste a list of event attendees to the front-most app
      class EventAttendees < EntityInstanceCommand
        include PasteTemplate

        def name
          'paste-attendees'
        end

        def description
          'event attendees'
        end

        def supported_entity_type
          EntityType::Event
        end

        def text_from(event)
          event.people.join(', ')
        end
      end

      # Command to paste a list of people from a group to the front-most app
      class Group < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityType::Group
        end

        def text_from(group)
          group.people.map { |p| "\"#{p['name']}\" <#{p['email']}>" }.join(', ')
        end
      end
    end
  end
end

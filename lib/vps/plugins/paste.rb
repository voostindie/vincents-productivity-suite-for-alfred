module VPS
  module Plugins
    module Paste
      include Plugin

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

        def run(context, runner = Jxa::Runner.new('alfred'))
          runner.execute('paste', text_from(context.load))
          nil
        end

        def text_from(entity)
          nil
        end
      end

      class Note < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityTypes::Note
        end

        def text_from(note)
          note.id
        end
      end

      class Project < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityTypes::Project
        end

        def text_from(project)
          project.name
        end
      end

      class Contact < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityTypes::Contact
        end

        def text_from(contact)
          contact.name
        end
      end

      class Event < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityTypes::Event
        end

        def text_from(event)
          event.title
        end
      end

      class EventAttendees < EntityInstanceCommand
        include PasteTemplate

        def name
          'paste-attendees'
        end

        def description
          'event attendees'
        end

        def supported_entity_type
          EntityTypes::Event
        end

        def text_from(event)
          event.people.join(', ')
        end
      end

      class Group < EntityInstanceCommand
        include PasteTemplate

        def supported_entity_type
          EntityTypes::Group
        end

        def text_from(group)
          group.people.map { |p| "\"#{p['name']}\" <#{p['email']}>" }.join(', ')
        end
      end
    end
  end
end
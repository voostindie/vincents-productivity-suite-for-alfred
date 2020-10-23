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
            name = entity_name
            parser.banner = "Paste #{description} to the frontmost app"
            parser.separator "Usage: #{name} paste <#{name}Id>"
            parser.separator ''
            parser.separator "Where <#{name}Id> is the ID of the #{name} to paste."
            parser.separator ''
            parser.separator 'This plugin obviously has very little use outside of Alfred...'
          end
        end

        def entity_name
          supported_entity_type.entity_type_name
        end

        def description
          "a #{entity_name} name"
        end

        def run(context, runner = Jxa::Runner.new('alfred'))
          # TODO: re-enable caching
          # entity = cache(@context.arguments.join(' ')) do
          entity = context.load
          # end
          runner.execute('paste', text_from(entity))
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

        def description
          'an event'
        end

        def text_from(event)
          event.title
        end
      end

      class EventAttendees < EntityInstanceCommand
        include PasteTemplate

        def name
          'paste-att'
        end

        def description
          'all attendees from an event'
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

      # def self.commands_for(area, entity)
      #   if entity.is_a?(Types::Note)
      #     {
      #       title: 'Paste note name to the frontmost app',
      #       arg: "text note #{entity.id}",
      #       icon: {
      #         path: "icons/clipboard.png"
      #       }
      #     }
      #   elsif entity.is_a?(Types::Project)
      #     {
      #       title: 'Paste project name to the frontmost app',
      #       arg: "text project #{entity.id}",
      #       icon: {
      #         path: "icons/clipboard.png"
      #       }
      #     }
      #   elsif entity.is_a?(Types::Contact)
      #     {
      #       title: 'Paste contact name to the frontmost app',
      #       arg: "text contact #{entity.id}",
      #       icon: {
      #         path: "icons/clipboard.png"
      #       }
      #     }
      #   elsif entity.is_a?(Types::Event)
      #     {
      #       title: 'Paste event title to the frontmost app',
      #       arg: "text event #{entity.id}",
      #       icon: {
      #         path: "icons/clipboard.png"
      #       }
      #     }
      #   elsif entity.is_a?(Types::Group)
      #     {
      #       title: 'Paste group addresses to the frontmost app',
      #       arg: "text group #{entity.id}",
      #       icon: {
      #         path: "icons/clipboard.png"
      #       }
      #     }
      #   else
      #     raise "Unsupported entity class for collaboration: #{entity.class}"
      #   end
      # end
      #
    end
  end
end
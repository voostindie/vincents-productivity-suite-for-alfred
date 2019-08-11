module VPS
  module Plugins
    module Paste

      def self.commands_for(entity)
        if entity.is_a?(Entities::Project)
          {
            title: 'Paste project name to the frontmost app',
            arg: "paste project #{entity.id}",
            icon: {
              path: "icons/clipboard.png"
            }
          }
        elsif entity.is_a?(Entities::Contact)
          {
            title: 'Paste contact name to the frontmost app',
            arg: "paste contact #{entity.id}",
            icon: {
              path: "icons/clipboard.png"
            }
          }
        elsif entity.is_a?(Entities::Event)
          {
            title: 'Pate event title to the frontmost app',
            arg: "paste event #{entity.id}",
            icon: {
              path: "icons/clipboard.png"
            }
          }
        else
          raise "Unsupported entity class for collaboration: #{entity.class}"
        end
      end

      class PasteTemplate
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = "Paste the #{entity_name} name to the frontmost app"
            parser.separator "Usage: paste #{entity_name} <#{entity_name}Id>"
            parser.separator ''
            parser.separator "Where <#{entity_name}Id> is the ID of the #{entity_name} to paste."
            parser.separator ''
            parser.separator 'This plugin obviously has very little use outside of Alfred...'
          end
        end

        def can_run
          is_entity_present?(entity_class) && is_entity_manager_available?(entity_class)
        end

        def run(runner = Jxa::Runner.new('alfred'))
          entity = @context.load_entity(entity_class)
          runner.execute('paste', text_from(entity))
          nil
        end

        def self.entity_name
          nil
        end

        def entity_class
          nil
        end

        def text_from(entity)
          nil
        end
      end

      class Project < PasteTemplate

        def self.entity_name
          'project'
        end

        def entity_class
          Entities::Project
        end

        def text_from(project)
          project.name
        end
      end

      class Contact < PasteTemplate

        def self.entity_name
          'contact'
        end

        def entity_class
          Entities::Contact
        end

        def text_from(contact)
          contact.name
        end
      end

      class Event < PasteTemplate

        def self.entity_name
          'event'
        end

        def entity_class
          Entities::Event
        end

        def text_from(event)
          event.title
        end
      end

      Registry.register(Paste) do |plugin|
        plugin.for_entity(Entities::Text)
        plugin.add_command(Project, :single)
        plugin.add_command(Contact, :single)
        plugin.add_command(Event, :single)
        plugin.add_collaboration(Entities::Project)
        plugin.add_collaboration(Entities::Contact)
        plugin.add_collaboration(Entities::Event)
      end
    end
  end
end
module VPS
  module Plugins
    module Paste
      include Plugin

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
      # class PasteTemplate
      #   include PluginSupport, CacheSupport
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = "Paste the #{entity_name} name to the frontmost app"
      #       parser.separator "Usage: paste #{entity_name} <#{entity_name}Id>"
      #       parser.separator ''
      #       parser.separator "Where <#{entity_name}Id> is the ID of the #{entity_name} to paste."
      #       parser.separator ''
      #       parser.separator 'This plugin obviously has very little use outside of Alfred...'
      #     end
      #   end
      #
      #   def can_run
      #     is_entity_present?(entity_class) && is_entity_manager_available?(entity_class)
      #   end
      #
      #   def run(runner = Jxa::Runner.new('alfred'))
      #     entity = cache(@context.arguments.join(' ')) do
      #       @context.load_entity(entity_class)
      #     end
      #     runner.execute('paste', text_from(entity))
      #     nil
      #   end
      #
      #   def self.entity_name
      #     nil
      #   end
      #
      #   def entity_class
      #     nil
      #   end
      #
      #   def text_from(entity)
      #     nil
      #   end
      # end
      #
      # class Note < PasteTemplate
      #   def self.entity_name
      #     'note'
      #   end
      #
      #   def entity_class
      #     Types::Note
      #   end
      #
      #   def text_from(note)
      #     note.id
      #   end
      # end
      #
      # class Project < PasteTemplate
      #
      #   def self.entity_name
      #     'project'
      #   end
      #
      #   def entity_class
      #     Types::Project
      #   end
      #
      #   def text_from(project)
      #     project.name
      #   end
      # end
      #
      # class Contact < PasteTemplate
      #
      #   def self.entity_name
      #     'contact'
      #   end
      #
      #   def entity_class
      #     Types::Contact
      #   end
      #
      #   def text_from(contact)
      #     contact.name
      #   end
      # end
      #
      # class Event < PasteTemplate
      #
      #   def self.entity_name
      #     'event'
      #   end
      #
      #   def entity_class
      #     Types::Event
      #   end
      #
      #   def text_from(event)
      #     event.title
      #   end
      # end
      #
      # class Group < PasteTemplate
      #   def self.entity_name
      #     'group'
      #   end
      #
      #   def cache_enabled?
      #     # This is technically incorrect, because it looks into the configuration of the 'groups' plugin
      #     # which it should not even know about...
      #     @context.focus['groups'][:cache] == true
      #   end
      #
      #   def entity_class
      #     Types::Group
      #   end
      #
      #   def text_from(group)
      #     group.people.map { |p| "\"#{p['name']}\" <#{p['email']}>" }.join(', ')
      #   end
      # end
    end
  end
end
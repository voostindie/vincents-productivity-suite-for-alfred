module VPS
  module Plugins
    module Bear

      def self.read_area_configuration(area, hash)
        {
          tags: hash['tags'] || []
        }
      end

      def self.commands_for(entity)
        if entity.is_a?(Entities::Project)
          {
            title: 'Create a note in Bear',
            arg: "note project #{entity.id}",
            icon: {
              path: "icons/bear.png"
            }
          }
        elsif entity.is_a?(Entities::Contact)
          {
            title: 'Create a note in Bear',
            arg: "note contact #{entity.id}",
            icon: {
              path: "icons/bear.png"
            }
          }
        elsif entity.is_a?(Entities::Event)
          {
            title: 'Create a note in Bear',
            arg: "note event #{entity.id}",
            icon: {
              path: "icons/bear.png"
            }
          }
        else
          raise "Unsupported entity class for collaboration: #{entity.class}"
        end
      end

      class Plain
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create a new, empty note, optionally with a title'
            parser.separator 'Usage: note plain [title]'
          end
        end

        def run(runner = Shell::SystemRunner.new)
          context = create_context
          title = ERB::Util.url_encode(context[:title])
          tags = create_tags
                   .map { |t| merge_template(t, context) }
                   .map { |t| ERB::Util.url_encode(t) }
                   .join(',')
          callback = "bear://x-callback-url/create?title=#{title}&tags=#{tags}"
          runner.execute('open', callback)
          "Created a new note in Bear with title '#{context[:title]}'"
        end

        def create_context
          date = DateTime.now
          {
            year: date.strftime('%Y'),
            month: date.strftime('%m'),
            week: date.strftime('%V'),
            day: date.strftime('%d'),
            title: create_title,
          }
        end

        def create_title
          @context.arguments.join(' ')
        end

        def create_tags
          @context.focus['bear'][:tags]
        end

        def merge_template(template, context)
          result = template.dup
          context.each_pair do |key, value|
            result.gsub!('$' + key.to_s, value)
          end
          result
        end
      end

      class Project < Plain
        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create a new note for a project'
            parser.separator 'Usage: note project <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to create a note for'
          end
        end

        def can_run?
          is_entity_present?(Entities::Project) && is_entity_manager_available?(Entities::Project)
        end

        def run
          @project = @context.load_entity(Entities::Project)
          super
        end

        def create_title
          strip_emojis(@project.name)
        end
      end

      class Contact < Plain
        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create a new note for a contact'
            parser.separator 'Usage: note contact <contactId>'
            parser.separator ''
            parser.separator 'Where <contactId> is the ID of the contact to create a note for'
          end
        end

        def can_run?
          is_entity_present?(Entities::Contact) && is_entity_manager_available?(Entities::Contact)
        end

        def run
          @contact = @context.load_entity(Entities::Contact)
          super
        end

        def create_title
          @contact.name
        end

        def create_tags
          ## TODO: make the contact tags configurable.
          super << "#{@context.focus[:name]}/Contacts/#{@contact.name}"
        end
      end

      class Event < Plain
        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create a new note for an event'
            parser.separator 'Usage: note event <eventId>'
            parser.separator ''
            parser.separator 'Where <eventId> is the ID of the event to create a note for'
          end
        end

        def can_run?
          is_entity_present?(Entities::Event) && is_entity_manager_available?(Entities::Event)
        end

        def run
          @event = @context.load_entity(Entities::Event)
          super
        end

        def create_title
          @event.title
        end

        def create_tags
          ## TODO: make the contact tags configurable.
          focus = @context.focus[:name]
          tags = @event.people.map { |p| "#{focus}/Contacts/#{p}" }
          super + tags
        end
      end

      def self.register(plugin)
        plugin.for_entity(Entities::Note)
        plugin.add_command(Plain, :single)
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

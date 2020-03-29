class String
  def url_encode
    ERB::Util.url_encode(self)
  end
end

module VPS
  module Plugins
    module Bear
      def self.configure_plugin(plugin)
        plugin.configurator_class = Configurator
        plugin.for_entity(Entities::Note)
        plugin.add_command(Find, :single)
        plugin.add_command(Plain, :single)
        plugin.add_command(Project, :single)
        plugin.add_command(Contact, :single)
        plugin.add_command(Event, :single)
        plugin.add_collaboration(Entities::Project)
        plugin.add_collaboration(Entities::Contact)
        plugin.add_collaboration(Entities::Event)
      end

      class Configurator < PluginSupport::Configurator
        def read_area_configuration(area, hash)
          config = {
            templates: {}
          }
          %w(default plain contact event project).each do |set|
            templates = if hash['templates'] && hash['templates'][set] then hash['templates'][set] else {} end
            config[:templates][set.to_sym] = {
              title: templates['title'] || nil,
              text: templates['text'] || nil,
              tags: templates['tags'] || nil
            }
          end
          config[:templates][:default][:title] ||= '{{input}}'
          config[:templates][:default][:text] ||= ''
          config[:templates][:default][:tags] ||= []
          config
        end
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
          [
            {
              title: 'Create a note in Bear',
              arg: "note contact #{entity.id}",
              icon: {
                path: "icons/bear.png"
              }
            },
            {
              title: 'Find all notes',
              arg: "note find \"#{entity.name}\" -\"Bila #{entity.name}\"",
              icon: {
                path: "icons/bear.png"
              }
            },
            {
              title: 'Find all 1-on-1 meeting notes',
              arg: "note find \"Bila #{entity.name}\"",
              icon: {
                path: "icons/bear.png"
              }
            }
          ]
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

      class Find
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Find all notes matching the search criteria'
            parser.separator 'Usage: note find [criteria]'
          end
        end

        def run(runner = Shell::SystemRunner.new)
          criteria = ERB::Util.url_encode(@context.arguments.join(' '))
          url = "bear://x-callback-url/search?term=#{criteria}"
          runner.execute("open", url)
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

        def initialize(context)
          super(context)
          @template_set = template_set
        end

        def template_set
          :plain
        end

        def run(runner = Shell::SystemRunner.new)
          context = create_context
          title = merge_template(template(:title), context).url_encode
          text = merge_template(template(:text), context).url_encode
          tags = template(:tags)
                   .map { |t| merge_template(t, context) }
                   .map { |t| t.url_encode }
                   .join(',')
          callback = "bear://x-callback-url/create?title=#{title}&text=#{text}&tags=#{tags}"
          runner.execute('open', callback)
          "Created a new note in Bear with title '#{context[:title]}'"
        end

        def create_context
          query = @context.arguments.join(' ')
          date = DateTime.now
          {
            'year' => date.strftime('%Y'),
            'month' => date.strftime('%m'),
            'week' => date.strftime('%V'),
            'day' => date.strftime('%d'),
            'query' => query,
            'input' => query
          }
        end

        def template(sym)
          templates = @context.focus['bear'][:templates]
          templates[template_set][sym] || templates[:default][sym]
        end

        def merge_template(template, context)
          Liquid::Template.parse(template).render(context)
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

        def template_set
          :project
        end

        def can_run?
          is_entity_present?(Entities::Project) && is_entity_manager_available?(Entities::Project)
        end

        def run
          @project = @context.load_entity(Entities::Project)
          super
        end

        def create_context
          context = super
          context['input'] = @project.name
          context['name'] = @project.name
          context
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

        def template_set
          :contact
        end

        def can_run?
          is_entity_present?(Entities::Contact) && is_entity_manager_available?(Entities::Contact)
        end

        def run
          @contact = @context.load_entity(Entities::Contact)
          super
        end

        def create_context
          context = super
          context['input'] = @contact.name
          context['name'] = @contact.name
          context
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

        def template_set
          :contact
        end

        def can_run?
          is_entity_present?(Entities::Event) && is_entity_manager_available?(Entities::Event)
        end

        def run
          @event = @context.load_entity(Entities::Event)
          super
        end

        def create_context
          context = super
          context['input'] = @event.title
          context['title'] = @event.title
          context['names'] = @event.people
          context
        end
      end
    end
  end
end

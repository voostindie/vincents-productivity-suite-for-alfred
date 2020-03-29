class String
  def url_encode
    ERB::Util.url_encode(self)
  end

  def render_template(context)
    Liquid::Template.parse(self).render(context)
  end
end

module VPS
  module Plugins
    module Bear
      def self.configure_plugin(plugin)
        plugin.configurator_class = Configurator
        plugin.for_entity(Entities::Note)
        plugin.add_command(Finders, :list)
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
            finders: {},
            creators: {}
          }
          if hash['finders']
            hash['finders'].each_pair do |name, finder|
              config[:finders][name] = {
                description: finder['description'] || "No description available",
                scope: (finder['scope'] || ['global']).filter { |s| %w(global contact event project).include?(s) }.map { |s| s.to_sym },
                term: finder['term'] || '{{input}}',
                tags: finder['tags'] || ''
              }
            end
          end
          %w(default plain contact event project).each do |set|
            creators = if hash['creators'] && hash['creators'][set] then
                          hash['creators'][set]
                        else
                          {}
                        end
            config[:creators][set.to_sym] = {
              title: creators['title'] || nil,
              text: creators['text'] || nil,
              tags: creators['tags'] || nil
            }
          end
          config[:creators][:default][:title] ||= '{{input}}'
          config[:creators][:default][:text] ||= ''
          config[:creators][:default][:tags] ||= []
          config
        end
      end

      def self.commands_for(area, entity)
        if entity.is_a?(Entities::Project)
          [
            {
              title: 'Create a note in Bear',
              arg: "note project #{entity.id}",
              icon: {
                path: "icons/bear.png"
              }
            },
            *self.add_finders(area, entity.name, :project)
          ]
        elsif entity.is_a?(Entities::Contact)
          [
            {
              title: 'Create a note in Bear',
              arg: "note contact #{entity.id}",
              icon: {
                path: "icons/bear.png"
              }
            },
            *self.add_finders(area, entity.name, :contact)
          ]
        elsif entity.is_a?(Entities::Event)
          [{
             title: 'Create a note in Bear',
             arg: "note event #{entity.id}",
             icon: {
               path: "icons/bear.png"
             }
           },
           *self.add_finders(area, entity.name, :event)
          ]
        else
          raise "Unsupported entity class for collaboration: #{entity.class}"
        end
      end

      def self.add_finders(area, query, type)
        finders = []
        area['bear'][:finders].each_pair do |name, finder|
          if finder[:scope].include?(type)
            finders << {
              title: finder[:description],
              arg: "note find #{name} #{query}",
              icon: {
                path: 'icons/bear.png'
              }
            }
          end
        end
        finders
      end

      class Finders
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available global finders'
          end
        end

        def run
          finders = []
          @context.focus['bear'][:finders].each_pair do |name, finder|
            if finder[:scope].include?(:global)
              finders << {
                uid: name,
                arg: name,
                title: finder[:description]
              }
            end
          end
          finders
        end
      end

      class Find
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Find all notes matching the search criteria'
            parser.separator 'Usage: note find <query> [criteria]'
            parser.separator ''
            parser.separator 'Where <query> is a reference to a finder in your configuration.'
          end
        end

        def run(runner = Shell::SystemRunner.new)
          arguments = @context.arguments
          finder = @context.focus['bear'][:finders][arguments.shift]
          unless finder
            puts "ERROR: finder doesn't exist!"
            return
          end
          context = {'input' => arguments.join(' ')}
          query = [finder[:term].render_template(context)]
          query << finder[:tags].map { |tag| '#' + tag.render_template(context) }
          term = query.flatten.compact.join(' ').url_encode
          url = "bear://x-callback-url/search?term=#{term}"
          puts url
          runner.execute("open", url)
          nil
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
          @creator_set = creator_set
        end

        def creator_set
          :plain
        end

        def run(runner = Shell::SystemRunner.new)
          context = create_context
          title = template(:title).render_template(context).url_encode
          text = template(:text).render_template(context).url_encode
          tags = template(:tags)
                   .map { |t| t.render_template(context) }
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
          templates = @context.focus['bear'][:creators]
          templates[creator_set][sym] || templates[:default][sym]
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

        def creator_set
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

        def creator_set
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

        def creator_set
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

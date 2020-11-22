module VPS
  # Support module for plugins that manage notes. The goal is to have feature
  # parity across all note plugins. Currently that's Obsidian, iA Writer and Bear.
  #
  # For some reason I switch between applications to keep my notes at a somewhat regular
  # basis, whereas I don't do that for other tools. (Every now and then I do try Things
  # instead of OmniFocus, but I'm still not won over.)
  #
  # Since I keep a lot of notes, being able to handle them through VPS is very important
  # to me. That explains the birth of this module, I guess.
  #
  # == Note templating
  #
  # This module adds templating supporting to notes, for all entity types.
  # Imagine creating a note with the minutes of a meeting at a press of a button, from
  # the event in the calendar itself, producing a note with all the title, date and
  # attendees all pre-filled!
  #
  # === Template sets
  #
  # This module supports 6 different template sets, and 4 templates per set. The sets are:
  #
  # 1. +default+: default settings for all templates
  # 2. +plain+: for plain text notes ("note create")
  # 3. +contact+: for notes on contacts ("contact note")
  # 4. +event+: for notes on events ("event note")
  # 5. +project+: for notes on projects ("project note")
  # 6. +today+: templates for "Today's note" ("note today")
  #
  # === Templates
  #
  # The 4 templates in each set are.
  #
  # 1. +filename+
  # 2. +title+
  # 3. +text+
  # 4. +tags+
  #
  # Each of these templates is handled as a Liquid template: https://shopify.github.io/liquid/.
  #
  # === Variables
  #
  # The set of variables available in each template depends on the entity (typicall they add
  # the properties of the entity), but the following set is always available:
  #
  # - +year+
  # - +month+
  # - +week+
  # - +day+
  # - +query+
  # - +input+
  #
  # == How to use
  #
  # All support classes are modules as to not interfere with the class hierarchy. In your
  # own plugin, first extend some base plugin class and then include the appropriate module.
  #
  # See the {VPS::Plugins::Obsidian}, {VPS::Plugins::Bear} and {VPS::Plugins::IAWriter} for examples.
  module NoteSupport

    module Configurator
      # Pulls template definitions from the input hash and stores them in the configuration hash
      # @param config [Hash<Symbol, Object>]
      # @param hash [Hash<String, Object>]
      # @return [Hash<Symbol, Object>]
      def process_templates(config, hash)
        config[:templates] = {}
        %w(default plain contact event project today).each do |set|
          templates = if hash['templates'] && hash['templates'][set]
                        hash['templates'][set]
                      else
                        {}
                      end
          config[:templates][set.to_sym] = {
            filename: force(templates['filename'], String) || nil,
            title: force(templates['title'], String) || nil,
            text: force(templates['text'], String) || nil,
            tags: force_array(templates['tags'], String) || nil
          }
        end
        config[:templates][:default][:filename] ||= nil
        config[:templates][:default][:title] ||= '{{input}}'
        config[:templates][:default][:text] ||= ''
        config[:templates][:default][:tags] ||= []
        config
      end
    end

    ##
    # Repository for notes in Markdown files.
    # This module requires a `:root` value in the plugin configuration, pointing to a directory on disk.
    module FileRepository
      def supported_entity_type
        EntityType::Note
      end

      def find_all(context)
        notes = Dir.glob("#{context.configuration[:root]}/**/*.md").sort_by { |p| File.basename(p) }
        notes.map do |path|
          EntityType::Note.new do |note|
            note.id = File.basename(path, '.md')
            note.title = note.id
            note.path = path
            note.is_new = false
          end
        end
      end

      def load_instance(context)
        id = context.arguments.join(' ')
        return nil if id.empty?
        matches = Dir.glob("#{context.configuration[:root]}/**/#{id}.md")
        if matches.empty?
          nil
        else
          EntityType::Note.new do |note|
            note.id = id
            note.title = id
            note.path = matches[0]
            note.is_new = false
          end
        end
      end

      def create_or_find(context, note)
        path = note.path.nil? ? note.id : note.path
        note.path = File.join(context.configuration[:root], path + '.md')
        note.is_new = false
        if !File.exist?(note.path) || File.size(note.path) == 0
          title = note.title
          text = note.text
          tags = note.tags.map { |t| "##{t}" }.join(' ')
          content = ''
          content += "# #{title}\n" unless title.empty?
          content += "\n#{text}" unless text.empty?
          content += "\n#{tags}" unless tags.empty?
          File.open(note.path, 'w') do |file|
            file.puts content
          end
          note.is_new = true
        end
        note
      end
    end

    module Root
      def supported_entity_type
        EntityType::Note
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'Return the root path on disk to the notes'
          parser.separator 'Usage: note root'
        end
      end

      def run(context)
        context.configuration[:root]
      end
    end

    # List all notes. Only include this if your repository supports the fina_all method.
    module List
      def supported_entity_type
        EntityType::Note
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all notes in this area'
          parser.separator 'Usage: note list'
        end
      end

      def run(context)
        context.find_all.map do |note|
          {
            uid: note.id,
            title: note.title,
            subtitle: if context.triggered_as_snippet?
                        "Paste '#{note.title}' in the frontmost application"
                      else
                        "Select an action for '#{note.title}'"
                      end,
            arg: note.title,
            autocomplete: note.title,
            variables: note.to_env
          }
        end
      end
    end

    module TemplateNote
      def application
        self.class.name.split('::')[2].downcase
      end

      def supported_entity_type
        EntityType::Note
      end

      def collaboration_entity_type
        EntityType::Note
      end

      def create_note(context)
        template_context = create_template_context(context)
        filename_template = template(context, :filename)
        note = EntityType::Note.new do |n|
          n.title = template(context, :title).render_template(template_context).strip
          n.path = filename_template.render_template(template_context).strip unless filename_template.nil?
          n.id = if n.path.nil?
                   n.title
                 else
                   File.basename(n.path)
                 end
          n.id = Zaru.sanitize!(n.id)
          n.text = template(context, :text).render_template(template_context)
          n.tags = template(context, :tags)
                     .map { |t| t.render_template(template_context).strip }
        end
        context.create_or_find(note, EntityType::Note)
      end

      def create_template_context(context)
        query = context.arguments.join(' ')
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

      def template(context, symbol)
        templates = context.configuration[:templates]
        templates[template_set][symbol] || templates[:default][symbol]
      end
    end

    module PlainTemplateNote
      include TemplateNote

      def template_set
        :plain
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'Create a new, empty note, optionally with a title'
          parser.separator 'Usage: note create [title]'
        end
      end
    end

    module TodayTemplateNote
      include TemplateNote

      def template_set
        :today
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'Create or open today\'s note'
          parser.separator 'Usage: note today'
        end
      end

      def create_template_context(context)
        yesterday = DateTime.now - 1
        tomorrow = DateTime.now + 1
        template_context = super
        template_context.merge!(
          {
            'yesterday_year' => yesterday.strftime('%Y'),
            'yesterday_month' => yesterday.strftime('%m'),
            'yesterday_week' => yesterday.strftime('%V'),
            'yesterday_day' => yesterday.strftime('%d'),
            'tomorrow_year' => tomorrow.strftime('%Y'),
            'tomorrow_month' => tomorrow.strftime('%m'),
            'tomorrow_week' => tomorrow.strftime('%V'),
            'tomorrow_day' => tomorrow.strftime('%d')
          })
        template_context
      end
    end

    module ProjectTemplateNote
      include TemplateNote

      def name
        'note'
      end

      def supported_entity_type
        EntityType::Project
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'Edit this project\'s note'
          parser.separator 'Usage: project note <projectId>'
          parser.separator ''
          parser.separator 'Where <projectId> is the ID of the project to create a note for'
        end
      end

      def template_set
        :project
      end

      def create_template_context(context)
        project = context.load_instance
        template_context = super
        template_context['input'] = project.name
        template_context['name'] = project.name
        template_context
      end

      def template(context, symbol)
        project = context.load_instance
        custom_config = project.config[application] || {}
        custom_config[symbol.to_s] || super(context, symbol)
      end
    end

    module ContactTemplateNote
      include TemplateNote

      def name
        'note'
      end

      def supported_entity_type
        EntityType::Contact
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'Edit this contact\'s note'
          parser.separator 'Usage: contact note <contactID>'
          parser.separator ''
          parser.separator 'Where <contactID> is the ID of the project to create a note for'
        end
      end

      def template_set
        :contact
      end

      def create_template_context(context)
        contact = context.load_instance
        template_context = super
        template_context['input'] = contact.name
        template_context['name'] = contact.name
        template_context
      end
    end

    module EventTemplateNote
      include TemplateNote

      def name
        'note'
      end

      def supported_entity_type
        EntityType::Event
      end

      def collaboration_entity_type
        EntityType::Note
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'Edit this event\'s note'
          parser.separator 'Usage: event note <eventID>'
          parser.separator ''
          parser.separator 'Where <eventID> is the ID of the event to create a note for'
        end
      end

      def template_set
        :event
      end

      def create_template_context(context)
        event = context.load_instance
        template_context = super
        template_context['input'] = event.title
        template_context['title'] = event.title
        template_context['names'] = event.people
        template_context
      end
    end
  end
end
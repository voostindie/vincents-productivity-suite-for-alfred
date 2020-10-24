module VPS
  ##
  # Support module for plugins that manage notes. The goal is to have feature
  # parity across all note plugins. Currently that's Obsidian, iA Writer and Bear.
  #
  # All support classes are modules. In your own plugin, first extend some base plugin class
  # and then include the appropriate module.
  module NoteSupport
    module Configurator
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
        EntityTypes::Note
      end

      def find_all(context)
        notes = Dir.glob("#{context.configuration[:root]}/**/*.md").sort_by { |p| File.basename(p) }
        notes.map do |path|
          EntityTypes::Note.new do |note|
            note.id = File.basename(path, '.md')
            note.title = note.id
            note.path = path
            note.is_new = false
          end
        end
      end

      def load(context)
        id = context.arguments.join(' ')
        return nil if id.empty?
        matches = Dir.glob("#{context.configuration[:root]}/**/#{id}.md")
        if matches.empty?
          nil
        else
          EntityTypes::Note.new do |note|
            note.id = id
            note.title = id
            note.path = matches[0]
            note.is_new = false
          end
        end
      end

      def create_or_find(context, note)
        note.path = File.join(context.configuration[:root], note.id + '.md')
        note.is_new = false
        unless File.exist?(note.path)
          title = note.title
          text = note.text
          tags = note.tags.map { |t| "##{t}" }.join(' ')
          content = ''
          content += "# #{title}\n\n" unless title.empty?
          content += "#{text}" unless content.empty?
          content += "#{tags}" unless tags.empty?
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
        EntityTypes::Note
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

    ##
    # List all notes. Only include this if your repository supports the fina_all method.
    module List
      def supported_entity_type
        EntityTypes::Note
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
            title: note.id,
            subtitle: if context.triggered_as_snippet?
                        "Paste '#{note.id}' in the frontmost application"
                      else
                        "Select an action for '#{note.id}'"
                      end,
            arg: if context.triggered_as_snippet?
                   "[[#{note.id}]]"
                 else
                   "#{note.id}"
                 end,
            autocomplete: note.id,
          }
        end
      end
    end

    module TemplateNote
      def application
        self.class.name.split('::')[2].downcase
      end

      def supported_entity_type
        EntityTypes::Note
      end

      def collaboration_entity_type
        EntityTypes::Note
      end

      def create_note(context)
        template_context = create_template_context(context)
        filename_template = template(context, :filename)
        note = EntityTypes::Note.new do |n|
          n.title = template(context, :title).render_template(template_context).strip
          n.id = if filename_template.nil?
                   n.title
                 else
                   filename_template.render_template(template_context).strip
                 end
          n.id = Zaru.sanitize!(n.id)
          n.text = template(context, :text).render_template(template_context)
          n.tags = template(context, :tags)
                     .map { |t| t.render_template(template_context).strip }
        end
        context.create_or_find(note, EntityTypes::Note)
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
    end

    module ProjectTemplateNote
      include TemplateNote

      def name
        'note'
      end

      def supported_entity_type
        EntityTypes::Project
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
        project = context.load
        template_context = super
        template_context['input'] = project.name
        template_context['name'] = project.name
        template_context
      end

      def template(context, symbol)
        project = context.load
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
        EntityTypes::Contact
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
        contact = context.load
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
        EntityTypes::Event
      end

      def collaboration_entity_type
        EntityTypes::Note
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
        event = context.load
        template_context = super
        template_context['input'] = event.title
        template_context['title'] = event.title
        template_context['names'] = event.people
        template_context
      end
    end
  end
end
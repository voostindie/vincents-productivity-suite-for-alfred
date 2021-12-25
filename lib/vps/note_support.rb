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
    # Configurator for note plugins to extract template configurations.
    module Configurator
      # Pulls template definitions from the input hash and stores them in the configuration hash
      # @param config [Hash<Symbol, Object>]
      # @param hash [Hash<String, Object>]
      # @return [Hash<Symbol, Object>]
      def process_templates(config, hash)
        config[:templates] = {}
        %w[default plain contact event project today].each do |set|
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

      # @return [Boolean] whether the file should include frontmatter or not. If yes, any tags will be written
      # in the frontmatter; if not, tags will be added at the bottom of the file, prepended with '#'.
      def frontmatter?(_context)
        false
      end

      def update_index(root)
        index = {}
        Dir.chdir(root) do
          Dir.glob('**/*.md') do |path|
            page = Page.new(root, path)
            [page.name, page.front_matter['aliases']].compact.flatten.each do |name|
              index[name] ||= []
              index[name] << page.relative_path
            end
          end
        end
        IO.write(File.join(root, 'index.json'), index.to_json)
      end

      def find_all(context)
        root = context.configuration[:root]
        index = load_index(root)
        if index.nil?
          Dir.chdir(root) do
            notes = Dir.glob('**/*.md').sort_by { |p| File.basename(p) }
            notes.map do |path|
              EntityType::Note.new do |note|
                note.id = File.basename(path, '.md')
                note.title = note.id
                note.path = path
                note.is_new = false
              end
            end
          end
        else
          index.map do |page, paths|
            paths.map do |path|
              is_unique = paths.size == 1
              EntityType::Note.new do |note|
                note.id = page
                note.title = page
                note.path = path
                note.is_new = false
                note.is_unique = is_unique
              end
            end
          end.flatten
        end
      end

      def load_index(root)
        path = File.join(root, 'index.json')
        return nil unless File.exist?(path)
        File.open(path) do | file |
          return JSON.load(file)
        end
      end

      def load_instance(context)
        note = EntityType::Note.from_env(context.environment)
        return note unless note.path.nil?

        id = context.arguments.join(' ')
        return nil if id.empty?
        root = context.configuration[:root]
        index = load_index(root)
        if index.nil?
          Dir.chdir(root) do
            matches = Dir.glob("**/#{id}.md")
            if matches.empty?
              nil
            else
              EntityType::Note.new do |note|
                note.id = id
                note.title = id
                note.path = matches[0]
                note.is_new = false
                note.is_unique = matches.size == 1
              end
            end
          end
        else
          paths = index[id]
          if paths.nil?
            nil
          else
            # This is not right: the first path is always selected, even when there are
            # multiple hits. In very rare cases it may open the wrong file.
            # I haven't thought of an elegant way to solve it yet.
            # In practice this only happens when using the CLI.
            # The Alfred workflow works fine, because it hands over more data between CLI invocations.
            EntityType::Note.new do |note|
              note.id = id
              note.title = id
              note.path = paths[0]
              note.is_new = false
              note.is_unique = paths.size == 1
            end
          end
        end
      end

      def create_or_find(context, note)
        path = note.path.nil? ? note.id : note.path
        path = "#{path}.md" unless path.end_with?('.md')
        note.path = path
        filename = File.join(context.configuration[:root], note.path)
        note.is_new = false
        if !File.exist?(filename) || File.size(filename).zero?
          title = note.title
          text = note.text
          content = ''
          if frontmatter?(context)
            tags = note.tags.join(', ')
            content += "---\ntags: [#{tags}]\n---\n" unless tags.empty?
            content += "# #{title}\n\n" unless title.empty?
            content += "#{text}\n" unless text.empty?
          else
            tags = note.tags.map { |t| "##{t}" }.join(' ')
            content += "# #{title}\n\n" unless title.empty?
            content += "#{text}\n" unless text.empty?
            content += "\n#{tags}\n" unless tags.empty?
          end
          File.open(filename, 'w') do |file|
            file.puts content
          end
          note.is_new = true
        end
        note
      end

      class Page
        attr_reader :name, :relative_path, :front_matter, :text

        def initialize(root, relative_path)
          @name = File.basename(relative_path, '.md')
          @relative_path = relative_path
          path = File.join(root, relative_path)
          @front_matter = {}
          lines = IO.readlines(path)
          @front_matter_present = !lines.empty? && lines[0].start_with?('---')
          if @front_matter_present
            lines.shift
            i = lines.find_index { |l| l.start_with?('---') } - 1
            yaml = lines[0..i].join
            @front_matter = YAML.load(yaml, path)
            lines = lines.drop(i + 2)
          end
          @text = lines.join.strip
        end
      end
    end

    # Return the root on disk of the notes
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

    # Creates an index of notes and stores them on disk in JSON format. Only include this
    # if your repository has Markdown files on disk.
    module Index
      def supported_entity_type
        EntityType::Note
      end

      def option_parser
        OptionParser.new do |parser|
          parser.banner = 'Create the index of all notes in this area'
          parser.separator 'Usage: note index'
          parser.separator ''
          parser.separator 'This command creates an index and stores it in a JSON file in the'
          parser.separator 'root of the notes directory. Other commands, like `list` and `open`'
          parser.separator 'use the index if it exists. They can also do without, but the index'
          parser.separator 'provides better performance and additional functionality:'
          parser.separator ''
          parser.separator 'With the index, notes can also be found using their aliases.'
          parser.separator ''
          parser.separator 'Tip: schedule this command every day or so for each of your areas!'
        end
      end

      def run(context)
        repository = context.resolve_repository(EntityType::Note.entity_type_name)
        repository.update_index(context.configuration[:root])
        nil
      end
    end

    # List all notes. Only include this if your repository supports the find_all method.
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

    # Base module for templated notes
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
          n.tags = template(context, :tags).map { |t| t.render_template(template_context).strip }
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

    # Base module for "plain" notes.
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

    # Base module for "today" notes.
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
          }
        )
        template_context
      end
    end

    # Base module for "project" notes.
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
        template_context['id'] = project.id
        template_context['url'] = project.url
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

    # Base module for "contact" notes.
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

    # Base module for "event" notes.
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

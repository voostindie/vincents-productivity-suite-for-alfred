module VPS
  module Plugins
    module Obsidian
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          config = {
            root: File.join(area[:root], force_string(hash['path']) || 'Notes'),
            vault: force_string(hash['vault']) || area[:name],
            templates: {}
          }
          %w(default plain contact event project today).each do |set|
            templates = if hash['templates'] && hash['templates'][set]
                          hash['templates'][set]
                        else
                          {}
                        end
            config[:templates][set.to_sym] = {
              filename: force_string(templates['filename']) || nil,
              title: force_string(templates['title']) || nil,
              text: force_string(templates['text']) || nil,
              tags: force_string_array(templates['tags']) || nil
            }
          end
          config[:templates][:default][:filename] ||= nil
          config[:templates][:default][:title] ||= '{{input}}'
          config[:templates][:default][:text] ||= ''
          config[:templates][:default][:tags] ||= []
          config
        end
      end

      class NoteRepository < BaseRepository
        def supported_entity_type
          EntityTypes::Note
        end

        def find_all(context)
          root = context.configuration[:root]
          notes = Dir.glob("#{root}/**/*.md").sort_by { |p| File.basename(p) }
          notes.map do |path|
            EntityTypes::Note.new do |note|
              note.id = File.basename(path, '.md')
              note.path = path
            end
          end
        end

        def load(context)
          id = context.arguments.join(' ')
          return nil if id.empty?
          root = context.configuration[:root]
          matches = Dir.glob("#{root}/**/#{id}.md")
          if matches.empty?
            nil
          else
            EntityTypes::Note.new do |note|
              note.id = id
              note.path = matches[0]
            end
          end
        end

        def create_or_find(context, note)
          note.path = File.join(context.configuration[:root], note.id + '.md')
          unless File.exist?(note.path)
            File.open(note.path, 'w') do |file|
              file.puts note.text
            end
          end
          note
        end
      end

      class Root < EntityTypeCommand
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

      class List < EntityTypeCommand
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

      class Open < EntityInstanceCommand
        def supported_entity_type
          EntityTypes::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Opens the specified note in Obsidian for editing'
            parser.separator 'Usage: note edit <noteId>'
            parser.separator ''
            parser.separator 'Where <noteID> is the ID of the note to edit'
          end
        end

        def run(context, runner = Shell::SystemRunner.new)
          note = context.load
          vault = context.configuration[:vault]
          file = note.path[context.configuration[:root].size..]
          callback = "obsidian://open?vault=#{vault.url_encode}&file=#{file.url_encode}"
          runner.execute('open', callback)
          nil
        end
      end

      class Create < EntityTypeCommand
        def supported_entity_type
          EntityTypes::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create a new, empty note, optionally with a title'
            parser.separator 'Usage: note create [title]'
          end
        end

        def template_set
          :plain
        end

        def run(context, shell_runner = Shell::SystemRunner.new, jxa_runner = Jxa::Runner.new('obsidian'))
          template_context = create_template_context(context)
          title = template(context, :title).render_template(template_context).strip
          filename_template = template(context, :filename)
          filename = if filename_template.nil?
                       title
                     else
                       filename_template.render_template(template_context).strip
                     end
          content = template(context, :text).render_template(template_context)
          tags = template(context, :tags)
                   .map { |t| t.render_template(template_context).strip }
                   .map { |t| "##{t}" }
                   .join(' ')
          text = ''
          text += "# #{title}\n\n" unless title.empty?
          text += "#{content}" unless content.empty?
          text += "#{tags}" unless tags.empty?

          filename = Zaru.sanitize!(filename)
          note = EntityTypes::Note.new do |n|
            n.id = filename
            n.text = text
          end
          note = context.create_or_find(note)
          # Focus on Obsidian and give it some time, so that it can find the new file
          jxa_runner.execute('activate')
          sleep(0.5)
          # Now open the file
          vault = context.configuration[:vault]
          file = note.path[context.configuration[:root].size..]
          callback = "obsidian://open?vault=#{vault.url_encode}&file=#{file.url_encode}"
          shell_runner.execute('open', callback)
          nil # No output here, as Obsidian has its own notification
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

      class Project < CollaborationCommand
        def name
          'note'
        end

        def supported_entity_type
          EntityTypes::Project
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create a new note for a project'
            parser.separator 'Usage: project note <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to create a note for'
          end
        end
      end

      #
      # def self.commands_for(area, entity)
      #   if entity.is_a?(Types::Project)
      #     {
      #       title: 'Create a note in Obsidian',
      #       arg: "note project #{entity.id}",
      #       icon: {
      #         path: "icons/obsidian.png"
      #       }
      #     }
      #   elsif entity.is_a?(Types::Contact)
      #     {
      #       title: 'Create a note in Obsidian',
      #       arg: "note contact #{entity.id}",
      #       icon: {
      #         path: "icons/obsidian.png"
      #       }
      #     }
      #   elsif entity.is_a?(Types::Event)
      #     {
      #       title: 'Create a note in Obsidian',
      #       arg: "note event #{entity.id}",
      #       icon: {
      #         path: "icons/obsidian.png"
      #       }
      #     }
      #   else
      #     raise "Unsupported entity class for collaboration: #{entity.class}"
      #   end
      # end
      #
      #
      # class Commands < NoteCommand
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'List all available commands for the specified note'
      #       parser.separator 'Usage: note commands <noteId>'
      #       parser.separator ''
      #       parser.separator 'Where <noteID> is the ID of the note to act upon'
      #     end
      #   end
      #
      #   def run
      #     note = Obsidian::load_entity(@context)
      #     commands = []
      #     commands << {
      #       title: 'Open in Obsidian',
      #       arg: "note edit #{note.id}",
      #       icon: {
      #         path: "icons/obsidian.png"
      #       }
      #     }
      #     commands << {
      #       title: 'Open in Marked 2',
      #       arg: "note view #{note.id}",
      #       icon: {
      #         path: "icons/marked.png"
      #       }
      #     }
      #     commands += @context.collaborator_commands(note)
      #   end
      # end
      #
      #
      #
      # class Project < Plain
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'Create a new note for a project'
      #       parser.separator 'Usage: note project <projectId>'
      #       parser.separator ''
      #       parser.separator 'Where <projectId> is the ID of the project to create a note for'
      #     end
      #   end
      #
      #   def template_set
      #     :project
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Project) && is_entity_manager_available?(Types::Project)
      #   end
      #
      #   def run
      #     @project = @context.load_entity(Types::Project)
      #     @custom_config = @project.config['obsidian'] || {}
      #     super
      #   end
      #
      #   def template(sym)
      #     @custom_config[sym.to_s] || super(sym)
      #   end
      #
      #   def create_context
      #     context = super
      #     context['input'] = @project.name
      #     context['name'] = @project.name
      #     context
      #   end
      # end
      #
      # class Contact < Plain
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'Create a new note for a contact'
      #       parser.separator 'Usage: note contact <contactId>'
      #       parser.separator ''
      #       parser.separator 'Where <contactId> is the ID of the contact to create a note for'
      #     end
      #   end
      #
      #   def template_set
      #     :contact
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Contact) && is_entity_manager_available?(Types::Contact)
      #   end
      #
      #   def run
      #     @contact = @context.load_entity(Types::Contact)
      #     super
      #   end
      #
      #   def create_context
      #     context = super
      #     context['input'] = @contact.name
      #     context['name'] = @contact.name
      #     context
      #   end
      # end
      #
      # class Event < Plain
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'Create a new note for an event'
      #       parser.separator 'Usage: note event <eventId>'
      #       parser.separator ''
      #       parser.separator 'Where <eventId> is the ID of the event to create a note for'
      #     end
      #   end
      #
      #   def template_set
      #     :event
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Event) && is_entity_manager_available?(Types::Event)
      #   end
      #
      #   def run
      #     @event = @context.load_entity(Types::Event)
      #     super
      #   end
      #
      #   def create_context
      #     context = super
      #     context['input'] = @event.title
      #     context['title'] = @event.title
      #     context['names'] = @event.people
      #     context
      #   end
      # end
      #
      # class Today < Plain
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'Create or open today\'s note'
      #       parser.separator 'Usage: note today'
      #     end
      #   end
      #
      #   def template_set
      #     :today
      #   end
      #
      #   def can_run?
      #     is_entity_manager_available?(Types::Event)
      #   end
      # end
    end
  end
end

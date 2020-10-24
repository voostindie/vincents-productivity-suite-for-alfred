module VPS
  module Plugins
    module Obsidian
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          config = {
            root: File.join(area[:root], force(hash['path'], String) || 'Notes'),
            vault: force(hash['vault'], String) || area[:name],
            templates: {}
          }
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

      module NoteTemplate
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
          note = context.create_or_find(note, EntityTypes::Note)
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

      class Create < EntityTypeCommand
        include NoteTemplate

        def supported_entity_type
          EntityTypes::Note
        end

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

      class Today < EntityTypeCommand
        include NoteTemplate

        def supported_entity_type
          EntityTypes::Note
        end

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

      class Project < CollaborationCommand
        include NoteTemplate

        def name
          'note'
        end

        def supported_entity_type
          EntityTypes::Project
        end

        def collaboration_entity_type
          EntityTypes::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create or edit a note for a project'
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
          custom_config = project.config['obsidian'] || {}
          custom_config[symbol.to_s] || super(context, symbol)
        end
      end

      class Contact < CollaborationCommand
        include NoteTemplate

        def name
          'note'
        end

        def supported_entity_type
          EntityTypes::Contact
        end

        def collaboration_entity_type
          EntityTypes::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Create or edit a note for a contact'
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

      class Event < CollaborationCommand
        include NoteTemplate

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
            parser.banner = 'Create or edit a note for an event'
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
end

module VPS
  module Plugins
    # Plugin for Obsidian, for keeping notes in plaintext files.
    module Obsidian
      include Plugin

      # Configures the Obsidian plugin.
      class ObsidianConfigurator < Configurator
        include NoteSupport::Configurator

        def process_area_configuration(area, hash)
          config = {
            root: File.realdirpath(File.join(area[:root], force(hash['path'], String) || 'Notes')),
            vault: force(hash['vault'], String) || area[:name],
            frontmatter: hash['frontmatter'] == true
          }
          process_templates(config, hash)
          config
        end
      end

      # Repository for notes managed by Obsidian.
      class ObsidianRepository < Repository
        include NoteSupport::FileRepository

        def frontmatter?(context)
          context.configuration[:frontmatter]
        end
      end

      # Command that returns the root of the notes on disk.
      class Root < EntityTypeCommand
        include NoteSupport::Root
      end

      # Command to index the notes
      class Index < EntityTypeCommand
        include NoteSupport::Index
      end

      # Command to list all notes.
      class List < EntityTypeCommand
        include NoteSupport::List
      end

      # Support module for commands on Obsidian notes.
      module ObsidianNote
        def supported_entity_type
          EntityType::Note
        end

        def run(context, shell_runner = Shell::SystemRunner.instance, jxa_runner = JxaRunner.new('obsidian'))
          note = if is_a?(VPS::Plugin::EntityInstanceCommand)
                   context.load_instance
                 else
                   create_note(context)
                 end
          if note.is_new
            # Focus on Obsidian and give it some time, so that it can find the new file
            jxa_runner.execute('activate')
            sleep(0.5)
          end
          vault = context.configuration[:vault]
          callback = "obsidian://open?vault=#{vault.url_encode}&file=#{note.path.url_encode}"
          shell_runner.execute('open', callback)
          nil # No output here, as Obsidian has its own notification
        end
      end

      # Command to open a note in Obsidian.
      class Open < EntityInstanceCommand
        include ObsidianNote

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in Obsidian'
            parser.separator 'Usage: note edit <noteId>'
            parser.separator ''
            parser.separator 'Where <noteID> is the ID of the note to edit'
          end
        end
      end

      # Command to create a "plain" note in Obsidian.
      class Create < EntityTypeCommand
        include ObsidianNote
        include NoteSupport::PlainTemplateNote
      end

      # Command to create a "today" note in Obsidian.
      class Today < EntityTypeCommand
        include ObsidianNote
        include NoteSupport::TodayTemplateNote
      end

      # Command to create a "project" note in Obsidian.
      class Project < CollaborationCommand
        include ObsidianNote
        include NoteSupport::ProjectTemplateNote
      end

      # Command to create a "contact" note in Obsidian.
      class Contact < CollaborationCommand
        include ObsidianNote
        include NoteSupport::ContactTemplateNote
      end

      # Command to create an "event" note in Obsidian.
      class Event < CollaborationCommand
        include ObsidianNote
        include NoteSupport::EventTemplateNote
      end

      # Support module for note search commands.
      module Search
        def name
          'notes'
        end

        def collaboration_entity_type
          EntityType::Note
        end

        def option_parser
          name = supported_entity_type.entity_type_name
          OptionParser.new do |parser|
            parser.banner = "Search notes for this #{name}"
            parser.separator "Usage: #{name} notes <#{name}Id>"
            parser.separator ''
            parser.separator "Where <#{name}Id> is the ID of the #{name} to search for"
          end
        end

        def run(context, shell_runner = Shell::SystemRunner.instance)
          entity = context.load_instance
          vault = context.configuration[:vault]
          query = "\"#{query_for(entity)}\""
          callback = "obsidian://search?vault=#{vault.url_encode}&query=#{query.url_encode}"
          shell_runner.execute('open', callback)
        end

        def query(entity)
          entity.id
        end
      end

      # Command to search for notes on a project.
      class SearchProjects < CollaborationCommand
        include Search

        def supported_entity_type
          EntityType::Project
        end

        def query_for(project)
          config = project.config['obsidian'] || {}
          config['query'] || config['title'] || config['filename'] || project.name
        end
      end

      # Command to search for notes on an event.
      class SearchEvents < CollaborationCommand
        include Search

        def supported_entity_type
          EntityType::Event
        end

        def query_for(event)
          event.title
        end
      end

      # Command to search for notes on a contact.
      class SearchContacts < CollaborationCommand
        include Search

        def supported_entity_type
          EntityType::Contact
        end

        def query_for(contact)
          contact.name
        end
      end
    end
  end
end

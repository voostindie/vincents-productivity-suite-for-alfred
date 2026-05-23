module VPS
  module Plugins
    # Plugin for BBEdit, for keeping notes in plaintext files.
    module BBEdit
      include Plugin

      # Configures the BBEdit plugin
      class BBEditConfigurator < Configurator
        include NoteSupport::Configurator

        def process_area_configuration(area, hash)
          config = {
            root: File.realdirpath(File.join(area[:root], hash['path'] || 'Notes')),
            frontmatter: hash['frontmatter'] == true
          }
          process_templates(config, hash)
          config
        end
      end

      # Repository for notes managed by BBEdit.
      class BBEditRepository < Repository
        include NoteSupport::FileRepository

        def frontmatter?(context)
          context.configuration[:frontmatter]
        end
      end

      # Command to return the root of the notes on disk.
      class Root < EntityTypeCommand
        include NoteSupport::Root
      end

      # Command to index the notes
      class Index < EntityTypeCommand
        include NoteSupport::Index
      end

      # Command to list notes.
      class List < EntityTypeCommand
        include NoteSupport::List
      end

      # Support module for notes managed in IA Writer.
      module BBEditNote
        def run(context, runner = Shell::SystemRunner.instance)
          note = if is_a?(VPS::Plugin::EntityInstanceCommand)
                   context.load_instance
                 else
                   note = create_note(context)
                   sleep 0.5
                   note
                 end
          runner.execute('bbedit', File.join(context.configuration[:root], note.path))
          "Opened note '#{note.path}' in BBEdit"
        end
      end

      # Command to open a note in BBEdit.
      class Open < EntityInstanceCommand
        include BBEditNote

        def supported_entity_type
          EntityType::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in BBEdit'
            parser.separator 'Usage: note edit <noteId>'
            parser.separator ''
            parser.separator 'Where <noteID> is the ID of the note to edit'
          end
        end
      end

      # Command to create a "plain" note in BBEdit.
      class Create < EntityTypeCommand
        include BBEditNote
        include NoteSupport::PlainTemplateNote
      end

      # Command to create a "today" note in BBEdit.
      class Today < EntityTypeCommand
        include BBEditNote
        include NoteSupport::TodayTemplateNote
      end

      # Command to create a "project" note in BBEdit.
      class Project < CollaborationCommand
        include BBEditNote
        include NoteSupport::ProjectTemplateNote
      end

      # Command to create a "contact" note in BBEdit.
      class Contact < CollaborationCommand
        include BBEditNote
        include NoteSupport::ContactTemplateNote
      end

      # Command to create an "event" note in IA Writer.
      class Event < CollaborationCommand
        include BBEditNote
        include NoteSupport::EventTemplateNote
      end
    end
  end
end

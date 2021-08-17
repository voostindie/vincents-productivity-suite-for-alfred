module VPS
  module Plugins
    # Plugin for IA Writer, for keeping notes in plaintext files.
    module IAWriter
      include Plugin

      # Configures the IA Writer plugin
      class IAWriterConfigurator < Configurator
        include NoteSupport::Configurator

        def process_area_configuration(area, hash)
          config = {
            location: hash['location'] || area[:name],
            root: File.realdirpath(File.join(area[:root], hash['path'] || 'Notes')),
            frontmatter: hash['frontmatter'] == true
          }
          process_templates(config, hash)
          config
        end
      end

      # Repository for notes managed by IA Writer.
      class IAWriterRepository < Repository
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
      module IAWriterNote
        def run(context, runner = Shell::SystemRunner.instance)
          note = if is_a?(VPS::Plugin::EntityInstanceCommand)
                   context.load_instance
                 else
                   create_note(context)
                 end
          location = File.join('/Locations', context.configuration[:location], note.path)
          callback = "iawriter://open?path=#{location.url_encode}"
          runner.execute('open', callback)
          "Opened note '#{note.title}' in iA Writer"
        end
      end

      # Command to open a note in IA Writer.
      class Open < EntityInstanceCommand
        include IAWriterNote

        def supported_entity_type
          EntityType::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in iA Writer'
            parser.separator 'Usage: note edit <noteId>'
            parser.separator ''
            parser.separator 'Where <noteID> is the ID of the note to edit'
          end
        end
      end

      # Command to create a "plain" note in IA Writer.
      class Create < EntityTypeCommand
        include IAWriterNote
        include NoteSupport::PlainTemplateNote
      end

      # Command to create a "today" note in IA Writer.
      class Today < EntityTypeCommand
        include IAWriterNote
        include NoteSupport::TodayTemplateNote
      end

      # Command to create a "project" note in IA Writer.
      class Project < CollaborationCommand
        include IAWriterNote
        include NoteSupport::ProjectTemplateNote
      end

      # Command to create a "contact" note in IA Writer.
      class Contact < CollaborationCommand
        include IAWriterNote
        include NoteSupport::ContactTemplateNote
      end

      # Command to create an "event" note in IA Writer.
      class Event < CollaborationCommand
        include IAWriterNote
        include NoteSupport::EventTemplateNote
      end
    end
  end
end

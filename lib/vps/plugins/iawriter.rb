module VPS
  module Plugins
    module IAWriter
      include Plugin

      class IAWriterConfigurator < Configurator
        include NoteSupport::Configurator

        def process_area_configuration(area, hash)
          config = {
            location: hash['location'] || area[:name],
            root: File.join(area[:root], hash['path'] || 'Notes'),
          }
          process_templates(config, hash)
          config
        end
      end

      class IAWriterRepository < Repository
        include NoteSupport::FileRepository
      end

      class Root < EntityTypeCommand
        include NoteSupport::Root
      end

      class List < EntityTypeCommand
        include NoteSupport::List
      end

      module IAWriterNote
        def run(context, runner = Shell::SystemRunner.new)
          note = if self.is_a?(VPS::Plugin::EntityInstanceCommand)
                   context.load_instance
                 else
                   create_note(context)
                 end
          filename = note.path[context.configuration[:root].size..]
          location = File.join('/Locations', context.configuration[:location], filename)
          callback = "iawriter://open?path=#{location.url_encode}"
          runner.execute('open', callback)
          "Opened note '#{note.title}' in iA Writer"
        end
      end

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

      class Create < EntityTypeCommand
        include NoteSupport::PlainTemplateNote, IAWriterNote
      end

      class Today < EntityTypeCommand
        include NoteSupport::TodayTemplateNote, IAWriterNote
      end

      class Project < CollaborationCommand
        include NoteSupport::ProjectTemplateNote, IAWriterNote
      end

      class Contact < CollaborationCommand
        include NoteSupport::ContactTemplateNote, IAWriterNote
      end

      class Event < CollaborationCommand
        include NoteSupport::EventTemplateNote, IAWriterNote
      end
    end
  end
end

module VPS
  module Plugins
    module IAWriter
      include Plugin

      class Configurator < BaseConfigurator
        include NoteSupport::Configurator

        def process_area_configuration(area, hash)
          config = {
            location: hash['location'] || area[:name],
            root: File.join(area[:root], hash['path'] || 'Notes'),
            token: hash['token'] || 'TOKEN_NOT_CONFIGURED',
          }
          process_templates(config, hash)
          config
        end
      end

      class NoteRepository < BaseRepository
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
                   context.load
                 else
                   create_note(context)
                 end
          filename = note.path[context.configuration[:root].size..]
          location = File.join('/Locations', context.configuration[:location], filename)
          callback = "iawriter://open?path=#{location.url_encode}"
          runner.execute('open', callback)
          "Opened the note with ID '#{note.id}' in iA Writer"
        end
      end

      class Open < EntityInstanceCommand
        include IAWriterNote

        def supported_entity_type
          EntityTypes::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in iA Writer'
            parser.separator 'Usage: note edit <noteId>'
            parser.separator ''
            parser.separator 'Where <noteID> is the ID of the note to edit'
          end
        end

        def run(context)
          note = context.load
          open_note(context, note)
        end

        def resolve_note(context)
          context.load
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

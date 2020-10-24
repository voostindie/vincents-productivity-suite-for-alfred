module VPS
  module Plugins
    module Obsidian
      include Plugin

      class Configurator < BaseConfigurator
        include NoteSupport::Configurator

        def process_area_configuration(area, hash)
          config = {
            root: File.join(area[:root], force(hash['path'], String) || 'Notes'),
            vault: force(hash['vault'], String) || area[:name]
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

      class Open < EntityInstanceCommand
        def supported_entity_type
          EntityTypes::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in Obsidian'
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

      module ObsidianNote
        def run(context, shell_runner = Shell::SystemRunner.new, jxa_runner = Jxa::Runner.new('obsidian'))
          note = create_note(context)
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
      end

      class Create < EntityTypeCommand
        include NoteSupport::PlainTemplateNote, ObsidianNote
      end

      class Today < EntityTypeCommand
        include NoteSupport::TodayTemplateNote, ObsidianNote
      end

      class Project < CollaborationCommand
        include NoteSupport::ProjectTemplateNote, ObsidianNote
      end

      class Contact < CollaborationCommand
        include NoteSupport::ContactTemplateNote, ObsidianNote
      end

      class Event < CollaborationCommand
        include NoteSupport::EventTemplateNote, ObsidianNote
      end
    end
  end
end

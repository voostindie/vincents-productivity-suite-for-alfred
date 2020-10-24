module VPS
  module Plugins
    module Bear
      include Plugin

      class Configurator < BaseConfigurator
        include NoteSupport::Configurator

        def process_area_configuration(area, hash)
          config = {
            tag: hash['tag'] || area[:name],
            token: hash['token'] || 'TOKEN_NOT_CONFIGURED'
          }
          process_templates(config, hash)
          config
        end
      end

      class BearRepository < BaseRepository
        def supported_entity_type
          EntityTypes::Note
        end

        def find_all(context, runner = Xcall.instance)
          tag = context.configuration[:tag]
          token = context.configuration[:token]
          callback = "bear://x-callback-url/search?show_window=no&token=#{token}"
          callback += "&tag=#{tag}" unless tag.nil?
          output = runner.execute(callback)
          if output.nil? || output.empty?
            return []
          end
          JSON.parse(output['notes']).map do |record|
            EntityTypes::Note.new do |note|
              note.id = record['identifier']
              note.title = record['title']
            end
          end
        end

        def load(context, runner = Xcall.instance)
          if context.environment['NOTE_ID'].nil?
            id = context.arguments[0]
            token = context.configuration[:token]
            callback = "bear://x-callback-url/open-note?id=#{id.url_encode}&show_window=no&token=#{token}"
            record = runner.execute(callback)
            EntityTypes::Note.new do |note|
              note.id = id
              note.title = record['title'] || nil
            end
          else
            EntityTypes::Note.from_env(context.environment)
          end
        end

        def create_or_find(context, note, runner = Xcall.instance)
          token = context.configuration[:token]
          title = note.title.url_encode
          text = note.text.url_encode
          tags = note.tags.map { |t| t.url_encode }.join(',')
          callback = "bear://x-callback-url/create?title=#{title}&text=#{text}&tags=#{tags}&token=#{token}"
          output = runner.execute(callback)
          note.id = output['identifier']
          note
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
              title: note.title,
              subtitle: if context.triggered_as_snippet?
                          "Paste '#{note.title}' in the frontmost application"
                        else
                          "Select an action for '#{note.title}'"
                        end,
              arg: if context.triggered_as_snippet?
                     "[[#{note.title}]]"
                   else
                     "#{note.title}"
                   end,
              autocomplete: note.title,
              variables: note.to_env
            }
          end
        end
      end

      module BearNote
        def supported_entity_type
          EntityTypes::Note
        end

        def run(context, runner = Xcall.instance)
          note = if self.is_a?(VPS::Plugin::EntityInstanceCommand)
                   context.load
                 else
                   create_note(context)
                 end
          token = context.configuration[:token]
          callback = "bear://x-callback-url/open-note?id=#{note.id.url_encode}&token=#{token}"
          runner.execute(callback)
          "Opened note '#{note.title}' in Bear"
        end
      end

      class Open < EntityInstanceCommand
        include BearNote

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in Bear'
            parser.separator 'Usage: note edit <noteId>'
            parser.separator ''
            parser.separator 'Where <noteID> is the ID of the note to edit'
          end
        end
      end

      class Create < EntityTypeCommand
        include NoteSupport::PlainTemplateNote, BearNote
      end

      class Today < EntityTypeCommand
        include NoteSupport::TodayTemplateNote, BearNote
      end

      class Project < CollaborationCommand
        include NoteSupport::ProjectTemplateNote, BearNote
      end

      class Contact < CollaborationCommand
        include NoteSupport::ContactTemplateNote, BearNote
      end

      class Event < CollaborationCommand
        include NoteSupport::EventTemplateNote, BearNote
      end
    end
  end
end

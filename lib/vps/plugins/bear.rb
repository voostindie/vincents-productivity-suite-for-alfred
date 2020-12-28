module VPS
  module Plugins
    # Plugin for the note-keeping app Bear.
    #
    # *Warning*: I'm not using Bear myself anymore, so I'm not guaranteeing this plugin is going
    # to work perfectly!
    module Bear
      include Plugin

      # Configures the Bear plugin
      class BearConfigurator < Configurator
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

      # Repository for Bear notes
      class BearRepository < Repository
        def supported_entity_type
          EntityType::Note
        end

        def find_all(context, runner = Xcall.instance)
          tag = context.configuration[:tag]
          token = context.configuration[:token]
          callback = "bear://x-callback-url/search?show_window=no&token=#{token}"
          callback += "&tag=#{tag}" unless tag.nil?
          output = runner.execute(callback)
          return [] if output.nil? || output.empty?

          JSON.parse(output['notes']).map do |record|
            EntityType::Note.new do |note|
              note.id = record['identifier']
              note.title = record['title']
            end
          end
        end

        def load_instance(context, runner = Xcall.instance)
          if context.environment['NOTE_ID'].nil?
            id = context.arguments[0]
            return nil if id.nil?

            token = context.configuration[:token]
            callback = "bear://x-callback-url/open-note?id=#{id.url_encode}&show_window=no&token=#{token}"
            record = runner.execute(callback)
            EntityType::Note.new do |note|
              note.id = id
              note.title = record['title'] || nil
            end
          else
            EntityType::Note.from_env(context.environment)
          end
        end

        def create_or_find(context, note, runner = Xcall.instance)
          token = context.configuration[:token]
          title = note.title.url_encode
          text = note.text.url_encode
          tags = note.tags.map(&:url_encode).join(',')
          callback = "bear://x-callback-url/create?title=#{title}&text=#{text}&tags=#{tags}&token=#{token}"
          output = runner.execute(callback)
          note.id = output['identifier']
          note
        end
      end

      # Command to list Bear notes
      class List < EntityTypeCommand
        include NoteSupport::List
      end

      # Base module for Bear commands
      module BearNote
        def supported_entity_type
          EntityType::Note
        end

        def run(context, runner = Xcall.instance)
          note = if is_a?(VPS::Plugin::EntityInstanceCommand)
                   context.load_instance
                 else
                   create_note(context)
                 end
          token = context.configuration[:token]
          callback = "bear://x-callback-url/open-note?id=#{note.id.url_encode}&token=#{token}"
          runner.execute(callback)
          "Opened note '#{note.title}' in Bear"
        end
      end

      # Command to open notes in Bear.
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

      # Command to create "plain" notes in Bear.
      class Create < EntityTypeCommand
        include BearNote
        include NoteSupport::PlainTemplateNote
      end

      # Command to create "today" notes in Bear.
      class Today < EntityTypeCommand
        include BearNote
        include NoteSupport::TodayTemplateNote
      end

      # Command to create "project" notes in Bear.
      class Project < CollaborationCommand
        include BearNote
        include NoteSupport::ProjectTemplateNote
      end

      # Command to create "contact" notes in Bear.
      class Contact < CollaborationCommand
        include BearNote
        include NoteSupport::ContactTemplateNote
      end

      # Command to create "event" notes in Bear.
      class Event < CollaborationCommand
        include BearNote
        include NoteSupport::EventTemplateNote
      end
    end
  end
end

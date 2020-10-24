module VPS
  module Plugins
    module Marked
      include Plugin

      class View < EntityInstanceCommand
        def supported_entity_type
          EntityType::Note
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in Marked'
            parser.separator 'Usage: note view <noteId>'
            parser.separator ''
            parser.separator 'Where <noteID> is the ID of the note to view'
          end
        end

        def run(context, runner = Shell::SystemRunner.new)
          note = context.load_instance
          callback = "x-marked://open?file=#{note.path.url_encode}"
          runner.execute('open', callback)
          "Opened note '#{note.id}' in Marked"
        end
      end
    end
  end
end

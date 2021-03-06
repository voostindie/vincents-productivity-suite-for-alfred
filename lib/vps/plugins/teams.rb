module VPS
  module Plugins
    # Plugin for Microsoft Teams that opens video conferences from the calendar
    # directly in Teams.
    #
    # Without the Calendar plugin, this plugin is pretty useless!
    module Teams
      include Plugin

      # Command to join a Teams meeting from an event.
      class Join < EntityInstanceCommand
        def supported_entity_type
          EntityType::Event
        end

        def enabled?(_context, event)
          (event.notes || '') =~ %r{<https://teams.microsoft.com/l/meetup-join.*>}
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Join Teams meeting'
            parser.separator 'Usage: event join <eventID>'
            parser.separator ''
            parser.separator 'Where <eventID> is the ID of the event to join'
          end
        end

        def run(context, runner = Shell::SystemRunner.instance)
          event = context.load_instance
          if (event.notes || '') =~ %r{<https:(//teams.microsoft.com/l/meetup-join.*)>}
            runner.execute('open', "msteams://#{Regexp.last_match(1)}")
            nil
          else
            'No Teams meeting found in event'
          end
        end
      end
    end
  end
end

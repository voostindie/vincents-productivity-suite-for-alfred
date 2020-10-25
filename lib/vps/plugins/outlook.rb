module VPS
  module Plugins
    # Support for Outlook Calendar.
    #
    # Note: this plugin is slooooooow, and also unmaintained. I'm not using it at the moment.
    module Outlook
      include Plugin

      class OutlookConfigurator < Configurator
        def process_area_configuration(area, hash)
          {
            account: force(hash['account'], String) || area[:name],
            calendar: force(hash['calendar'], String) || 'Calendar',
            me: force(hash['me'], String) || nil
          }
        end
      end

      class OutlookCalendarRepository < Repository
        def supported_entity_type
          EntityType::Event
        end

        def load_instance(context, runner = JxaRunner.new('outlook'))
          id = context.environment['EVENT_ID'] || context.arguments[0]
          return nil if id.nil?
          event = runner.execute('event-details', id)
          people = [Person.new(nil, event['organizer'])]
          event['attendees'].each do |attendee|
            people << Person.new(attendee['name'], attendee['address'])
          end
          me = context.configuration[:me]
          people.reject! { |p| p.email == me } unless me.nil?
          event['people'] = people.map { |p| p.name }
          event.delete('organizer')
          event.delete('attendees')
          EventTypes::Event.from_hash(event)
        end

        def find_all(context, runner = JxaRunner.new('outlook'))
          events = runner.execute('list-events',
                                  context.configuration[:account],
                                  context.configuration[:calendar])
          events.map { |event| Types::Event.from_hash(event) }
        end
      end

      class List < EntityTypeCommand
        def supported_entity_type
          EntityType::Event
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available events in this area for today'
            parser.separator 'Usage: event list'
          end
        end

        def run(context)
          context.find_all.map do |event|
            {
              uid: event.id,
              title: event.title,
              subtitle: if context.triggered_as_snippet?
                          "Paste '#{event.title}' in the frontmost application"
                        else
                          "Select an action for '#{event.title}'"
                        end,
              arg: event.title,
              autocomplete: event.title,
              variables: event.to_env
            }
          end
        end
      end

      class Person
        attr_reader :name, :email

        def initialize(name, address)
          @name = if name.nil?
                    if address.nil?
                      'UNKNOWN'
                    else
                      Person::name_from_email(address)
                    end
                  else
                    Person::format_name(name)
                  end
          @email = if address.nil?
                     'UNKNOWN'
                   else
                     address
                   end
        end

        def to_s
          "#{@name} <#{@email}>"
        end

        def self.name_from_email(email)
          email[0, email.index('@')].gsub('.', ' ')
        end

        def self.format_name(name)
          # <last name(s)> <middle name(s)>, <initials> (<first name(s)>)
          if name =~ /^(.+?), \w+ \((.+)\)$/
            first_name = Regexp.last_match(2)
            parts = Regexp.last_match(1).split(' ')
            middle_index = parts.index { |w| w[0] =~ /[a-z]/ }
            last_name = if middle_index.nil?
                          parts.join(' ')
                        else
                          (parts[middle_index..-1] + parts[0..middle_index - 1]).join(' ')
                        end
            "#{first_name} #{last_name}"
          else
            name
          end
        end
      end
    end
  end
end

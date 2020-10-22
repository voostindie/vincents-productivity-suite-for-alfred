module VPS
  module Plugins
    module OutlookCalendar
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          {
            account: hash['account'] || area[:name],
            calendar: hash['calendar'] || 'Calendar',
            me: hash['me'] || nil
          }
        end
      end

      #
      # class Repository < PluginSupport::Repository
      #   def self.entity_class
      #     Types::Event
      #   end
      #
      #   def load_from_context(context)
      #     id = context.environment['EVENT_ID'] || context.arguments[0]
      #     event = runner.execute('event-details', id)
      #
      #     people = [Person.new(nil, event['organizer'])]
      #     event['attendees'].each do |attendee|
      #       people << Person.new(attendee['name'], attendee['address'])
      #     end
      #     me = context.focus['outlookcalendar'][:me]
      #     people.reject! { |p| p.email == me } unless me.nil?
      #
      #     event['people'] = people.map {|p| p.name}
      #     event.delete('organizer')
      #     event.delete('attendees')
      #     Types::Event.from_hash(event)
      #   end
      # end
      #
      # def self.load_entity(context, runner = Jxa::Runner.new('outlook'))
      #   id = context.environment['EVENT_ID'] || context.arguments[0]
      #   event = runner.execute('event-details', id)
      #
      #   people = [Person.new(nil, event['organizer'])]
      #   event['attendees'].each do |attendee|
      #     people << Person.new(attendee['name'], attendee['address'])
      #   end
      #   me = context.focus['outlookcalendar'][:me]
      #   people.reject! { |p| p.email == me } unless me.nil?
      #
      #   event['people'] = people.map {|p| p.name}
      #   event.delete('organizer')
      #   event.delete('attendees')
      #   Types::Event.from_hash(event)
      # end
      #
      # class List
      #   include PluginSupport
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'List all available events in this area for today'
      #       parser.separator 'Usage: event list'
      #     end
      #   end
      #
      #   def run(runner = Jxa::Runner.new('outlook'))
      #     events = runner.execute('list-events',
      #                             @context.focus['outlookcalendar'][:account],
      #                             @context.focus['outlookcalendar'][:calendar])
      #     events.map do |event|
      #       event = Types::Event.from_hash(event)
      #       {
      #         uid: event.id,
      #         title: event.title,
      #         subtitle: if triggered_as_snippet?
      #                     "Paste '#{event.title}' in the frontmost application"
      #                   else
      #                     "Select an action for '#{event.title}'"
      #                   end,
      #         arg: event.title,
      #         autocomplete: event.title,
      #         variables: event.to_env
      #       }
      #     end
      #   end
      # end
      #
      # class Commands
      #   include PluginSupport
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'List all available commands for the specified event'
      #       parser.separator 'Usage: event commands <eventId>'
      #       parser.separator ''
      #       parser.separator 'Where <eventID> is the ID of the event to act upon'
      #     end
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Event)
      #   end
      #
      #   def run
      #     event = OutlookCalendar::load_entity(@context)
      #     @context.collaborator_commands(event)
      #   end
      # end
      #
      # class Person
      #   attr_reader :name, :email
      #
      #   def initialize(name, address)
      #     @name = if name.nil?
      #               if address.nil?
      #                 'UNKNOWN'
      #               else
      #                 Person::name_from_email(address)
      #               end
      #             else
      #               Person::format_name(name)
      #             end
      #     @email = if address.nil?
      #                'UNKNOWN'
      #              else
      #                address
      #              end
      #   end
      #
      #   def to_s
      #     "#{@name} <#{@email}>"
      #   end
      #
      #   def self.name_from_email(email)
      #     email[0, email.index('@')].gsub('.', ' ')
      #   end
      #
      #   def self.format_name(name)
      #     # <last name(s)> <middle name(s)>, <initials> (<first name(s)>)
      #     if name =~ /^(.+?), \w+ \((.+)\)$/
      #       first_name = Regexp.last_match(2)
      #       parts = Regexp.last_match(1).split(' ')
      #       middle_index = parts.index { |w| w[0] =~ /[a-z]/ }
      #       last_name = if middle_index.nil?
      #                     parts.join(' ')
      #                   else
      #                     (parts[middle_index..-1] + parts[0..middle_index - 1]).join(' ')
      #                   end
      #       "#{first_name} #{last_name}"
      #     else
      #       name
      #     end
      #   end
      # end
    end
  end
end

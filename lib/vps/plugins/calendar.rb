module VPS
  module Plugins
    # Plugin for Apple Calendar, to fetch events and their attendees.
    #
    # This module offers just 1 repository and 2 commands, but there's a lot of code to make it work.
    # The code dives directly in the underlying database from Calendar to fetch today's event.
    # It requires some tricky queries, and still it's not perfect: the database is a _cache_.
    # Sometimes events don't show up (yet).
    #
    # But in practice it works pretty reliable, even with a calendar synced from Microsoft Office 365.
    # Go figure.
    module Calendar
      include Plugin

      # Configures the Calendar plugin
      class CalendarConfigurator < Configurator
        def process_area_configuration(_area, hash)
          config = {
            name: force(hash['name'], String) || nil,
            me: force(hash['me'], String) || nil,
            replacements: {}
          }
          if hash['replacements'].is_a?(Hash)
            config[:replacements] = hash['replacements'].select { |k, v| k.is_a?(String) && v.is_a?(String) }
          end
          config
        end
      end

      # Repository for events in the Apple Calendar
      class CalendarRepository < Repository
        def supported_entity_type
          EntityType::Event
        end

        def find_all(context, date = Date.today)
          database = CalendarDatabase.new(context.configuration[:name])
          database.all_events_for(date).map do |record|
            EntityType::Event.new do |e|
              e.id = record.primary_key.to_s
              e.title = record.title
            end
          end
        end

        def load_instance(context)
          database = CalendarDatabase.new(context.configuration[:name])
          id = context.environment['EVENT_ID'] || context.arguments[0]
          return nil if id.nil?

          record = database.event_by_id(id)
          event = EntityType::Event.new do |e|
            e.id = record.primary_key.to_s
            e.title = record.title
            e.notes = record.notes
          end
          event.people = record.people
                               .map(&:name)
                               .reject { |n| n == context.configuration[:me] }
                               .map { |n| context.configuration[:replacements][n] || n }
                               .uniq
          event
        end
      end

      # Command to list today's events from the Calendar.
      class List < EntityTypeCommand
        def supported_entity_type
          EntityType::Event
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all events for today in this area'
            parser.separator 'Usage: event list'
          end
        end

        def run(context)
          context.find_all.map do |event|
            {
              uid: event.id,
              title: event.title,
              subtitle: "Select an action for '#{event.title}'",
              arg: event.title,
              autocomplete: event.title,
              variables: event.to_env
            }
          end
        end
      end

      # Access to the Apple Calendar is done through the SQLite cache.
      class CalendarDatabase
        # Dates in SQLite start on January 1st 2001 instead of the usual January 1st 1970.
        # So we need to compensate.
        TIME_DIFF = Time.new(2001, 1, 1) - Time.new(1970, 1, 1)

        def initialize(calendar_name)
          @calendar_name = calendar_name
          file = File.expand_path('~/Library/Calendars/Calendar Cache')
          unless File.exist? file
            puts "Calendar database not found: #{file}"
            exit(1)
          end
          @database = SQLite3::Database.new(file, readonly: true)
        end

        def single_events_for(date)
          start_date = (Time.mktime(date.year, date.month, date.day, 0, 0, 0) - TIME_DIFF).to_f
          end_date = (Time.mktime(date.year, date.month, date.day, 23, 59, 59) - TIME_DIFF).to_f
          query = <<-QUERY
            SELECT CI.Z_PK,
                   CI.ZLOCALUID,
                   CI.ZTITLE,
                   CI.ZSTARTDATE,
                   CI.ZENDDATE,
                   CI.ZISDETACHED,
                   CI.ZMYATTENDEESTATUS,
                   CI.ZORGANIZERCOMMONNAME,
                   CI.ZORGANIZERADDRESSSTRING
            FROM ZCALENDARITEM CI
            JOIN ZNODE CA ON CI.ZCALENDAR = CA.Z_PK
            WHERE CA.ZTITLE = '#{@calendar_name}'
            AND ZSTARTDATE >= #{start_date} AND ZSTARTDATE <= #{end_date}
            AND ZRECURRENCERULE IS NULL
            AND ZISALLDAY = 0
            ORDER BY ZSTARTDATE
          QUERY
          @database.execute(query).map { |row| SingleEvent.new(*row) }
        end

        def recurrent_events_for(date)
          start_date = (Time.mktime(date.year, date.month, date.day, 0, 0, 0) - CalendarDatabase::TIME_DIFF).to_f
          query = <<-QUERY
            SELECT CI.Z_PK,
                 CI.ZLOCALUID,
                 CI.ZTITLE,
                 CI.ZSTARTDATE,
                 CI.ZENDDATE,
                 CI.ZRECURRENCERULE,
                 CI.ZMYATTENDEESTATUS,
                 CI.ZORGANIZERCOMMONNAME,
                 CI.ZORGANIZERADDRESSSTRING
            FROM ZCALENDARITEM CI
            JOIN ZNODE CA ON CI.ZCALENDAR = CA.Z_PK
            WHERE CA.ZTITLE = '#{@calendar_name}'
            AND (ZRECURRENCEENDDATE IS NULL
                    OR ZRECURRENCEENDDATE >= #{start_date})
            AND ZRECURRENCERULE IS NOT NULL
            ORDER BY ZSTARTDATE
          QUERY
          @database.execute(query).map { |row| RecurringEvent.new(*row) }.filter { |e| e.active?(date) }
        end

        def all_events_for(date)
          recurring = recurrent_events_for(date)
          single = single_events_for(date)
          merge_events(recurring, single)
        end

        def merge_events(recurring_events, single_events)
          events = []
          recurring_events.each do |recurring_event|
            override = single_events.find { |e| e.public_id == recurring_event.public_id }
            if override.nil?
              events << recurring_event if recurring_event.attendee_status == :accepted
            elsif override.attendee_status == :accepted
              events << override
            end
          end
          events += single_events.reject(&:is_detached)
          events.sort_by!(&:start_time)
          events
        end

        def event_by_id(id)
          query = <<-QUERY
            SELECT CI.Z_PK,
                   CI.ZLOCALUID,
                   CI.ZTITLE,
                   CI.ZSTARTDATE,
                   CI.ZENDDATE,
                   CI.ZISDETACHED,
                   CI.ZMYATTENDEESTATUS,
                   CI.ZORGANIZERCOMMONNAME,
                   CI.ZORGANIZERADDRESSSTRING,
                   CI.ZNOTES
            FROM ZCALENDARITEM CI
            WHERE CI.Z_PK = ?
          QUERY
          event = @database.execute(query, id).map { |row| SingleEvent.new(*row) }.first
          enrich_event_with_attendees(event)
        end

        def self.to_date(int)
          Time.strptime(int.to_s, '%s') + CalendarDatabase::TIME_DIFF
        end

        def self.to_boolean(bool)
          bool == 1
        end

        private

        def enrich_event_with_attendees(event)
          query = <<-QUERY
            SELECT DISTINCT ZCOMMONNAME, ZADDRESSSTRING
            FROM ZATTENDEE
            WHERE ZEVENT = ?
          QUERY
          @database.execute(query, event.primary_key).map do |row|
            event.people << Person.new(*row)
          end
          event
        end
      end

      # Represents a single event from Apple Calendar.
      class Event
        attr_reader :primary_key, :public_id, :title, :start_date, :start_time, :end_date, :end_time,
                    :organizer, :attendee_status, :notes

        attr_accessor :people

        def initialize(primary_key, public_id, title, start_date, end_date,
                       organizer_name, organizer_address, attendee_status, notes = nil)
          @primary_key = primary_key
          @public_id = public_id
          @title = title
          @start_date = CalendarDatabase.to_date(start_date)
          @start_time = @start_date.strftime('%H:%M')
          @end_date = CalendarDatabase.to_date(end_date)
          @end_time = @end_date.strftime('%H:%M')
          @organizer = Person.new(organizer_name, organizer_address)
          @attendee_status = convert_attendee_status(attendee_status)
          @notes = notes
          @people = []
          @people << @organizer if @organizer.name != 'UNKNOWN'
        end

        private

        def convert_attendee_status(attendee_status)
          case attendee_status
          when 'ACCEPTED'
            :accepted
          when 'DECLINED'
            :declined
          when 'NEEDS_ACTION'
            :needs_action
          when 'TENTATIVE'
            :tentative
          else
            :empty
          end
        end
      end

      # Represents a single (non-recurring) event.
      class SingleEvent < Event
        attr_reader :is_detached

        # Constructs a single event from an SQLite row selection; all fields from database
        # must be passed as is!
        def initialize(primary_key, public_id, title, start_date, end_date,
                       is_detached, attendee_status, organizer_name, organizer_address, notes = nil)
          super(primary_key, public_id, title, start_date, end_date,
                organizer_name, organizer_address, attendee_status, notes)
          @is_detached = CalendarDatabase.to_boolean(is_detached)
        end
      end

      # Represents a recurring event.
      class RecurringEvent < Event
        # Constructs a recurring event from an SQLite row selection; all fields from database
        # must be passed as is!
        def initialize(primary_key, public_id, title, start_date, end_date,
                       recurrence_rule, attendee_status, organizer_name, organizer_address)
          super(primary_key, public_id, title, start_date, end_date,
                organizer_name, organizer_address, attendee_status)
          @schedule = IceCube::Schedule.from_ical "RRULE:#{recurrence_rule}"
          @schedule.start_time = @start_date
        end

        def active?(date)
          @schedule.occurs_on?(date)
        end
      end

      # Represents an event attendee.
      class Person
        attr_reader :name, :email

        def initialize(name, address)
          @name = if name.nil?
                    'UNKNOWN'
                  else
                    Person.format_name(name)
                  end
          @email = if address.nil?
                     'UNKNOWN'
                   else
                     address.gsub('mailto:', '')
                   end
        end

        def to_s
          "#{@name} <#{@email}>"
        end

        def self.format_name(name)
          # <last name(s)> <middle name(s)>, <initials> (<first name(s)>)
          if name =~ /^(.+?), \w+ \((.+)\)$/
            first_name = Regexp.last_match(2)
            parts = Regexp.last_match(1).split
            middle_index = parts.index { |w| w[0] =~ /[a-z]/ }
            last_name = if middle_index.nil?
                          parts.join(' ')
                        else
                          (parts[middle_index..] + parts[0..middle_index - 1]).join(' ')
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

module VPS
  module Calendar
    def self.read_area_configuration(area, hash)
      {
        name: hash['name'] || nil
      }
    end

    def self.load_entity
      if context.environment['EVENT_ID'].nil?
        raise 'Not yet implemented (for the CLI)!'
      else
        Entities::Event.from_env(context.environment)
      end
    end

    class List
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all events for today in this area'
          parser.separator 'Usage: event list'
        end
      end

      def run
        events_today.map do |record|
          event = Entities::Event.new do |e|
            e.id = record.primary_key.to_s
            e.title = record.title
          end
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

      def events_today
        database = CalendarDatabase.new(@context.focus['calendar'][:name])
        database.all_events_for(Date.today)
        # database.all_events_for(Date.new(2019,7,11))
      end
    end

    class Commands
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available commands for the event'
          parser.separator 'Usage: event commands <eventId>'
          parser.separator ''
          parser.separator 'Where <eventId> is the ID of the event to act upon'
        end
      end

      def can_run?
        is_plugin_enabled?(:calendar) && has_id?(:event)
      end

      def run
        event = Calendar::details_for(arguments, environment)
        commands = []
        # commands << {
        #   title: 'Open in Calendar',
        #   arg: "event open #{arguments[0]}",
        #   icon: {
        #     path: "icons/calendar.png"
        #   }
        # }
        commands << @context.collaborator_commands(:event, event)
        commands.flatten
      end
    end

    Registry.register(Calendar) do |plugin|
      plugin.for_entity(Entities::Event)
      plugin.add_command(List, :list)
      # plugin.add_command(Commands, :list) # Work in progress..
    end

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
        query = <<-EOS
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
        EOS
        @database.execute(query).map { |row| SingleEvent.new(*row) }
      end

      def recurrent_events_for(date)
        start_date = (Time.mktime(date.year, date.month, date.day, 0, 0, 0) - CalendarDatabase::TIME_DIFF).to_f
        query = <<-EOS
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
        EOS
        @database.execute(query).map { |row| RecurringEvent.new(*row) }.filter { |e| e.is_active(date) }
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
        events = events + single_events.reject { |e| e.is_detached }
        events.sort_by! { |e| e.start_time }
        enrich_events_with_attendees(events)
        events
      end


      def self.to_date(int)
        Time.strptime(int.to_s, '%s') + CalendarDatabase::TIME_DIFF
      end

      def self.to_boolean(bool)
        bool == 1
      end

      private

      def enrich_events_with_attendees(events)
        query = <<-EOS
      SELECT DISTINCT ZEVENT, ZCOMMONNAME, ZADDRESSSTRING
      FROM ZATTENDEE
      WHERE ZEVENT IN (#{events.map { |_| '?' }.join(', ')})
        EOS
        @database.execute(query, events.map { |e| e.primary_key }).map do |row|
          primary_key = row.shift
          event = events.find { |e| e.primary_key == primary_key }
          event.people << Person.new(*row)
        end
        events.each { |e| e.people.sort_by! { |p| p.name } }
      end

    end

    class Event
      attr_reader :primary_key, :public_id, :title, :start_date, :start_time, :end_date, :end_time,
                  :organizer, :attendee_status

      attr_accessor :people

      def initialize(primary_key, public_id, title, start_date, end_date,
                     organizer_name, organizer_address, attendee_status)
        @primary_key = primary_key
        @public_id = public_id
        @title = title
        @start_date = CalendarDatabase::to_date(start_date)
        @start_time = @start_date.strftime('%H:%M')
        @end_date = CalendarDatabase::to_date(end_date)
        @end_time = @end_date.strftime('%H:%M')
        @organizer = Person.new(organizer_name, organizer_address)
        @attendee_status = convert_attendee_status(attendee_status)
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

    class SingleEvent < Event

      attr_reader :is_detached

      # Constructs a single event from an SQLite row selection; all fields from database
      # must be passed as is!
      def initialize(primary_key, public_id, title, start_date, end_date,
                     is_detached, attendee_status, organizer_name, organizer_address)
        super(primary_key, public_id, title, start_date, end_date,
              organizer_name, organizer_address, attendee_status)
        @is_detached = CalendarDatabase::to_boolean(is_detached)
      end
    end

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

      def is_active(date)
        @schedule.occurs_on?(date)
      end
    end

    class Person
      attr_reader :name, :email

      def initialize(name, address)
        @name = if name.nil?
                  'UNKNOWN'
                else
                  Person::format_name(name)
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
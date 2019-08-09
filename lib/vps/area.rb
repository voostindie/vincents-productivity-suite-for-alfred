module VPS
  module Area
    class List
      def initialize(configuration, state)
        @configuration = configuration
        @state = state
      end

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available areas'
        end
      end

      def run(arguments, environment)
        focus = @state.focus[:key]
        @configuration.areas.map do |area|
          postfix = area[:key].eql?(focus) ? ' (focused)' : ''
          {
            uid: area[:key],
            arg: area[:key],
            title: area[:name] + postfix,
            autocomplete: area[:name]
          }
        end
      end
    end

    class Commands
      def initialize(configuration, state)
        @state = state
      end

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available commands for the focused area'
        end
      end

      def run(arguments, environment)
        result = []
        commands = Registry::commands
        @state.focus.each_pair do |key,value|
          next unless value.is_a? Hash
          if commands[key]
            commands[key][:commands].each_key do |command|
              result << {
                uid: "#{key} #{command}",
                title: commands[key][:commands][command][:class].option_parser.banner
              }
            end
          end
        end
        result
      end
    end

    class Focus
      def initialize(configuration, state)
        @configuration = configuration
        @state = state
      end

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Set the focus to the specified area'
          parser.separator 'Usage: area focus <area>'
          parser.separator ''
          parser.separator 'Where <area> is the key of the area to focus on.'
        end
      end

      def can_run?(arguments, environment)
        if arguments.size != 1
          $stderr.puts "Exactly one argument required: the name of the area to focus on"
          return false
        end
        area = @configuration.area(arguments[0])
        if area.nil?
          $stderr.puts "Unknown area: #{arguments[0]}"
          return false
        end
        true
      end

      def run(arguments, environment)
        area = @configuration.area(arguments[0])
        @state.change_focus(area[:key], @configuration)
        @state.persist
        @configuration.actions.each_key do |key|
          Registry::plugins[key][:action].new(@configuration, @state).run(environment)
        end
        "#{area[:name]} is now the focused area"
      end
    end
  end
end
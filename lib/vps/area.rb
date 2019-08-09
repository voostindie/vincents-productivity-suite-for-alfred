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

      def run(arguments)
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

      end

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available commands for the focused area'
        end
      end
    end

    class Focus
      def initialize(configuration, state)

      end

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Set the focus to the specified area'
        end
      end
    end

    def self.list(config: Config.load)
      focus = config.focused_area[:key]
      config.areas.map do |name|
        area = config.area(name)
        postfix = area[:key].eql?(focus) ? ' (focused)' : ''
        {
          uid: area[:key],
          arg: area[:key],
          title: area[:name] + postfix,
          autocomplete: area[:name]
        }
      end
    end

    def self.focus(key, config: Config.load)
      area = config.focus(key)
      config.save
      config.actions.each do |key|
        action = instantiate_action(key)
        action.focus_changed(area, config.action(key))
      end
      "#{area[:name]} is now the focused area"
    end

    def self.instantiate_action(key)
      plugin = PLUGINS[key]
      return if plugin.nil?
      require_relative(plugin[:path])
      Object.const_get(plugin[:class]).new
    end
  end
end
module VPS
  module Area
    class List
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available areas'
        end
      end

      def run
        focus = @context.focus[:key]
        @context.configuration.areas.map do |area|
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

    class Focus
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Set the focus to the specified area'
          parser.separator 'Usage: area focus <area>'
          parser.separator ''
          parser.separator 'Where <area> is the key of the area to focus on.'
        end
      end

      def can_run?
        if @context.arguments.size != 1
          $stderr.puts "Exactly one argument required: the name of the area to focus on"
          return false
        end
        area = @context.configuration.area(@context.arguments[0])
        if area.nil?
          $stderr.puts "Unknown area: #{@context.arguments[0]}"
          return false
        end
        true
      end

      def run
        area = @context.configuration.area(@context.arguments[0])
        @context.state.change_focus(area[:key], @context.configuration)
        @context.state.persist
        @context.configuration.actions.each_key do |key|
          Registry::plugins[key].action_class.new(@context).run
        end
        "#{area[:name]} is now the focused area"
      end
    end

    Registry.register(Area) do |plugin|
      plugin.for_entity(Entities::Area)
      plugin.add_command(List, :list)
      plugin.add_command(Focus, :single)
    end
  end
end
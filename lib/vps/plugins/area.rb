module VPS
  module Plugins
    module Area
      include Plugin

      class AreaRepository < Repository
        def supported_entity_type
          EntityType::Area
        end
      end

      class List < SystemCommand
        def supported_entity_type
          EntityType::Area
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available areas'
          end
        end

        def run(context)
          focus = context.area[:key]
          context.configuration.areas.map do |area|
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

      class Focus < SystemCommand
        def supported_entity_type
          EntityType::Area
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Set the focus to the specified area'
            parser.separator 'Usage: area focus <area>'
            parser.separator ''
            parser.separator 'Where <area> is the key of the area to focus on.'
          end
        end

        def run(context)
          if context.arguments.size != 1
            $stderr.puts "Exactly one argument required: the name of the area to focus on"
            return nil
          end
          area = context.configuration.area(context.arguments[0])
          if area.nil?
            $stderr.puts "Unknown area: #{context.arguments[0]}"
            return nil
          end
          context.state.change_focus(area[:key], context.configuration)
          context.state.persist
          context = SystemContext.new(context.configuration, context.state, context.arguments)
          context.configuration.actions.each_key do |plugin_name|
            # TODO: create a different kind of context for the action; now it gets the complete configuration.
            # Possible alternative: new area plugin configuration, action configuration
            # On the other hand: maybe some actions need the complete configuration...
            Registry.instance.plugins[plugin_name].action.run(context)
          end
          "#{area[:name]} is now the focused area"
        end
      end

      class Flush < EntityTypeCommand
        include CacheSupport

        def supported_entity_type
          EntityType::Area
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Flushes any caches for all plugins in this area'
            parser.separator 'Usage: area flush'
          end
        end

        def run(context)
          total = flush_plugin_cache(context.area_key)
          "Flushed #{total} cache file(s) for area #{context.area_key}"
        end
      end

      class Commands < SystemCommand
        def supported_entity_type
          EntityType::Area
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available commands for entities of the specified type in this area'
            parser.separator 'Usage: area commands <type> <entityID>'
            parser.separator ''
            parser.separator 'This command is fairly useless outside of Alfred!'
          end
        end

        ##
        # @param context [SystemContext]
        def run(context)
          type_name = context.arguments.shift
          raise 'No type specified' if type_name.nil?
          id = context.arguments.join(' ')
          raise 'No id specified' if id.empty?
          context.configuration
            .available_commands(context.area)
            .select { |entity_type, _| entity_type.entity_type_name == type_name }
            .map { |_, commands| commands }
            .flatten
            .reject { |command| command.is_a?(VPS::Plugin::EntityTypeCommand) }
            .map do |command|
            {
              title: command.option_parser.banner,
              arg: "#{type_name} #{command.name} #{id}",
              icon: {
                path: "icons/#{Registry.instance.for_command(command).name}.png"
              }
            }
          end
        end
      end
    end
  end
end
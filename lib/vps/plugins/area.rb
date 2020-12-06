module VPS
  module Plugins
    # Commands on the areas used within the system themselves.
    #
    # This may seem a bit of a hack, to use the plugin system itself to have built-in commands on
    # areas show up. I call it... pure elegance! :-)
    module Area
      include Plugin

      # Repository for areas; it doesn't actually do anything.
      # This class is needed only to make the commands show up. Since: if the supporting repository
      # isn't there, the command will be filtered out!
      class AreaRepository < Repository
        def supported_entity_type
          EntityType::Area
        end
      end

      # Lists all available areas
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
          context.configuration.areas.values.map do |area|
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

      # Sets the focus to an area, and runs all enabled actions.
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
          area = context.configuration.areas[context.arguments[0]]
          if area.nil?
            $stderr.puts "Unknown area: #{context.arguments[0]}"
            return nil
          end
          context.change_focus(area)
          context.configuration.actions.each_key do |plugin_name|
            Registry.instance.plugins[plugin_name].action.run(context)
          end
          "#{area[:name]} is now the focused area"
        end
      end

      # Flush all disk caches for the active area, see {VPS::CacheSupport} for more information.
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

      # Outputs the name of the focused area.
      class Current < SystemCommand
        def supported_entity_type
          EntityType::Area
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Prints the name of the area that has focus'
            parser.separator 'Usage: area current'
          end
        end

        def run(context)
          context.area[:name]
        end

      end

      # Lists all available commands in this area. This command purely exists to support the
      # Alfred workflow, allowing it to show a list of things to do for a selected entity.
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

        def run(context)
          type_name = context.arguments.shift
          raise 'No type specified' if type_name.nil?
          instance = load_instance(context, type_name)
          raise "Entity not found" if instance.nil?

          root = File.expand_path('../../..', File.dirname(File.realdirpath(__FILE__)))
          context.configuration
                 .available_commands(context.area)
                 .select { |entity_type, _| entity_type.entity_type_name == type_name }
                 .map { |_, commands| commands }
                 .flatten
                 .reject { |command| command.is_a?(VPS::Plugin::EntityTypeCommand) }
                 .select { |command| command.enabled?(context.for_command(command), instance) }
                 .map { |command|
                   {
                     title: command.option_parser.banner,
                     arg: "#{type_name} #{command.name} #{instance.id}",
                     icon: {
                       path: "#{root}/icons/#{Registry.instance.for_command(command).name}.png"
                     }
                   }
                 }
        end

        def load_instance(context, type_name)
          repository = context.resolve_repository(type_name)
          repository.load_instance(context.for_repository(repository))
        end
      end
    end
  end
end
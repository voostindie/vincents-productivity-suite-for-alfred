module VPS
  module Plugins
    module Area
      include Plugin

      class AreaRepository < BaseRepository
        def supported_entity_type
          EntityTypes::Area
        end
      end

      class List < SystemCommand
        def supported_entity_type
          EntityTypes::Area
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
          EntityTypes::Area
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
          EntityTypes::Area
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

      #
      # class Commands
      #   include PluginSupport
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'List all available commands for the specified contact'
      #       parser.separator 'Usage: contact commands <contactId>'
      #       parser.separator ''
      #       parser.separator 'Where <contactId> is the ID of the contact to act upon'
      #     end
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Contact)
      #   end
      #
      #   def run
      #     contact = Contacts::load_entity(@context)
      #     commands = []
      #     commands << {
      #       title: 'Open in Contacts',
      #       arg: "contact open #{contact.id}",
      #       icon: {
      #         path: "icons/contacts.png"
      #       }
      #     }
      #     commands += @context.collaborator_commands(contact)
      #     commands.flatten
      #   end
      # end
    end
  end
end
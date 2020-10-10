module VPS
  module Plugins
    # This plugin works on top of Apple Contacts, but it supports a different Entity.
    # The current plugin model doesn't allow multiple entities per plugin, so I'm
    # working around that here.
    module Groups
      def self.configure_plugin(plugin)
        plugin.configurator_class = Configurator
        plugin.for_entity(Entities::Group)
        plugin.add_command(List, :list)
        plugin.add_command(Commands, :list)
      end

      class Configurator < PluginSupport::Configurator
        def read_area_configuration(area, hash)
          {
            prefix: hash['prefix'] || area[:name] + ' - ',
            cache: hash['cache'] || false
          }
        end
      end

      def self.load_entity(context, runner = Jxa::Runner.new('contacts'))
        id = context.environment['GROUP_ID'] || context.arguments[0]
        Entities::Group.from_hash(runner.execute('group-details', id))
      end

      class List
        include PluginSupport, CacheSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available groups in this area'
            parser.separator 'Usage: group list'
          end
        end

        def cache_enabled?
          @context.focus['groups'][:cache] == true
        end

        def run(runner = Jxa::Runner.new('contacts'))
          cache do
            contacts = runner.execute('list-groups', @context.focus['groups'][:prefix])
            contacts.map do |group|
              group = Entities::Group.from_hash(group)
              {
                uid: group.id,
                title: group.name,
                subtitle: if triggered_as_snippet?
                            "Paste addresses from '#{group.name}' in the frontmost application"
                          else
                            "Select an action for '#{group.name}'"
                          end,
                arg: group.name,
                autocomplete: group.name,
                variables: group.to_env
              }
            end
          end
        end
      end

      class Commands
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available commands for the specified group'
            parser.separator 'Usage: group commands <groupId>'
            parser.separator ''
            parser.separator 'Where <groupId> is the ID of the group to act upon'
          end
        end

        def can_run?
          is_entity_present?(Entities::Group)
        end

        def run
          group = Groups::load_entity(@context)
          commands = @context.collaborator_commands(group)
          commands.flatten
        end
      end
    end
  end
end
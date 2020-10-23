module VPS
  module Plugins
    module Contacts
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          group = force(hash['group'], String) || area[:name]
          {
            group: group,
            prefix: force(hash['prefix'], String) || group + ' - ',
            cache: hash['cache'] || false
          }
        end
      end

      class ContactRepository < BaseRepository
        def supported_entity_type
          EntityTypes::Contact
        end

        def find_all(context, runner = Jxa::Runner.new('contacts'))
          contacts = runner.execute('list-people', context.configuration[:group])
          contacts.map { |contact| EntityTypes::Contact.from_hash(contact) }
        end

        def load(context, runner = Jxa::Runner.new('contacts'))
          if context.environment['CONTACT_ID'].nil?
            EntityTypes::Contact.from_hash(runner.execute('contact-details', context.arguments[0]))
          else
            EntityTypes::Contact.from_env(context.environment)
          end
        end
      end

      class GroupRepository < BaseRepository
        def supported_entity_type
          EntityTypes::Group
        end

        def find_all(context, runner = Jxa::Runner.new('contacts'))
          groups = runner.execute('list-groups', context.configuration[:prefix])
          groups.map { |group| EntityTypes::Group.from_hash(group) }
        end

        def load(context, runner = Jxa::Runner.new('contacts'))
          if context.environment['GROUP_ID'].nil?
            EntityTypes::Group.from_hash(runner.execute('group-details', context.arguments[0]))
          else
            EntityTypes::Group.from_env(context.environment)
          end
        end
      end

      module ListSupport
        extend CacheSupport

        def name
          'list'
        end

        def option_parser
          name = supported_entity_type.entity_type_name + 's'
          OptionParser.new do |parser|
            parser.banner = "List all available #{name} in this area"
            parser.separator "Usage: #{name} list"
          end
        end

        def cache_enabled?(context)
          context.configuration[:cache]
        end

        def run(context)
          # TODO: fix caching!
          # cache(context) do
          context.find_all.map do |entity|
            {
              uid: entity.id,
              title: entity.name,
              subtitle: if context.triggered_as_snippet?
                          "Paste '#{entity.name}' in the frontmost application"
                        else
                          "Select an action for '#{entity.name}'"
                        end,
              arg: entity.name,
              autocomplete: entity.name,
              variables: entity.to_env
            }
          end
          # end
        end
      end

      class ListContacts < EntityTypeCommand
        include ListSupport

        def supported_entity_type
          EntityTypes::Contact
        end
      end

      class ListGroups < EntityTypeCommand
        include ListSupport

        def supported_entity_type
          EntityTypes::Group
        end
      end

      class Open < EntityInstanceCommand
        def supported_entity_type
          EntityTypes::Contact
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open the specified contact in Contacts'
            parser.separator 'Usage: contact open <contactId>'
            parser.separator ''
            parser.separator 'Where <contactId> is the ID of the contact to open'
          end
        end

        def run(context, runner = Shell::SystemRunner.new)
          contact = context.load
          runner.execute('open', "addressbook://#{contact.id}")
          nil
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
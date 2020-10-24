module VPS
  module Plugins
    module Contacts
      include Plugin

      class ContactsConfigurator < Configurator
        def process_area_configuration(area, hash)
          group = force(hash['group'], String) || area[:name]
          {
            group: group,
            prefix: force(hash['prefix'], String) || group + ' - ',
            cache_enabled: hash['cache'] || false,
          }
        end
      end

      class ContactRepository < Repository
        include CacheSupport

        def supported_entity_type
          EntityType::Contact
        end

        def cache_enabled?(context)
          context.configuration[:cache_enabled]
        end

        def find_all(context, runner = Jxa::Runner.new('contacts'))
          cache(context) do
            contacts = runner.execute('list-people', context.configuration[:group])
            contacts.map { |contact| EntityType::Contact.from_hash(contact) }
          end
        end

        def load_instance(context, runner = Jxa::Runner.new('contacts'))
          id = context.environment['CONTACT_ID'] || context.arguments[0]
          cache(context, id) do
            EntityType::Contact.from_hash(runner.execute('contact-details', id))
          end
        end
      end

      class GroupRepository < Repository
        include CacheSupport

        def supported_entity_type
          EntityType::Group
        end

        def cache_enabled?(context)
          context.configuration[:cache_enabled]
        end

        def find_all(context, runner = Jxa::Runner.new('contacts'))
          cache(context) do
            groups = runner.execute('list-groups', context.configuration[:prefix])
            groups.map { |group| EntityType::Group.from_hash(group) }
          end
        end

        def load_instance(context, runner = Jxa::Runner.new('contacts'))
          id = context.environment['GROUP_ID'] || context.arguments[0]
          cache(context, id) do
            EntityType::Group.from_hash(runner.execute('group-details', id))
          end
        end
      end

      module ListSupport
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

        def run(context)
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
        end
      end

      class ListContacts < EntityTypeCommand
        include ListSupport

        def supported_entity_type
          EntityType::Contact
        end
      end

      class ListGroups < EntityTypeCommand
        include ListSupport

        def supported_entity_type
          EntityType::Group
        end
      end

      class Open < EntityInstanceCommand

        def supported_entity_type
          EntityType::Contact
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in Contacts'
            parser.separator 'Usage: contact open <contactId>'
            parser.separator ''
            parser.separator 'Where <contactId> is the ID of the contact to open'
          end
        end

        def run(context, runner = Shell::SystemRunner.new)
          contact = context.load_instance
          runner.execute('open', "addressbook://#{contact.id}")
          "Opened #{contact.name} in Contacts"
        end
      end
    end
  end
end
module VPS
  module Plugins
    module Contacts

      def self.read_area_configuration(area, hash)
        {
          group: hash['group'] || area[:name],
        }
      end

      def self.load_entity(context, runner = Jxa::Runner.new('contacts'))
        if context.environment['CONTACT_ID'].nil?
          Entities::Contact.from_hash(runner.execute('contact-details', context.arguments[0]))
        else
          Entities::Contact.from_env(context.environment)
        end
      end

      class List
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available contacts in this area'
            parser.separator 'Usage: contact list'
          end
        end

        def run(runner = Jxa::Runner.new('contacts'))
          contacts = runner.execute('list-people', @context.focus['contacts'][:group])
          contacts.map do |contact|
            contact = Entities::Contact.from_hash(contact)
            {
              uid: contact.id,
              title: contact.name,
              subtitle: if triggered_as_snippet?
                          "Paste '#{contact.name}' in the frontmost application"
                        else
                          "Select an action for '#{contact.name}'"
                        end,
              arg: contact.name,
              autocomplete: contact.name,
              variables: contact.to_env
            }
          end
        end
      end

      class Open
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open the specified contact in Contacts'
            parser.separator 'Usage: contact open <contactId>'
            parser.separator ''
            parser.separator 'Where <contactId> is the ID of the contact to open'
          end
        end

        def can_run?
          is_entity_present?(Entities::Contact)
        end

        def run(runner = Shell::SystemRunner.new)
          runner.execute("open addressbook://#{@context.arguments[0]}")
          nil
        end
      end

      class Commands
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available commands for the specified contact'
            parser.separator 'Usage: contact commands <contactId>'
            parser.separator ''
            parser.separator 'Where <contactId> is the ID of the contact to act upon'
          end
        end

        def can_run?
          is_entity_present?(Entities::Contact)
        end

        def run
          contact = Contacts::load_entity(@context)
          commands = []
          commands << {
            title: 'Open in Contacts',
            arg: "contact open #{contact.id}",
            icon: {
              path: "icons/contacts.png"
            }
          }
          commands += @context.collaborator_commands(contact)
          commands.flatten
        end
      end

      Registry.register(Contacts) do |plugin|
        plugin.for_entity(Entities::Contact)
        plugin.add_command(List, :list)
        plugin.add_command(Open, :single)
        plugin.add_command(Commands, :list)
      end
    end
  end
end
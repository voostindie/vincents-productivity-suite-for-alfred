module VPS
  module Contacts

    def self.read_area_configuration(area, hash)
      mail = hash['mail'] || {}
      {
        group: hash['group'] || area[:name],
        mail: {
          client: mail['client'] || 'Mail',
          from: mail['from'] || nil
        }
      }
    end

    def self.details_for(id, runner = Jxa::Runner.new('contacts'))
      runner.execute('contact-details', id)
    end

    class List
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available contacts in this area'
          parser.separator 'Usage: contact list'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled? :contacts
      end

      def run(arguments, environment, runner = Jxa::Runner.new('contacts'))
        contacts = runner.execute('list-people', @state.focus[:contacts][:group])
        contacts.map do |contact|
          {
            uid: contact['id'],
            title: contact['name'],
            subtitle: if triggered_as_snippet?(environment)
                        "Paste '#{contact['name']}' in the frontmost application"
                      else
                        "Select an action for '#{contact['name']}'"
                      end,
            arg: contact['name'],
            autocomplete: contact['name'],
            variables: {
              # Passed in the Alfred workflow as an argument to subsequent commands
              CONTACT_ID: contact['id']
            }
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

      def can_run?(arguments, environment)
        is_plugin_enabled?(:contacts) && has_arguments?(arguments)
      end

      def run(arguments, environment, runner = Shell::SystemRunner.new)
        runner.execute("open addressbook://#{arguments[0]}")
        nil
      end
    end

    class Email
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Prepare an email to the specified contact'
          parser.separator 'Usage: contact email <contactId>'
          parser.separator ''
          parser.separator 'Where <contactId> is the ID of the contact to write a mail to'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled?(:contacts) && has_arguments?(arguments)
      end

      def run(arguments, environment, runner = Jxa::Runner.new('contacts'))
        contact = Contacts::details_for(arguments[0])
        address_line = "#{contact['name']} <#{contact['email']}>"
        mail = @state.focus[:contacts][:mail]
        case mail[:client]
        when 'Mail'
          runner.execute('create-mail-message', address_line, mail[:from])
        when 'Microsoft Outlook'
          # Note, the "from" address is not supported for Outlook.
          # I don't need it, so I don't care right now.
          runner.execute('create-outlook-message', address_line)
        else
          raise "Unsupported mail client: #{mail[:client]}"
        end
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

      def can_run?(arguments, environment)
        is_plugin_enabled?(:contacts) && has_arguments?(arguments)
      end

      def run(arguments, environment)
        contact_id = arguments[0]
        commands = []
        commands << {
          uid: 'open',
          title: 'Open in Contacts',
          arg: "contact open #{contact_id}",
          icon: {
            path: "icons/contacts.png"
          }
        }
        collaborators = @configuration.collaborators(@state.focus, :contact)
        collaborators.each_value do |collaborator|
          commands << collaborator[:module].commands_for(:contact, contact_id)
        end
        commands << {
          uid: 'email',
          title: 'Write email',
          arg: "contact email #{contact_id}",
          icon: {
            path: "icons/mail.png"
          }
        }
        commands.flatten
      end
    end

    def self.create_email(address, area: Config.load.focused_area, runner: Jxa::Runner.new('contacts'))
      address_line = "#{address[:name]} <#{address[:email]}>"
      mail = area[:contacts][:mail]
      case mail[:client]
      when 'Mail'
        runner.execute('create-mail-message', address_line, mail[:from])
      when 'Microsoft Outlook'
        # Note, the "from" address is not supported for Outlook.
        # I don't need it, so I don't care right now.
        runner.execute('create-outlook-message', address_line)
      else
        raise "Unsupported mail client: #{mail[:client]}"
      end
    end

    def self.actions(contact, area: Config.load.focused_area)
      contacts = area[:contacts]
      raise 'Contacts is not enabled for the focused area' unless contacts
      supports_notes = area[:markdown_notes] != nil || area[:bear] != nil
      supports_markdown_notes = area[:markdown_notes] != nil
      actions = []
      actions.push(
        title: 'Show in Contact Viewer',
        arg: contact[:name],
        variables: {
          action: 'contact-viewer'
        }
      )
      actions.push(
        title: 'Paste in frontmost application',
        arg: contact[:name],
        variables: {
          action: 'snippet'
        }
      )
      actions
    end
  end
end
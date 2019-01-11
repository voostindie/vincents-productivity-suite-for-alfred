require 'json'
require 'jxa'
require 'config'

module Contacts

  def self.create_email(address, area: Config.load.focused_area, runner: Jxa::Runner.new(__FILE__))
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

  def self.people(triggered_as_snippet = false, area: Config.load.focused_area, runner: Jxa::Runner.new(__FILE__))
    contacts = area[:contacts]
    raise 'Contacts is not enabled for the focused area' unless contacts
    group = contacts[:group]
    contacts = runner.execute('list-people', group)
    contacts.map do |contact|
      {
        uid: contact['id'],
        title: contact['name'],
        subtitle: if triggered_as_snippet
                    "Paste '#{contact['name']}' in the frontmost application"
                  else
                    "Select an action for '#{contact['name']}'"
                  end,
        arg: contact['name'],
        autocomplete: contact['name'],
        variables: {
          id: contact['id'],
          name: contact['name'],
          email: contact['email']
        }
      }
    end
  end

  def self.actions(contact, area: Config.load.focused_area)
    contacts = area[:contacts]
    raise 'Contacts is not enabled for the focused area' unless contacts
    supports_notes = area[:markdown_notes] != nil
    actions = []
    actions.push(
      title: 'Open in Contacts',
      arg: "addressbook://#{contact[:id]}",
      variables: {
        action: 'open'
      }
    )
    if supports_notes
      actions.push(
        title: 'Create note',
        arg: contact[:name],
        variables: {
          action: 'create-markdown-note'
        }
      )
      actions.push(
        title: 'Search notes',
        arg: contact[:name],
        variables: {
          action: 'search-markdown-notes'
        }
      )
    end
    actions.push(
      title: 'Write e-mail',
      arg: contact[:name],
      variables: {
        action: 'create-email',
        id: contact[:id],
        name: contact[:name],
        email: contact[:email]
      }
    )
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
require 'json'
require_relative 'config'
require_relative 'jxa'

module Contacts

  def self.create_email(address, area: Config.load.focused_area, runner: Jxa::Runner.new)
    mail = area[:contacts][:mail]
    case mail[:client]
    when 'Mail'
      runner.execute('mail-create-email-message', address, mail[:from])
    when 'Microsoft Outlook'
      # Note, the "from" address is not supported for Outlook.
      # I don't need it, so I don't care right now.
      runner.execute('outlook-create-email-message', address)
    else
      raise "Unsupported mail client: #{mail[:client]}"
    end
  end

  class << self

    def people(triggered_as_snippet = false, area: Config.load.focused_area, runner: Jxa::Runner.new)
      contacts = area[:contacts]
      raise "Contacts is not enabled for the focused area" unless contacts
      group = contacts[:group]
      supports_notes = area[:markdown_notes] != nil
      contacts = runner.execute('contacts-people', group)
      contacts.map do |contact|
        {
          uid: contact['id'],
          title: contact['name'],
          subtitle: if triggered_as_snippet
                      'Paste this name in the frontmost application'
                    else
                      'View this contact in Alfred'
                    end,
          arg: contact['name'],
          autocomplete: contact['name'],
          mods: {
            alt: {
              valid: supports_notes,
              arg: contact['name'],
              subtitle: if supports_notes
                          'Create a Markdown note for this contact'
                        else
                          'Markdown notes are not available for the focused area'
                        end
            }
          }
        }
      end
    end
  end
end
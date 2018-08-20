require 'json'
require_relative 'config'
require_relative 'jxa'

module Contacts

  class << self

    def people(area: Config.load.focused_area, runner: Jxa::Runner.new)
      contacts = area[:contacts]
      raise "Contacts is not enabled for the focused area" unless contacts
      group = contacts[:group]
      supports_notes = area[:markdown_notes] != nil
      contacts = runner.execute('contacts-people', group)
      contacts.map do |contact|
        {
          uid: contact['id'],
          title: contact['name'],
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
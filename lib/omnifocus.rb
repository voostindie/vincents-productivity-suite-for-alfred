require 'json'
require_relative 'config'
require_relative 'jxa'

module OmniFocus

  class << self

    def projects(area: Config.load.focused_area, runner: Jxa::Runner.new)
      omnifocus = area[:omnifocus]
      raise 'OmniFocus is not enabled for the focused area' unless omnifocus
      folder = omnifocus[:folder]
      supports_notes = area[:markdown_notes] != nil

      projects = runner.execute('omnifocus-projects', folder)
      projects.map do |project|
        {
          uid: project['id'],
          title: project['name'],
          arg: project['name'],
          autocomplete: project['name'],
          mods: {
            alt: {
              valid: supports_notes,
              arg: project['name'],
              subtitle: if supports_notes
                          'Create a Markdown note for this project'
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
require 'json'
require_relative 'config'
require_relative 'jxa'

class OmniFocus

  def initialize(runner = Jxa::Runner.new)
    @runner = runner
  end

  def change(area, defaults)
    omnifocus = area[:omnifocus]
    return if omnifocus.nil?
    puts omnifocus[:folder]
    @runner.execute('omnifocus-set-focus', omnifocus[:folder])
  end

  def self.projects(triggered_as_snippet = false, area: Config.load.focused_area, runner: Jxa::Runner.new)
    omnifocus = area[:omnifocus]
    raise 'OmniFocus is not enabled for the focused area' unless omnifocus
    folder = omnifocus[:folder]
    supports_notes = area[:markdown_notes] != nil

    projects = runner.execute('omnifocus-projects', folder)
    projects.map do |project|
      {
        uid: project['id'],
        title: project['name'],
        subtitle: if triggered_as_snippet
                    "Paste '#{project['name']}' in the frontmost application"
                  else
                    "Open '#{project['name']}' in OmniFocus"
                  end,
        arg: if triggered_as_snippet
               project['name']
             else
               "omnifocus://task/#{project['id']}"
             end,
        autocomplete: project['name'],
        mods: {
          alt: {
            valid: supports_notes,
            arg: project['name'],
            subtitle: if supports_notes
                        "Create a Markdown note on '#{project['name']}'"
                      else
                        'Markdown notes are not available for the focused area'
                      end
          }
        }
      }
    end
  end
end
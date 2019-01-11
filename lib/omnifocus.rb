require 'json'
require_relative 'focus_plugin'
require_relative 'config'
require_relative 'jxa'
require_relative 'filesystem'

class OmniFocus < FocusPlugin

  def initialize(runner = Jxa::Runner.new(__FILE__))
    @runner = runner
  end

  def focus_changed(area, defaults)
    omnifocus = area[:omnifocus]
    return if omnifocus.nil?
    puts omnifocus[:folder]
    @runner.execute('omnifocus-set-focus', omnifocus[:folder])
  end

  def self.projects(triggered_as_snippet = false, area: Config.load.focused_area, runner: Jxa::Runner.new(__FILE__))
    omnifocus = area[:omnifocus]
    raise 'OmniFocus is not enabled for the focused area' unless omnifocus
    folder = omnifocus[:folder]
    projects = runner.execute('omnifocus-projects', folder)
    projects.map do |project|
      {
        uid: project['id'],
        title: project['name'],
        subtitle: if triggered_as_snippet
                    "Paste '#{project['name']}' in the frontmost application"
                  else
                    "Select an action for '#{project['name']}'"
                  end,
        arg: project['name'],
        variables: {
          id: project['id'],
          name: project['name']
        },
        autocomplete: project['name'],
      }
    end
  end

  def self.actions(project, area: Config.load.focused_area)
    omnifocus = area[:omnifocus]
    raise 'OmniFocus is not enabled for the focused area' unless omnifocus
    supports_notes = area[:markdown_notes] != nil
    supports_files = area[:project_files] != nil
    actions = []
    actions.push(
      title: 'Open in OmniFocus',
      arg: "omnifocus://task/#{project[:id]}",
      variables: {
        action: 'open'
      }
    )
    if supports_notes
      actions.push(
        title: 'Create note',
        arg: project[:name],
        variables: {
          action: 'create-markdown-note'
        }
      )
      actions.push(
        title: 'Search notes',
        arg: project[:name],
        variables: {
          action: 'search-markdown-notes'
        }
      )
    end
    if supports_files
      files = area[:project_files]
      path = File.join(area[:root], files[:path], FileSystem::safe_filename(project[:name]))
      documents = File.join(path, files[:documents])
      if FileSystem::exists?(documents)
        actions.push(
          title: 'Browse documents',
          arg: documents,
          variables: {
            action: 'browse-project-files'
          }
        )
      end
      reference = File.join(path, files[:reference])
      if FileSystem::exists?(reference)
       actions.push(
          title: 'Browse reference material',
          arg: reference,
          variables: {
            action: 'browse-project-files'
          }
        )
      end
    end
    actions.push(
      title: 'Paste in frontmost application',
      arg: project[:name],
      variables: {
        action: 'snippet'
      }
    )
    actions
  end
end
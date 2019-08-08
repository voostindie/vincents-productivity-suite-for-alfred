module VPS
  class OmniFocusPlugin < FocusPlugin

    def initialize(defaults = {}, runner: Jxa::Runner.new(__FILE__))
      @runner = runner
    end

    def focus_changed(area, old_area_config)
      omnifocus = old_area_config[:omnifocus]
      return if omnifocus.nil?
      puts omnifocus[:folder]
      @runner.execute('set-focus', omnifocus[:folder])
    end

    def self.projects(triggered_as_snippet = false, area: Config.load.focused_area, runner: Jxa::Runner.new(__FILE__))
      omnifocus = area[:omnifocus]
      raise 'OmniFocus is not enabled for the focused area' unless omnifocus
      folder = omnifocus[:folder]
      projects = runner.execute('list-projects', folder)
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
      supports_notes = area[:markdown_notes] != nil || area[:bear] != nil
      supports_markdown_notes = area[:markdown_notes] != nil
      supports_files = area[:project_files] != nil
      actions = []
      actions.push(
        title: 'Open in OmniFocus',
        arg: "omnifocus://task/#{project[:id]}",
        variables: {
          action: 'open'
        },
        icon: {
          path: "icons/omnifocus.png"
        }
      )
      if supports_notes
        actions.push(
          title: 'Create note',
          arg: project[:name],
          variables: {
            action: 'create-note'
          },
          icon: {
            path: "icons/bear.png"
          }
        )
      end
      if supports_markdown_notes
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
            },
            icon: {
              path: "icons/finder.png"
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
            },
            icon: {
              path: "icons/finder.png"
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
end
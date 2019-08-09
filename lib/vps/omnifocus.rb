module VPS
  module OmniFocus
    def self.read_area_configuration(area, hash)
      {
        folder: hash['folder'] || area[:name]
      }
    end

    def self.read_action_configuration(hash)
      {
      }
    end

    def self.details_for(id, runner = Jxa::Runner.new('omnifocus'))
      runner.execute('project-details', id)
    end

    class Focus
      include PluginSupport

      def run(environment, runner = Jxa::Runner.new('omnifocus'))
        if @state.focus[:omnifocus]
          runner.execute('set-focus', @state.focus[:omnifocus][:folder])
        end
      end
    end

    class List
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available projects in this area'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled? :omnifocus
      end

      def run(arguments, environment, runner = Jxa::Runner.new('omnifocus'))
        triggered_as_snippet = if environment['TRIGGERED_AS_SNIPPET'].nil?
                                 false
                               else
                                 environment['TRIGGERED_AS_SNIPPET'] == 'true'
                               end
        projects = runner.execute('list-projects', @state.focus[:omnifocus][:folder])
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
              # Passed in the Alfred workflow as an argument to subsequent commands
              PROJECT_ID: project['id']
            },
            autocomplete: project['name'],
          }
        end
      end
    end

    class Open
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Open the specified project in OmniFocus'
          parser.separator 'Usage: omnifocus open <project>'
          parser.separator ''
          parser.separator 'Where <project> is the ID of the project to open'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled?(:omnifocus) && has_arguments?(arguments)
      end

      def run(arguments, environment, runner = Shell::SystemRunner.new)
        runner.execute('open', "omnifocus:///task/#{arguments[0]}")
        nil
      end
    end

    class Commands
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available commands for the specified project'
          parser.separator 'Usage: omnifocus commands <project>'
          parser.separator ''
          parser.separator 'Where <project> is the ID of the project to open'
        end
      end

      def can_run?(arguments, environment)
        if is_plugin_enabled? :omnifocus
          if arguments.size != 1
            $stderr.puts "The ID of the project to open must be passed as an argument"
            return false
          end
        end
        true
      end

      def run(arguments, environment)
        project_id = arguments[0]
        commands = []
        commands << {
          uid: 'open',
          title: 'Open in OmniFocus',
          arg: "omnifocus open '#{arguments[0]}'",
          icon: {
            path: "icons/omnifocus.png"
          }
        }
        collaborators = @configuration.collaborators(@state.focus, :projects)
        collaborators.each_value do |collaborator|
          commands << collaborator[:module].commands_for(:projects, project_id)
        end
        commands.flatten
      end
    end
  end

  class OmniFocusPlugin

    def self.actions(project, area: Config.load.focused_area)
      omnifocus = area[:omnifocus]
      raise 'OmniFocus is not enabled for the focused area' unless omnifocus
      supports_notes = area[:markdown_notes] != nil || area[:bear] != nil
      supports_markdown_notes = area[:markdown_notes] != nil
      supports_files = area[:project_files] != nil
      actions = []
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
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
          parser.separator 'Usage: project list'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled? :omnifocus
      end

      def run(arguments, environment, runner = Jxa::Runner.new('omnifocus'))
        projects = runner.execute('list-projects', @state.focus[:omnifocus][:folder])
        projects.map do |project|
          {
            uid: project['id'],
            title: project['name'],
            subtitle: if triggered_as_snippet?(environment)
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
          parser.separator 'Usage: project open <projectId>'
          parser.separator ''
          parser.separator 'Where <projectId> is the ID of the project to open'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled?(:omnifocus) && has_arguments?(arguments)
      end

      def run(arguments, environment, runner = Shell::SystemRunner.new)
        runner.execute("open omnifocus:///task/#{arguments[0]}")
        nil
      end
    end

    class Commands
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'List all available commands for the specified project'
          parser.separator 'Usage: project commands <projectId>'
          parser.separator ''
          parser.separator 'Where <projectId> is the ID of the project to act upon'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled?(:omnifocus) && has_arguments?(arguments)
      end

      def run(arguments, environment)
        project_id = arguments[0]
        commands = []
        commands << {
          title: 'Open in OmniFocus',
          arg: "project open #{arguments[0]}",
          icon: {
            path: "icons/omnifocus.png"
          }
        }
        collaborators = @configuration.collaborators(@state.focus, :project)
        collaborators.each_value do |collaborator|
          commands << collaborator[:module].commands_for(:project, project_id)
        end
        commands.flatten
      end
    end
  end
end
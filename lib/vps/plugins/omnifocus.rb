module VPS
  module Plugins
    module OmniFocus
      def self.configure_plugin(plugin)
        plugin.configurator = Configurator.new
        plugin.add_repository(Entities::Project, ProjectRepository.new)
        plugin.for_entity(Entities::Project)
        plugin.add_command(List, :list)
        plugin.add_command(Open, :single)
        plugin.add_command(Commands, :list)
        plugin.with_action(Focus)
      end

      class Configurator < PluginSupport::Configurator
        def read_area_configuration(area, hash)
          {
            folder: hash['folder'] || area[:name]
          }
        end
      end

      class ProjectRepository < PluginSupport::Repository
        def load_entity(context, runner = Jxa::Runner.new('omnifocus'))
          if context.environment['PROJECT_ID'].nil?
            Entities::Project.from_hash(runner.execute('project-details', context.arguments[0]))
          else
            Entities::Project.from_env(context.environment)
          end
        end
      end

      def self.load_entity(context, runner = Jxa::Runner.new('omnifocus'))
        if context.environment['PROJECT_ID'].nil?
          Entities::Project.from_hash(runner.execute('project-details', context.arguments[0]))
        else
          Entities::Project.from_env(context.environment)
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

        def run(runner = Jxa::Runner.new('omnifocus'))
          projects = runner.execute('list-projects', @context.focus['omnifocus'][:folder])
          projects.map do |project|
            project = Entities::Project.from_hash(project)
            {
              uid: project.id,
              title: project.name,
              subtitle: if triggered_as_snippet?
                          "Paste '#{project.name}' in the frontmost application"
                        else
                          "Select an action for '#{project.name}'"
                        end,
              arg: project.name,
              autocomplete: project.name,
              variables: project.to_env
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

        def can_run?
          is_entity_present?(Entities::Project)
        end

        def run(runner = Shell::SystemRunner.new)
          runner.execute("open omnifocus:///task/#{@context.arguments[0]}")
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

        def can_run?
          is_entity_present?(Entities::Project)
        end

        def run
          project = OmniFocus::load_entity(@context)
          commands = []
          commands << {
            title: 'Open in OmniFocus',
            arg: "project open #{project.id}",
            icon: {
              path: "icons/omnifocus.png"
            }
          }
          commands += @context.collaborator_commands(project)
        end
      end

      class Focus
        include PluginSupport

        def run(runner = Jxa::Runner.new('omnifocus'))
          if @context.focus['omnifocus']
            runner.execute('set-focus', @context.focus['omnifocus'][:folder])
          end
        end
      end
    end
  end
end
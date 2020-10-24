module VPS
  module Plugins
    module OmniFocus
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          {
            folder: force(hash['folder'], String) || area[:name]
          }
        end
      end

      class ProjectRepository < BaseRepository
        def supported_entity_type
          EntityTypes::Project
        end

        def find_all(context, runner = Jxa::Runner.new('omnifocus'))
          projects = runner.execute('list-projects', context.configuration[:folder])
          projects.map do |project|
            EntityTypes::Project.from_hash(project)
          end
        end

        def load(context, runner = Jxa::Runner.new('omnifocus'))
          id = context.environment['PROJECT_ID'] || context.arguments[0]
          EntityTypes::Project.from_hash(runner.execute('project-details', id))
        end
      end

      class List < EntityTypeCommand
        def supported_entity_type
          EntityTypes::Project
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available projects in this area'
            parser.separator 'Usage: project list'
          end
        end

        def run(context, runner = Jxa::Runner.new('omnifocus'))
          context.find_all.map do |project|
            {
              uid: project.id,
              title: project.name,
              subtitle: if context.triggered_as_snippet?
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

      class Open < EntityInstanceCommand
        def supported_entity_type
          EntityTypes::Project
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open the specified project in OmniFocus'
            parser.separator 'Usage: project open <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to open'
          end
        end

        def run(context, runner = Shell::SystemRunner.new)
          project = context.load
          runner.execute("open omnifocus:///task/#{project.id}")
          nil
        end
      end

      class Focus < BaseAction
        def run(context, runner = Jxa::Runner.new('omnifocus'))
          if context.area['omnifocus']
            runner.execute('set-focus', context.area['omnifocus'][:folder])
          end
        end
      end
    end
  end
end
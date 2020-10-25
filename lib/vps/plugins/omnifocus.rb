module VPS
  module Plugins
    # Plugin for OmniFocus, for managing projects.
    module OmniFocus
      include Plugin

      class OmniFocusConfigurator < Configurator
        def process_area_configuration(area, hash)
          {
            folder: force(hash['folder'], String) || area[:name]
          }
        end
      end

      class OmniFocusRepository < Repository
        def supported_entity_type
          EntityType::Project
        end

        def find_all(context, runner = JxaRunner.new('omnifocus'))
          projects = runner.execute('list-projects', context.configuration[:folder])
          projects.map do |project|
            EntityType::Project.from_hash(project)
          end
        end

        def load_instance(context, runner = JxaRunner.new('omnifocus'))
          id = context.environment['PROJECT_ID'] || context.arguments[0]
          return nil if id.nil?
          EntityType::Project.from_hash(runner.execute('project-details', id))
        end
      end

      class List < EntityTypeCommand
        def supported_entity_type
          EntityType::Project
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'List all available projects in this area'
            parser.separator 'Usage: project list'
          end
        end

        def run(context, runner = JxaRunner.new('omnifocus'))
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
          EntityType::Project
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Open in OmniFocus'
            parser.separator 'Usage: project open <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to open'
          end
        end

        def run(context, runner = Shell::SystemRunner.instance)
          project = context.load_instance
          runner.execute("open omnifocus:///task/#{project.id}")
          "Opened #{project.name} in OmniFocus"
        end
      end

      class Focus < Action
        def run(context, runner = JxaRunner.new('omnifocus'))
          if context.area['omnifocus']
            runner.execute('set-focus', context.area['omnifocus'][:folder])
          end
        end
      end
    end
  end
end
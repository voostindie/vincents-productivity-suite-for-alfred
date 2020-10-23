module VPS
  module Plugins
    module OmniFocus
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          {
            folder: force_string(hash['folder']) || area[:name]
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


      #
      # class Commands
      #   include PluginSupport
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'List all available commands for the specified project'
      #       parser.separator 'Usage: project commands <projectId>'
      #       parser.separator ''
      #       parser.separator 'Where <projectId> is the ID of the project to act upon'
      #     end
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Project)
      #   end
      #
      #   def run
      #     project = OmniFocus::load_entity(@context)
      #     commands = []
      #     commands << {
      #       title: 'Open in OmniFocus',
      #       arg: "project open #{project.id}",
      #       icon: {
      #         path: "icons/omnifocus.png"
      #       }
      #     }
      #     commands += @context.collaborator_commands(project)
      #   end
      # end
      #
      # class Focus
      #   include PluginSupport
      #
      #   def run(runner = Jxa::Runner.new('omnifocus'))
      #     if @context.focus['omnifocus']
      #       runner.execute('set-focus', @context.focus['omnifocus'][:folder])
      #     end
      #   end
      # end
    end
  end
end
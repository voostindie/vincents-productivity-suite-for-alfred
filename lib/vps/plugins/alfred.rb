module VPS
  module Plugins
    module Alfred
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          {
            docs: hash['documents'] || 'Documents',
            refs: hash['reference material'] || 'Reference Material'
          }
        end
      end

      class Refs < TypeCommand
        def option_parser
          super do |parser|
            parser.banner = 'Browse reference material in Alfred'
            parser.separator 'Usage: file refs'
          end
        end

        def run(runner = Jxa::Runner.new('alfred'))
          area = @context.focus
          path = File.join(area[:root], area['alfred'][:refs]) + '/'
          runner.execute('browse', path)
          "Opened Alfred for directory '#{path}'"
        end
      end


      class Docs < TypeCommand
        def option_parser
          super do |parser|
            parser.banner = 'Browse documents in Alfred'
            parser.separator 'Usage: file docs'
          end
        end

        def run(runner = Jxa::Runner.new('alfred'))
          area = @context.focus
          path = File.join(area[:root], area['alfred'][:docs]) + '/'
          runner.execute('browse', path)
          "Opened Alfred for directory '#{path}'"
        end
      end

      class ProjectFiles < CollaborationCommand
        def option_parser
          super do |parser|
            parser.banner = 'Browse files in Alfred for a project'
            parser.separator 'Usage: files project <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to browse'
          end
        end

        def can_run?
          is_entity_present?(Types::Project) && is_entity_manager_available?(Types::Project)
        end

        def run(runner = Jxa::Runner.new('alfred'))
          project = @context.load_entity(Types::Project)
          area = @context.focus
          folder = strip_emojis(project.name)
          path = File.join(area[:root], area['alfred'][:refs], folder) + '/'
          runner.execute('browse', path)
          "Opened Alfred for directory '#{path}'"
        end
      end
    end
  end
end
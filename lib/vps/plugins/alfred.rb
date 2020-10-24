module VPS
  module Plugins
    module Alfred
      include Plugin

      class AlfredConfigurator < Configurator
        def process_area_configuration(area, hash)
          {
            docs: File.join(area[:root], force(hash['documents'], String) || 'Documents', '/'),
            refs: File.join(area[:root], force(hash['reference material'], String) || 'Reference Material', '/')
          }
        end
      end

      ##
      # This repository actually doesn't do anything and should be removed once I've implemented
      # a real repository on top of files, which this plugin can then contribute its commands to.
      class DummyFileRepository < Repository
        def supported_entity_type
          EntityType::File
        end
      end

      module FileBrowser
        def supported_entity_type
          EntityType::File
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = "Browse #{@description} in Alfred"
            parser.separator "Usage: file #{name}"
          end
        end

        def run(context, runner = Jxa::Runner.new('alfred'))
          path = context.configuration[@symbol]
          runner.execute('browse', path)
          "Opened Alfred for directory '#{path}'"
        end
      end

      class Docs < EntityTypeCommand
        include FileBrowser

        def initialize
          @description = "documents"
          @symbol = :docs
        end
      end

      class Refs < EntityTypeCommand
        include FileBrowser

        def initialize
          @description = 'reference material'
          @symbol = :refs
        end
      end

      class ProjectFiles < CollaborationCommand
        def name
          'files'
        end

        def supported_entity_type
          EntityType::Project
        end

        def collaboration_entity_type
          EntityType::File
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Browse project files'
            parser.separator 'Usage: project files <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to browse'
          end
        end

        def run(context, runner = Jxa::Runner.new('alfred'))
          project = context.load_instance
          folder = if project.config['alfred']
                     project.config['alfred']['folder'] || project.name
                   else
                     project.name
                   end
          path = File.join(context.configuration[:refs], folder) + '/'
          runner.execute('browse', path)
          "Opened Alfred for directory '#{path}'"
        end
      end
    end
  end
end
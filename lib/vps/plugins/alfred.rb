module VPS
  module Plugins
    module Alfred
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          {
            docs: File.join(area[:root], force_string(hash['documents']) || 'Documents', '/'),
            refs: File.join(area[:root], force_string(hash['reference material']) || 'Reference Material', '/')
          }
        end
      end

      ##
      # This repository actually doesn't do anything and should be removed once I've implemented
      # a real repository on top of files, which this plugin can then contribute its commands to.
      class DummyFileRepository < BaseRepository
        def supported_entity_type
          EntityTypes::File
        end
      end

      module FileBrowser
        def supported_entity_type
          EntityTypes::File
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
          @description = "reference material"
          @symbol = :refs
        end
      end

      # class ProjectFiles < CollaborationCommand
      #   def option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'Browse files in Alfred for a project'
      #       parser.separator 'Usage: files project <projectId>'
      #       parser.separator ''
      #       parser.separator 'Where <projectId> is the ID of the project to browse'
      #     end
      #   end
      #
      #   def supported_entity_type
      #     EntityTypes::Project
      #   end
      #
      #   def can_run?
      #     is_entity_present?(EntityTypes::Project) && is_entity_manager_available?(EntityTypes::Project)
      #   end
      #
      #   def run(context, runner = Jxa::Runner.new('alfred'))
      #     project = @context.load_entity(EntityTypes::Project)
      #     area = @context.focus
      #     folder = strip_emojis(project.name)
      #     path = File.join(area[:root], area['alfred'][:refs], folder) + '/'
      #     runner.execute('browse', path)
      #     "Opened Alfred for directory '#{path}'"
      #   end
      # end
    end
  end
end
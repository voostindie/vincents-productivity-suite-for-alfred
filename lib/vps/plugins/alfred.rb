module VPS
  module Plugins
    module Alfred
      def self.configure_plugin(plugin)
        plugin.configurator_class = Configurator
        plugin.for_entity(Entities::File)
        plugin.add_command(Refs, :single)
        plugin.add_command(Docs, :single)
        plugin.add_command(Project, :single)
        plugin.add_collaboration(Entities::Project)
      end

      class Configurator < PluginSupport::Configurator
        def read_area_configuration(area, hash)
          {
            docs: hash['documents'] || 'Documents',
            refs: hash['reference material'] || 'Reference Material'
          }
        end

      end

      def self.commands_for(area, entity)
        if entity.is_a?(Entities::Project)
          {
            title: 'Browse project files in Alfred',
            arg: "file project #{entity.id}",
            icon: {
              path: 'icons/folder.png'
            }
          }
        else
          raise "Unsupported entity type for collaboration: #{entity.class}"
        end
      end

      class Docs
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
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


      class Refs
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
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

      class Project
        include PluginSupport

        def self.option_parser
          OptionParser.new do |parser|
            parser.banner = 'Browse files in Alfred for a project'
            parser.separator 'Usage: files project <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to browse'
          end
        end

        def can_run?
          is_entity_present?(Entities::Project) && is_entity_manager_available?(Entities::Project)
        end

        def run(runner = Jxa::Runner.new('alfred'))
          project = @context.load_entity(Entities::Project)
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
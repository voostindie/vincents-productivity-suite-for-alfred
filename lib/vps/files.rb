module VPS
  module Files
    def self.read_area_configuration(area, hash)
      {
        path: hash['path'] || 'Projects',
      }
    end

    def self.commands_for(type, id)
      case type
      when :project
        {
          uid: 'browse',
          title: 'Browse project files in Alfred',
          arg: "file project #{id}",
          icon: {
            path: 'icons/folder.png'
          }
        }
      else
        raise "Unsupported type for collaboration: #{type}"
      end
    end

    class Browse
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Browse files in Alfred'
          parser.separator 'Usage: files browse'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled?(:files)
      end

      def run(arguments, environment, runner = Jxa::Runner.new('alfred'))
        area = @state.focus
        path = File.join(area[:root], area[:files][:path]) + '/'
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

      def can_run?(arguments, environment)
        is_plugin_enabled?(:files) && has_arguments?(arguments) && is_manager_available?(:project)
      end

      def run(arguments, environment, runner = Jxa::Runner.new('alfred'))
        project = manager_module(:project).details_for(arguments[0])
        area = @state.focus
        folder = strip_emojis(project['name'])
        path = File.join(area[:root], area[:files][:path], folder) + '/'
        runner.execute('browse', path)
        "Opened Alfred for directory '#{path}'"
      end
    end
  end
end
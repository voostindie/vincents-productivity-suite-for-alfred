module VPS
  module Bear

    def self.read_area_configuration(area, hash)
      {
        tags: hash['tags'] || []
      }
    end

    def self.commands_for(type, id)
      case type
      when :projects
        {
          uid: 'note',
          title: 'Create a note in Bear',
          arg: "bear project #{id}",
          icon: {
            path: "icons/bear.png"
          }
        }
      else
        raise "Unsupported type for collaboration: #{type}"
      end
    end

    class PlainNote
      include PluginSupport

      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Create a new, empty note, optionally with a title'
          parser.separator 'Usage: bear note [title]'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled? :bear
      end

      def run(arguments, environment, runner = Shell::SystemRunner.new)
        date = DateTime.now
        @context = {
          year: date.strftime('%Y'),
          month: date.strftime('%m'),
          week: date.strftime('%V'),
          day: date.strftime('%d'),
          title: arguments.join(' '),
        }
        title = ERB::Util.url_encode(@context[:title])
        tags = @state.focus[:bear][:tags]
                 .map { |t| merge_template(t) }
                 .map { |t| ERB::Util.url_encode(t) }
                 .join(',')
        callback = "bear://x-callback-url/create?title=#{title}&tags=#{tags}"
        runner.execute('open', callback)
        "Created a new note in Bear with title '#{title}'"
      end

      def merge_template(template)
        result = template.dup
        @context.each_pair do |key, value|
          result.gsub!('$' + key.to_s, value)
        end
        result
      end
    end

    class ProjectNote < PlainNote
      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Create a new note for a project'
          parser.separator 'Usage: bear project <projectId>'
          parser.separator ''
          parser.separator 'Where <projectId> is the ID of the project to create a note for'
        end
      end

      def can_run?(arguments, environment)
        if super(arguments, environment)
          is_manager_available? :projects
        else
          false
        end
      end

      def run(arguments, environment)
        project = manager_module.details_for(arguments[0])
        super([project['name']], environment)
      end
    end
  end
end

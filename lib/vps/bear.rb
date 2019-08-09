module VPS
  module Bear

    def self.read_area_configuration(area, hash)
      {
        tags: hash['tags'] || []
      }
    end

    def self.commands_for(type, id)
      case type
      when :project
        {
          uid: 'note',
          title: 'Create a note in Bear',
          arg: "note project #{id}",
          icon: {
            path: "icons/bear.png"
          }
        }
      when :contact
        {
          uid: 'note',
          title: 'Create a note in Bear',
          arg: "note contact #{id}",
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
          parser.separator 'Usage: note plain [title]'
        end
      end

      def can_run?(arguments, environment)
        is_plugin_enabled? :bear
      end

      def run(arguments, environment, runner = Shell::SystemRunner.new)
        context = create_context(arguments)
        title = ERB::Util.url_encode(context[:title])
        tags = create_tags(arguments)
                 .map { |t| merge_template(t, context) }
                 .map { |t| ERB::Util.url_encode(t) }
                 .join(',')
        callback = "bear://x-callback-url/create?title=#{title}&tags=#{tags}"
        runner.execute('open', callback)
        "Created a new note in Bear with title '#{title}'"
      end

      def create_context(arguments)
        date = DateTime.now
        context = {
          year: date.strftime('%Y'),
          month: date.strftime('%m'),
          week: date.strftime('%V'),
          day: date.strftime('%d'),
          title: create_title(arguments),
        }
      end

      def create_title(arguments)
        arguments.join(' ')
      end

      def create_tags(arguments)
        @state.focus[:bear][:tags]
      end

      def merge_template(template, context)
        result = template.dup
        context.each_pair do |key, value|
          result.gsub!('$' + key.to_s, value)
        end
        result
      end
    end

    class ProjectNote < PlainNote
      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Create a new note for a project'
          parser.separator 'Usage: note project <projectId>'
          parser.separator ''
          parser.separator 'Where <projectId> is the ID of the project to create a note for'
        end
      end

      def can_run?(arguments, environment)
        if super(arguments, environment)
          is_manager_available? :project
        else
          false
        end
      end

      def run(arguments, environment)
        project = manager_module(:project).details_for(arguments[0])
        super([project['name']], environment)
      end
    end

    class ContactNote < PlainNote
      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Create a new note for a contact'
          parser.separator 'Usage: note contact <contactId>'
          parser.separator ''
          parser.separator 'Where <contactId> is the ID of the contact to create a note for'
        end
      end

      def can_run?(arguments, environment)
        if super(arguments, environment)
          is_manager_available? :contact
        else
          false
        end
      end

      def run(arguments, environment)
        contact = manager_module(:contact).details_for(arguments[0])
        super(contact, environment)
      end

      def create_title(contact)
        contact['name']
      end

      def create_tags(contact)
        super(contact) << "#{@state.focus[:name]}/Contacts/#{contact['name']}"
      end
    end
  end
end

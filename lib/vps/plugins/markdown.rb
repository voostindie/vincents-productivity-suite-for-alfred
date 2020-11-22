module VPS
  module Plugins
    module Markdown
      include Plugin

      class MarkdownConfigurator < Configurator
        def process_area_configuration(area, hash)
          {
            level: force(hash['level'], Integer) || 2,
            link: hash['link'] || false
          }
        end
      end

      module MarkdownCommand
        def name
          'markdown'
        end

        def option_parser
          name = supported_entity_type.entity_type_name
          OptionParser.new do |parser|
            parser.banner = "Paste #{name} as Markdown to the frontmost app"
            parser.separator "Usage: #{name} markdown <#{name}Id}>"
            parser.separator ''
            parser.separator "Where <#{name}Id> is the ID of the #{name} to paste"
          end
        end

        def run(context, runner = JxaRunner.new('alfred'))
          entity = context.load_instance
          date = DateTime.now
          @template_context = {
            'year' => date.strftime('%Y'),
            'month' => date.strftime('%m'),
            'week' => date.strftime('%V'),
            'day' => date.strftime('%d'),
          }
          output = '#' * context.configuration[:level] + ' '
          output += title(context, entity)
          output += "\n"
          text = text(context, entity)
          output += "\n#{text}" unless text.nil?
          output += "\n"
          runner.execute('paste', output)
          "Pasted Markdown from #{supported_entity_type.entity_type_name}"
        end

        def link(context, text)
          if context.configuration[:link]
            "[[#{text}]]"
          else
            text
          end
        end
      end

      class Project < EntityInstanceCommand
        include MarkdownCommand

        def supported_entity_type
          EntityType::Project
        end

        def title(context, project)
          config = project.config['markdown'] || {}
          if config['title'].nil?
            link(context, project.name)
          else
            config['title'].render_template(@template_context)
          end
        end

        def text(context, project)
          config = project.config['markdown'] || {}
          unless config['text'].nil?
            config['text'].render_template(@template_context)
          end
        end
      end

      class Event < EntityInstanceCommand
        include MarkdownCommand

        def supported_entity_type
          EntityType::Event
        end

        def title(context, event)
          event.title
        end

        def text(context, event)
          people = event.people.map { |p| link(context, p) }.join(', ')
          "With #{people}." unless people.empty?
        end
      end
    end
  end
end
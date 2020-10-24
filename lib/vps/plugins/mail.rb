module VPS
  module Plugins
    module Mail
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          {
            from: force(hash['from'], String) || nil
          }
        end
      end

      class Contact < EntityInstanceCommand
        def name
          'mail'
        end

        def supported_entity_type
          EntityTypes::Contact
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Write an e-mail'
            parser.separator 'Usage: group mail <contactId>'
            parser.separator ''
            parser.separator 'Where <contactId> is the ID of the contact to write a mail to'
          end
        end

        def run(context, runner = Jxa::Runner.new('mail'))
          contact = context.load
          addresses = ["#{contact.name} <#{contact.email}>"].to_json
          from = context.configuration[:from]
          runner.execute('create-email', addresses, from)
          nil
        end
      end

      class Group < EntityInstanceCommand
        def name
          'mail'
        end

        def supported_entity_type
          EntityTypes::Group
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Write an e-mail'
            parser.separator 'Usage: group mail <groupId>'
            parser.separator ''
            parser.separator 'Where <groupId> is the ID of the group to write a mail to'
          end
        end

        def run(context, runner = Jxa::Runner.new('mail'))
          group = context.load
          addresses = group.people.map { |p| "#{p['name']} <#{p['email']}>" }.to_json
          from = context.configuration[:from]
          runner.execute('create-email', addresses, from)
          nil
        end
      end
    end
  end
end
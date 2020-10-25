module VPS
  module Plugins
    # Plugin for Apple Mail that adds a couple of commands to Contacts and Groups.
    #
    # Without the Contacts plugin, this plugin is pretty useless!
    module Mail
      include Plugin

      class MailConfigurator < Configurator
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
          EntityType::Contact
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Write an e-mail'
            parser.separator 'Usage: group mail <contactId>'
            parser.separator ''
            parser.separator 'Where <contactId> is the ID of the contact to write a mail to'
          end
        end

        def run(context, runner = JxaRunner.new('mail'))
          contact = context.load_instance
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
          EntityType::Group
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Write an e-mail'
            parser.separator 'Usage: group mail <groupId>'
            parser.separator ''
            parser.separator 'Where <groupId> is the ID of the group to write a mail to'
          end
        end

        def run(context, runner = JxaRunner.new('mail'))
          group = context.load_instance
          addresses = group.people.map { |p| "#{p['name']} <#{p['email']}>" }.to_json
          from = context.configuration[:from]
          runner.execute('create-email', addresses, from)
          nil
        end
      end
    end
  end
end
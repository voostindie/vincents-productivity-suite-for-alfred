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

      #
      # def self.commands_for(area, entity)
      #   if entity.is_a?(Types::Contact)
      #     {
      #       title: 'Write an e-mail in Mail',
      #       arg: "mail contact #{entity.id}",
      #       icon: {
      #         path: "icons/mail.png"
      #       }
      #     }
      #   elsif entity.is_a?(Types::Group)
      #     {
      #       title: 'Write an e-mail in Mail',
      #       arg: "mail group #{entity.id}",
      #       icon: {
      #         path: "icons/mail.png"
      #       }
      #     }
      #   else
      #     raise "Unsupported entity class for collaboration: #{entity.class}"
      #   end
      # end
      #
      # class Contact
      #   include PluginSupport
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'Prepare an email to the specified contact'
      #       parser.separator 'Usage: mail contact <contactId>'
      #       parser.separator ''
      #       parser.separator 'Where <contactId> is the ID of the contact to write a mail to'
      #     end
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Contact)
      #   end
      #
      #   def run(runner = Jxa::Runner.new('mail'))
      #     contact = Contacts::load_entity(@context)
      #     addresses = ["#{contact.name} <#{contact.email}>"].to_json
      #     from = @context.focus['mail'][:from]
      #     runner.execute('create-email', addresses, from)
      #     nil
      #   end
      # end
      #
      # class Group
      #   include PluginSupport
      #
      #   def self.option_parser
      #     OptionParser.new do |parser|
      #       parser.banner = 'Prepare an email to the specified group'
      #       parser.separator 'Usage: mail group <contactId>'
      #       parser.separator ''
      #       parser.separator 'Where <contactId> is the ID of the contact to write a mail to'
      #     end
      #   end
      #
      #   def can_run?
      #     is_entity_present?(Types::Group)
      #   end
      #
      #   def run(runner = Jxa::Runner.new('mail'))
      #     group = Groups::load_entity(@context)
      #     addresses = group.people.map {|p| "#{p['name']} <#{p['email']}>"}.to_json
      #     from = @context.focus['mail'][:from]
      #     runner.execute('create-email', addresses, from)
      #     nil
      #   end
      # end
    end
  end
end
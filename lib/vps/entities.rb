module VPS
  module Entities

    module EntitySupport

      # ...It should be possible to generate all code required for each entity here...
    end

    class Area
      include EntitySupport

      attr_reader :name

    end

    class Contact
      attr_accessor :id, :name, :email

      def initialize
        yield self
      end

      def self.from_hash(hash)
        Contact.new do |c|
          c.id = hash['id']
          c.name = hash['name']
          c.email = hash['email']
        end
      end

      def self.from_env(env)
        Contact.new do |c|
          c.id = env['CONTACT_ID']
          c.name = env['CONTACT_NAME']
          c.email = env['CONTACT_EMAIL']
        end
      end

      def to_env
        {
          CONTACT_ID: @id,
          CONTACT_NAME: @name,
          CONTACT_EMAIL: @email
        }
      end
    end

    class Project
      attr_accessor :id, :name

      def initialize
        yield self
      end

      def self.from_hash(hash)
         Project.new do |p|
          p.id = hash['id']
          p.name = hash['name']
        end
      end

      def self.from_env(env)
        Project.new do |p|
          p.id = env['PROJECT_ID']
          p.name = env['PROJECT_NAME']
        end
      end

      def to_env
        {
          PROJECT_ID: @id,
          PROJECT_NAME: @name
        }
      end

    end

    class File
      include EntitySupport

      attr_reader :path

    end

    class Event

      attr_accessor :id, :title, :people

      def initialize
        yield self
      end

      def self.from_env(env)
        Event.new do |e|
          e.id = env['EVENT_ID']
          e.title = env['EVENT_TITLE']
        end
      end

      def to_env
        {
          EVENT_ID: @id,
          EVENT_TITLE: @title
        }
      end

    end

    class Note
      include EntitySupport

      attr_reader :title
    end
  end
end
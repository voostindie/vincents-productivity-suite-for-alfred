module VPS
  ##
  # Defines all different type supported by VPS. A type is a concept like a contact,
  # a file, a project, an event.
  module Types

    ##
    # Base class for entities. All subclasses need to do is define +attr_accessor+s for
    # the fields they want to expose.
    class BaseType

      # Every entity has an ID.
      attr_accessor :id

      def self.type_name
        self.name.split('::').last.downcase
      end

      ##
      # Initialize a new entity. The pattern here is that you get an empty entity back
      # that you have to set the values for yourself.
      #
      #   contact = Contact.new |c| do
      #     c.id = 'id'
      #     c.name = 'Contact Name'
      #   end
      def initialize
        yield self
      end

      ##
      # Convert the entity to a hash with environment variables. Each instance variable
      # with a value is added.
      #
      # The names of the environment variables are based on the name of the entity class
      # and the name of the instance variable.
      #
      # E.g. +Contact.id+ becomes +CONTACT_ID+
      def to_env
        env = {}
        prefix = env_prefix
        self.instance_variables.each do |symbol|
          var = prefix + symbol[1..-1].to_s.upcase
          value = self.instance_variable_get(symbol)
          env[var] = value unless value.nil?
        end
        env
      end

      ##
      # Creates a new entity from the environment. This is the reverse of +to_env+.
      #
      # @param env the set of environment variables
      def self.from_env(env)
        entity = self.new do |entity|
          prefix = entity.env_prefix
          index = prefix.size
          env.select { |key, _| key.start_with?(prefix) }.each_pair do |key, value|
            variable = "@#{key[index..-1].downcase}".to_sym
            entity.instance_variable_set(variable, value)
          end
        end
        entity
      end

      ##
      # Creates a new entity from a hash. The keys in the hash must be strings, and
      # must be mappable to instance variables of the entity.
      #
      # E.g. the key +id+ maps to the instance variable +@id+
      def self.from_hash(hash)
        entity = self.new do |entity|
          hash.each_pair do |key, value|
            variable = "@#{key}".to_sym
            entity.instance_variable_set(variable, value)
          end
        end
        entity
      end

      ##
      # Helper method that returns the prefix for the entity class in the environment.
      # E.g. +VPS::Entities::Contact+ becomes +CONTACT_+.
      def env_prefix
        self.class.name.split('::').last.upcase + '_'
      end
    end

    ##
    # Represents a contact with a name and email address.
    class Contact < BaseType
      attr_accessor :name, :email
    end

    ##
    # Represents a project with a name
    class Project < BaseType
      attr_accessor :name, :note

      def config
        return {} if note.nil?
        yaml = note.
          gsub("\t", '  ').
          gsub("’", "'").
          gsub("“", '"').
          gsub("”", '"').
          lines.
          drop_while { |l| !l.start_with?('---') }.
          drop(1).
          join
        return {} if yaml.empty?
        YAML.load(yaml)
      end
    end

    ##
    # Represents an event with a title and people associated with it, like the organizer
    # and the attendees.
    class Event < BaseType
      attr_accessor :title, :people
    end

    ##
    # Represents a group of people.
    class Group < BaseType
      attr_accessor :name, :people
    end

    class Note < BaseType
      def self.from_id(id)
        Note.new do |note|
          note.id = id
        end
      end
    end

    # The entities below do nothing (yet); they exist only to make the code safer/better.

    class Area
    end

    class File
    end

    class Mail
    end

    class Text
    end
  end
end
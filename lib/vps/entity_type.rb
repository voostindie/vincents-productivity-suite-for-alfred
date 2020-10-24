module VPS
  # Defines all different entity types supported by VPS. An entity type is a concept like a contact,
  # a file, a project, an event.
  #
  # Instances of entities always have an ID, hence the {BaseType}. The actual entities might introduce
  # more.
  module EntityType

    # Base class for entities. All subclasses need to do is define +attr_accessor+s for
    # the fields they want to expose.
    # @abstract
    class BaseType

      # Every entity has an ID.
      attr_accessor :id

      def self.entity_type_name
        self.name.split('::').last.downcase
      end

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

      # Converts an instance to a hash with environment variables.
      #
      # The names of the environment variables are based on the name of the entity class
      # and the name of the instance variable.
      #
      # Use this method in your plugin to encode an instance in the output to Alfred, and
      # then, later in the workflow, use {BaseType.from_env} to decode it back. That can save you
      # a roundtrip to the backing application.
      #
      # E.g. +Contact.id+ becomes +CONTACT_ID+
      # @return [Hash]
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

      # Creates am instance from the environment. This is the reverse of {#to_env}
      #
      # @param env [Hash] the set of environment variables
      # @return [BaseType]
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

      # Creates a new entity from a hash. The keys in the hash must be strings, and
      # must be mappable to instance variables of the entity.
      #
      # E.g. the key +id+ maps to the instance variable +@id+
      # @param hash [Hash]
      # @return [BaseType]
      def self.from_hash(hash)
        entity = self.new do |entity|
          hash.each_pair do |key, value|
            variable = "@#{key}".to_sym
            entity.instance_variable_set(variable, value)
          end
        end
        entity
      end

      private

      # Helper method that returns the prefix for the entity class in the environment.
      # E.g. +VPS::Entities::Contact+ becomes +CONTACT_+.
      # @return [String]
      def env_prefix
        self.class.name.split('::').last.upcase + '_'
      end
    end

    # Represents a contact with a name and email address.
    class Contact < BaseType
      attr_accessor :name, :email
    end

    # Represents a project with a name and a note that might contain "YAML Back Matter"
    class Project < BaseType
      attr_accessor :name, :note

      # Read "YAML Back Matter" from the project note if present.
      # @return [Hash, nil]
      def config
        return {} if note.nil?
        yaml = note.
          lines.
          drop_while { |l| !l.start_with?('---') }.
          drop(1).
          join.
          gsub("\t", '  ').
          gsub("’", "'").
          gsub("“", '"').
          gsub("”", '"')
        return {} if yaml.empty?
        YAML.load(yaml)
      end
    end

    # Represents an event with a title and people associated with it, like the organizer
    # and the attendees.
    class Event < BaseType
      attr_accessor :title, :people
    end

    # Represents a group with a name and a list of people.
    class Group < BaseType
      attr_accessor :name, :people
    end

    # Represents a note.
    class Note < BaseType
      attr_accessor :path, :title, :text, :tags, :is_new
    end

    # Represents an area of responsibility in the system itself.
    class Area < BaseType
    end

    # Represents a file.
    class File < BaseType
    end
  end
end
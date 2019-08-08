##
# Re-implementation of the application configuration. Will replace existing
# Config class when the migration is complete.
#
# The goal of this class is to simplify, load plugins dynamically, and move
# plugin config code into the plugin itself. That should result in a more
# scalable solution (just look at the old Config class).
#
# I'm starting with the FocusPlugins
module VPS
  class NewConfig

    DEFAULT_CONFIG_FILE = File.join(Dir.home, '.vpsrc').freeze
    private_constant :DEFAULT_CONFIG_FILE

    ##
    # @return [Hash] All areas in the configuration
    attr_reader :areas

    ##
    # Creates a new configuration by reading both the configuration and state
    # (if available) from disk.
    def initialize(path = DEFAULT_CONFIG_FILE)
      raise "Can't read config file in '#{path}'" unless File.readable?(path)
      config = load_yaml(path, false)
      @areas = config['areas'] || {}
      @actions = config['actions'] || {}
      @state = load_yaml("#{path}.state", true)
    end

    ##
    # @return [Array<FocusPlugin>] an array of enabled +FocusPlugin+s; might be empty!
    def instantiate_actions
      actions = []
      FocusPlugin.plugins.each_pair do |name, clazz|
        if @actions.has_key? name
          actions << clazz.new(@actions[name] || {})
        end
      end
      actions
    end

    ##
    # Loads and parses YAML from disk
    #
    # @param path [String] Path to the file to load
    # @param allow_empty [Boolean] Whether or not a missing or empty file is allowed
    # @return [Hash] parsed from the YAML file
    # @raise RuntimeError if +allow_empty+ is +false+ and the file couldn't be found or read.
    def load_yaml(path, allow_empty)
      return {} if allow_empty && !File.exist?(path)
      raise "Can't read file in '#{path}'" unless File.readable?(path) || allow_empty
      begin
        yaml = YAML.load_file(path, fallback: allow_empty ? {} : false)
      rescue Psych::Exception => e
        raise "Can't read YAML in '#{path}': #{e}"
      end
      yaml
    end
  end
end
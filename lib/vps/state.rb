module VPS
  # Manages the persistent state of the application. This is just one thing: the currently focused area.
  class State

    # @return [String] the default file name of the state file: +`~/.vpsrc.state`+
    DEFAULT_FILE = (Configuration::DEFAULT_FILE + '.state').freeze

    # Loads the state from disk
    # @param path [String] location to load the state from.
    # @param configuration [Configuration] the full configuration
    # @return [State]
    def self.load(path, configuration)
      State.new(path, configuration)
    end

    # @return [Hash<String, Object>] the area with the current focus.
    attr_reader :focus

    ##
    # Creates a new state by loading it from disk
    # @param path [String] location to load the state from.
    # @param configuration [Configuration] the full configuration
    def initialize(path, configuration)
      @path = path
      settings = if File.readable?(path)
                   YAML.load_file(path)
                 else
                   {}
                 end
      area_name = settings[:area]
      change_focus(area_name, configuration)
    end

    # Changes the focus. If the specified area doesn't exist, the focus is set to nil.
    #
    # @param area_name [String] the name of the area to focus on
    # @param configuration [Configuration] the full configuration
    # @return [Hash<String, Object>] the area with the focus
    def change_focus(area_name, configuration)
      @focus = if area_name != nil && configuration.areas.has_key?(area_name)
                 configuration.areas[area_name]
               else
                 # This is a 'null' area, used when the focus is empty or invalid
                 {
                   key: 'null',
                   name: 'Null area. Please fix your configuration file!',
                   root: nil,
                   'area' => {}
                 }
               end
    end

    # Persists the current state to disk. It's persisted in the same location it was loaded from.
    #
    # @return [void]
    def persist
      settings = {
        area: @focus[:key]
      }
      File.open(@path, 'w') do |file|
        file.write settings.to_yaml
      end
    end
  end
end
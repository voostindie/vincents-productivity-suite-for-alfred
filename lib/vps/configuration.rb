module VPS
  class Configuration

    DEFAULT_FILE = File.join(Dir.home, '.vpsrc').freeze

    def self.load(path)
      unless File.readable?(path)
        $stderr.puts 'ERROR: cannot read configuration file'
        $stderr.puts
        $stderr.puts 'VPS requires a configuration file at ' #{path}'"
        raise 'Configuration file missing or unreadable'
      end
      Configuration.new(path)
    end

    def initialize(path)
      hash = YAML.load_file(path)
      extract_areas(hash)
      extract_actions(hash)
    end

    def include_area?(name)
      @areas.has_key? name
    end

    def area(name)
      @areas[name]
    end

    def areas
      @areas.values
    end

    def actions
      @actions
    end

    ##
    # Returns all managers of a certain type within an area
    def manager(area, type)
      Registry.managers(type).select { |key, _| area.has_key?(key) }.values[0]
    end

    ##
    # Returns all managers of all types within an area
    def available_managers(area)
      Registry.available_managers.select { |key, _| area.has_key?(key) }
    end

    ##
    # Returns all collaborators. Possible types are +:project+
    def collaborators(area, type)
      Registry.collaborators(type).select { |key, _| area.has_key?(key) }
    end

    private

    def extract_areas(hash)
      @areas = {}
      hash['areas'].each_pair do |key, config|
        config = config || {}
        name = config['name'] || key.capitalize
        root = if config['root']
                 File.expand_path(config['root'])
               else
                 File.join(Dir.home, name)
               end
        area = {
          key: key,
          name: name,
          root: root,
          area: {} # This plugin is hard-coded
        }
        types = [:area]
        config.each_pair do |plugin_key, plugin_config|
          plugin_sym = plugin_key.to_sym
          plugin = Registry::plugins[plugin_sym]
          if plugin.nil?
            if area[plugin_sym].nil?
              $stderr.puts "WARNING: no area plugin found for key '#{plugin_key}'. Please check your configuration!"
            end
            next
          end
          type = plugin[:manages]
          unless type.nil?
            if types.include? type
              $stderr.puts "WARNING: the area #{name} has multiple managers of type #{type.to_s}. Skipping plugin #{plugin_key}"
              next
            end
          end
          area[plugin_sym] = plugin[:module].read_area_configuration(area, plugin_config || {})
        end
        @areas[key] = area
      end
    end

    def extract_actions(hash)
      @actions = {}
      hash['actions'].each_pair do |name, config|
        config = config || {}
        key = name.to_sym
        plugin = Registry::plugins[key]
        if plugin.nil? || plugin[:action].nil?
          $stderr.puts "WARNING: no action plugin found for key '#{key}'. Please check your configuration!"
          next
        end
        @actions[key] = plugin[:module].read_action_configuration(config || {})
      end
    end
  end
end
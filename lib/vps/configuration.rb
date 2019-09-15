module VPS
  class Configuration

    attr_reader :registry

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
      @registry = Registry.new
      hash = YAML.load_file(path)
      extract_areas(hash)
      extract_actions(hash)
      freeze
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
    # Returns the manager for a specified entity name in an area
    def entity_manager_for(area, entity_name)
      @registry.entity_managers_for(entity_name).select do |plugin|
        area.has_key?(plugin.key)
      end.first
    end

    ##
    # Returns the manager for a specified entity name in an area
    def entity_manager_for_class(area, entity_class)
      entity_name = entity_class.name.split('::').last.downcase
      entity_manager_for(area, entity_name)
    end

    ##
    # Returns all entity managers that are enabled within an area
    def entity_managers(area)
      @registry.entity_managers.select do |plugin|
        area.has_key?(plugin.key)
      end
    end

    ##
    # Returns all collaborators. Possible types are +:project+
    def collaborators(area, entity_class)
      @registry.collaborators(entity_class).select do |plugin|
        area.has_key?(plugin.key)
      end
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
          root: root
        }.freeze
        # The area and paste plugins are added to every area, so that:
        # - these commands are always available
        # - no overriding configuration can be provided
        plugins = {}
        plugins['area'] = {}
        plugins['paste'] = {}
        entity_classes = [Entities::Area, Entities::Text]
        config.each_pair do |plugin_key, plugin_config|
          next if %w(key name root).include?(plugin_key)
          plugin = @registry.plugins[plugin_key]
          if plugin.nil?
            $stderr.puts "WARNING: no area plugin found for key '#{plugin_key}'. Please check your configuration!"
            next
          end
          entity_class = plugin.entity_class
          unless entity_class.nil?
            if entity_classes.include? entity_class
              $stderr.puts "WARNING: the area #{name} has multiple managers for entity class #{entity_class}. Skipping plugin #{plugin_key}"
              next
            end
          end
          plugins[plugin.key] = plugin.configurator.read_area_configuration(area, plugin_config || {}).freeze
        end
        @areas[key] = area.merge(plugins)
      end
      @areas.freeze
    end

    def extract_actions(hash)
      @actions = {}
      hash['actions'].each_pair do |key, config|
        plugin = @registry.plugins[key]
        if plugin.nil? || plugin.action_class.nil?
          $stderr.puts "WARNING: no action plugin found for key '#{key}'. Please check your configuration!"
          next
        end
        @actions[key] = plugin.configurator.read_action_configuration(config || {}).freeze
      end
      @actions.freeze
    end
  end
end
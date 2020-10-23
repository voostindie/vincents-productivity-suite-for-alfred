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
    # Return a list of available commands in the specified area, grouped by entity type.
    #
    def available_commands(area)
      plugins_for(area)
        .map { |plugin| plugin.repositories }
        .flatten
        .sort_by { |repository| repository.supported_entity_type.name }
        .map { |repository| [repository.supported_entity_type, commands_per_entity_type(area, repository.supported_entity_type)] }
        .reject { |_, commands| commands.empty? }
        .to_h
    end

    private

    def commands_per_entity_type(area, entity_type)
      plugins_for(area)
        .map { |plugin| plugin.commands }
        .flatten
        .sort_by { |command| command.name }
        .select { |command| command.supported_entity_type == entity_type }
    end

    def plugins_for(area)
      area
        .keys
        .reject { |key| key.is_a?(Symbol) }
        .filter_map { |name| Registry.instance.plugins[name] }
    end

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
        entity_types = [EntityTypes::Area, EntityTypes::Text]
        config.each_pair do |plugin_key, plugin_config|
          next if %w(key name root).include?(plugin_key)
          plugin = Registry.instance.plugins[plugin_key]
          if plugin.nil?
            $stderr.puts "WARNING: no area plugin found for key '#{plugin_key}'. Please check your configuration!"
            next
          end
          plugin.repositories.map { |r| r.supported_entity_type }.each do |entity_type|
            if entity_types.include? entity_type
              $stderr.puts "WARNING: the area #{name} has multiple repositories for type #{entity_type}. Skipping plugin #{plugin_key}"
              next
            end
            entity_types << entity_type
          end
          plugins[plugin.name] = plugin.configurator.process_area_configuration(area, plugin_config || {}).freeze
        end
        @areas[key] = area.merge(plugins)
      end
      @areas.freeze
    end

    def extract_actions(hash)
      @actions = {}
      (hash['actions'] || {}).each_pair do |key, config|
        plugin = Registry.instance.plugins[key]
        if plugin.nil? || plugin.action.nil?
          $stderr.puts "WARNING: no action plugin found for key '#{key}'. Please check your configuration!"
          next
        end
        @actions[key] = plugin.configurator.process_action_configuration(config || {}).freeze
      end
      @actions.freeze
    end
  end
end
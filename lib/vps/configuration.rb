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

    def supported_entity_types(area)
      plugins_for?(area)
        .map { |plugin| plugin.repositories }
        .flatten
        .map { |repository| repository.supported_entity_type }
    end

    def supported_commands(area, entity_type)
      plugins_for?(area)
        .map { |plugin| plugin.commands }
        .flatten
        .select { |command| command.supported_entity_type == entity_type }
    end

    def resolve_command(area, entity_type_name, command_name)
      plugins_for?(area)
        .map { |plugin| plugin.commands }
        .flatten
        .select { |command| command.name == command_name && command.supported_entity_type.entity_type_name == entity_type_name }
        .first
    end

    def command_config(area, command)
      area[@registry.plugin_for_command?(command).name]
    end

    def repository_for_entity_type(area, entity_type)
      plugins_for?(area)
        .map { |plugin| plugin.repositories }
        .flatten
        .select { |repository| repository.supported_entity_type == entity_type }
        .first
    end

    private

    def plugins_for?(area)
      area.keys
        .filter_map { |name| @registry.plugins[name] }
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
          plugin = @registry.plugins[plugin_key]
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
        plugin = @registry.plugins[key]
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
module VPS
  # Reads the configuration from file and turns into a set of areas and their commands, fully configured.
  #
  # To decouple the configuration from the plugin systems, VPS uses a {VPS::Plugin::Configurator} per plugin,
  # which gets passed the Ruby hash parsed from the YAML configuration file for that plugin. The output of
  # that process is then kept in here, in memory.
  class Configuration
    ROOT = File.join(Dir.home, '.vps')

    # @return [String] default location of the configuration file: +~/.vps/config.yaml+
    DEFAULT_FILE = File.join(ROOT, 'config.yaml').freeze

    # The configuration of the individual areas, keyed on the plugin name, as well as 3 other
    # values, keyed on symbol: +:key+, +:name+ and +:root+
    #
    # @return [Hash<String, Hash<String, Object>>]
    attr_reader :areas

    # The configuration of the individual actions, keyed on the plugin name.
    # @return [Hash<String, Hash<String, Object>>]
    attr_reader :actions

    # Loads the configuration from disk.
    # @return [Configuration]
    def self.load(path)
      unless File.readable?(path)
        warn 'ERROR: cannot read configuration file'
        warn
        warn "VPS requires a configuration file at '#{path}'"
        raise 'Configuration file missing or unreadable'
      end
      Configuration.new(path)
    end

    # @param path [String] file to read as configuration
    def initialize(path)
      hash = YAML.load_file(path)
      extract_areas(hash)
      extract_actions(hash)
      freeze
    end

    ##
    # Returns a list of available commands in the specified area, grouped by entity type.
    #
    # @param area Hash<String, Object>
    # @return [Hash<VPS::Plugin::Repository, Array<VPS::Plugin::Command>]
    def available_commands(area)
      plugins_for(area)
        .map(&:repositories)
        .flatten
        .sort_by { |r| r.supported_entity_type.name }
        .map { |r| [r.supported_entity_type, commands_per_entity_type(area, r.supported_entity_type)] }
        .reject { |_, commands| commands.empty? }
        .to_h
    end

    def plugins_for(area)
      area
        .keys
        .reject { |key| key.is_a?(Symbol) }
        .filter_map { |name| Registry.instance.plugins[name] }
    end

    private

    def commands_per_entity_type(area, entity_type)
      plugins_for(area)
        .map(&:commands)
        .flatten
        .sort_by(&:name)
        .select { |command| command.supported_entity_type == entity_type }
    end

    def extract_areas(hash)
      @areas = {}
      hash['areas'].each_pair do |key, config|
        config ||= {}
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
        entity_types = [EntityType::Area]
        config.each_pair do |plugin_key, plugin_config|
          next if %w[key name root].include?(plugin_key)

          plugin = Registry.instance.plugins[plugin_key]
          if plugin.nil?
            warn "WARNING: no area plugin found for key '#{plugin_key}'. Please check your configuration!"
            next
          end
          plugin.repositories.map(&:supported_entity_type).each do |entity_type|
            if entity_types.include? entity_type
              warn "WARNING: area #{name} has multiple repositories for #{entity_type}s. Skipping plugin #{plugin_key}"
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
      @actions['alfred'] = Registry.instance.plugins['alfred'].configurator.process_action_configuration({}).freeze
      (hash['actions'] || {}).each_pair do |key, config|
        plugin = Registry.instance.plugins[key]
        if plugin.nil? || plugin.action.nil?
          warn "WARNING: no action plugin found for key '#{key}'. Please check your configuration!"
          next
        end
        @actions[key] = plugin.configurator.process_action_configuration(config || {}).freeze
      end
      @actions.freeze
    end
  end
end

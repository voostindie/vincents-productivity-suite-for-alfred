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

    def supported_types(area)
      area.keys
        .filter_map { |name| @registry.plugins[name] }
        .map { |plugin| plugin.repositories }
        .flatten
        .map { |repository| repository.type? }
    end

    def supported_commands(area, type)
      area.keys
        .filter_map { |name| @registry.plugins[name] }
        .map { |plugin| plugin.commands }
        .flatten
        .select { |command| command.acts_on_type? == type }
    end

    def resolve_command(area, type_name, command_name)
      area.keys
        .filter_map { |name| @registry.plugins[name] }
        .map { |plugin| plugin.commands }
        .flatten
        .select { |command| command.name == command_name && command.acts_on_type?.type_name == type_name }
        .first
    end

    def command_config(area, command)
      area[@registry.command_plugin(command).name]
    end

    def repository_for_type(area, type)
      area.keys
        .filter_map { |name| @registry.plugins[name] }
        .map { |plugin| plugin.repositories }
        .flatten
        .select { |repository| repository.type? == type }
        .first
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
        types = [Types::Area, Types::Text]
        config.each_pair do |plugin_key, plugin_config|
          next if %w(key name root).include?(plugin_key)
          plugin = @registry.plugins[plugin_key]
          if plugin.nil?
            $stderr.puts "WARNING: no area plugin found for key '#{plugin_key}'. Please check your configuration!"
            next
          end
          plugin.repositories.map { |r| r.type? }.each do |type|
            if types.include? type
              $stderr.puts "WARNING: the area #{name} has multiple repositories for type #{type}. Skipping plugin #{plugin_key}"
              next
            end
            types << type
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
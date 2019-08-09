module VPS
  class Configuration

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
      @areas = {}
      hash['areas'].each_pair do |key, config|
        next unless config.is_a?(Hash)
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
        }
        config.each_pair do |plugin_key, plugin_config|
          plugin = Registry::plugins[plugin_key.to_sym]
          if plugin.nil?
            $stderr.puts "WARNING: no plugin found for key '#{plugin_key}'. Please check your configuration!"
          else
            area[plugin_key.to_sym] = plugin[:module].read_configuration(area, plugin_config)
          end
        end
        @areas[key] = area
      end
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
  end
end
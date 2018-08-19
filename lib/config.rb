require 'yaml'

class Config

  DEFAULT_CONFIG_FILE= File.join(Dir.home, '.vpsrc').freeze

  def self.load(path = DEFAULT_CONFIG_FILE)
    raise "Couldn't read config from '#{path}'" unless File.readable?(path)
    config = YAML.load_file(path)
    file = state_file(path)
    state = if File.readable?(file)
              YAML.load_file(file)
            else
              {}
            end
    Config.new(config, state)
  end

  def self.save_state(config, path = DEFAULT_CONFIG_FILE)
    File.open(state_file(path), 'w') do |file|
      file.write config.state.to_yaml
    end
  end

  def self.delete_state(path = DEFAULT_CONFIG_FILE)
    file = state_file(path)
    File.delete(file) if File.exist?(file)
  end

  def areas
    @areas.keys.sort
  end

  def area(name)
    @areas[name]
  end

  def focused_area
    raise "No valid area is active" unless @state[:area] && @areas.include?(@state[:area])
    @areas[@state[:area]]
  end

  def focus(name)
    raise "Unknown area '#{name}'" unless @areas.include?(name)
    @state[:area] = name
  end

  def state
    @state
  end

  def self.state_file(path)
    "#{path}.state"
  end

  private

  def initialize(config_hash, state_hash)
    @areas = extract_areas(config_hash)
    @state = state_hash
  end

  def extract_areas(yaml)
    areas = {}
    yaml['areas'].each_pair do |key, area|
      area = area || {}
      name = area['name'] || key.capitalize
      root = if area['root']
               File.expand_path(area['root'])
             else
               File.join(Dir.home, name)
             end
      areas[key] = {
          key: key,
          name: name,
          root: root
      }
      if area.has_key?('markdown-notes')
        notes = area['markdown-notes'] || {}
        areas[key][:markdown_notes] = {
          path: notes['path'] || 'Notes',
          extension: notes['extension'] || 'md',
          name_template: notes['name-template'] || '$year-$month-$day-$slug',
          file_template: notes['file-template'] || <<EOT
---
date: $day-$month-$year
---
# $title

EOT
        }
      end
    end
    areas
  end
end

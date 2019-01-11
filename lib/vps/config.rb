class Config

  DEFAULT_CONFIG_FILE = File.join(Dir.home, '.vpsrc').freeze

  def self.load(path = DEFAULT_CONFIG_FILE)
    raise "Couldn't read config from '#{path}'" unless File.readable?(path)
    config = YAML.load_file(path)
    file = state_file(path)
    state = if File.readable?(file)
              YAML.load_file(file)
            else
              {}
            end
    Config.new(path, config, state)
  end

  def areas
    @areas.keys.sort
  end

  def area(name)
    @areas[name]
  end

  def focused_area
    return {} unless @state[:area] && @areas.include?(@state[:area])
    @areas[@state[:area]]
  end

  def focus(name)
    raise "Unknown area '#{name}'" unless @areas.include?(name)
    @state[:area] = name
    focused_area
  end

  def save
    File.open(Config.state_file(@path), 'w') do |file|
      file.write @state.to_yaml
    end
  end

  def actions
    @actions.keys
  end

  def action(key)
    @actions[key]
  end

  def state
    @state
  end

  def self.state_file(path)
    "#{path}.state"
  end

  private

  def initialize(path, config_hash, state_hash)
    @path = path
    @areas = extract_areas(config_hash)
    @actions = extract_actions(config_hash)
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
          editor: notes['editor'] || 'open',
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
      if area.has_key?('omnifocus')
        omnifocus = area['omnifocus'] || {}
        areas[key][:omnifocus] = {
          folder: omnifocus['folder'] || name
        }
      end
      if area.has_key?('contacts')
        contacts = area['contacts'] || {}
        mail = contacts['mail'] || {}
        areas[key][:contacts] = {
          group: contacts['group'] || name,
          mail: {
            client: mail['client'] || 'Mail',
            from: mail['from'] || nil
          }
        }
      end
      if area.has_key?('project-files')
        files = area['project-files'] || {}
        areas[key][:project_files] = {
          path: files['path'] || 'Projects',
          documents: files['documents'] || 'Documents',
          reference: files['reference'] || 'Reference Material'
        }
      end
      if area.has_key?('wallpaper')
        wallpaper = area['wallpaper'] || {}
        areas[key][:wallpaper] = {
          path: wallpaper['path'] || nil
        }
      end
    end
    areas
  end

  def extract_actions(yaml)
    return {} unless yaml.has_key?('actions')
    actions = {}
    yaml['actions'].each_pair do |key, config|
      config = config || {}
      case key
      when 'wallpaper'
        actions[:wallpaper] = {}
        actions[:wallpaper][:default] = config['default'] || '/Library/Desktop Pictures/High Sierra.jpg'
      when 'bitbar'
        actions[:bitbar] = {}
        actions[:bitbar][:plugin] = config['plugin'] || 'focused-area.1d.rb'
      when 'omnifocus'
        actions[:omnifocus] = {}
      else
        # Unknown key, we'll just ignore it.
      end
    end
    actions
  end
end

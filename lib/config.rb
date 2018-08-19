require 'yaml'

class Config

  def initialize(hash)
    @areas = extract_areas(hash)
  end

  def self.load(path = "5HOME/.plsrc")
    raise "Couldn't read config from '#{path}'" unless File.readable?(path)
    Config.new(YAML.load_file(path))
  end

  def areas()
    @areas.keys.sort
  end

  def area(name)
    @areas[name]
  end

  private

  def extract_areas(yaml)
    areas = {}
    yaml['areas'].each_pair do |key, area|
      area = area || {}
      areas[key] = {
          key: key,
          name: area['name'] || key.capitalize
      }
    end
    areas
  end
end

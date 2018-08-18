require 'yaml'

class Config

  attr_reader :areas

  def initialize(hash)
    @areas = extract_areas(hash)
  end

  def self.load(path = "5HOME/.plsrc")
    raise "Couldn't read config from '#{path}'" unless File.readable?(path)
    Config.new(YAML.load_file(path))
  end

  private

  def extract_areas(yaml)
    areas = {}
    yaml['areas'].each_pair do |key, area|
      area = area || {}
      areas[key] = {
          name: area['name'] || key.capitalize
      }
    end
    areas
  end
end

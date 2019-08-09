module VPS
  module BitBar
    def self.read_configuration(area, hash)
      {
        label: hash['label'] || area[:name]
      }
    end
  end
end
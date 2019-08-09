module VPS
  ##
  # Manages the persistent state of the application. This is just one thing: the currently
  # focused area.
  class State
    def self.load(path, configuration)
      State.new(path, configuration)
    end

    attr_reader :focus

    def initialize(path, configuration)
      @path = path
      settings = if File.readable?(path)
                   YAML.load_file(path)
                 else
                   {}
                 end
      area = settings[:area]
      change_focus(area, configuration) unless area.nil?
    end

    def change_focus(area, configuration)
      @focus = if configuration.include_area?(area)
                 configuration.area(area)
               else
                 nil
               end
    end

  end
end
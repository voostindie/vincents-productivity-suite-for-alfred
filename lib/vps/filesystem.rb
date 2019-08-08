module VPS
  module FileSystem

    # This is a really ugly way to stub out filesystem access,
    # just to simplify testing. But hey, it works. For now.
    @@stub = false

    def self.enable_testing
      @@stub = true
    end

    def self.safe_filename(name)
      name.gsub(/[\t\n"',;\.!@#\$%\^&*]/, '').gsub(/\//, '-').gsub(/  /, ' ')
    end

    def self.exists?(file)
      if @@stub
        true
      else
        File.exist?(file)
      end
    end
  end
end
module VPS

  module Console

    def self.format
      result = yield
      if result.is_a? Array
        output = result.map do |entry|
          "- #{entry[:uid].ljust(14)}: #{entry[:title]}"
        end
        puts output
      else
        puts result
      end
    end
  end
end

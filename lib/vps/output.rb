##
# Helper methods for massaging output in a format that Alfred likes.
#
# @see https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
#   Alfred's Script Filter JSON Format
module VPS
  module Output
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

    module Alfred
      ##
      # Run a block, capture its output and formats it for Alfred.
      # @param type [Symbol] the type of output: `:single` or `:list`
      # @param block The block to run.
      def self.format
        result = yield
        if result.is_a? Array
          output = {
            items: result
          }
          puts output.to_json
        else
          puts result
        end
      end
    end
  end
end

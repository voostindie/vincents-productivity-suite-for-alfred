module VPS
  ##
  # Formats output depending on the "display": the console or Alfred.
  #
  # The idea is this: you have code that produces the result to output, either
  # - a single string
  # - an array of hashes in Alfred's workflow format (see below)
  #
  # Depending on the display, the output needs to be formatted differently. E.g. you
  # probably don't want a big JSON string on the console. But Alfred loves it.
  # So, you do this:
  #
  #   formatter = OutputFormatter::Console # console output
  #   output = formatter {
  #     # Code that produces output here
  #   }
  #   puts output
  #
  # Just replace Console with Alfred and Bob's your uncle.
  #
  # == Alfred's JSON format
  #
  # On the Alfred JSON format: this tool is meant to be used within an Alfred workflow
  # first. And on the command line second. So I've decided to follow Alfred's JSON
  # format internally. It's the easiest thing to do. If, some day, I decide to support
  # other launchers besides Alfred, I might change the internal format to something more
  # generic, and then have the Alfred formatter do the final mapping for Alfred. We'll see.
  #
  # See https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
  module OutputFormatter
    ##
    # Formatter for console output
    module Console
      ##
      # Runs a block, captures its output, formats it for the console and returns it.
      def self.format
        result = yield
        if result.is_a? Array
          id = if result.size > 0 && result[0][:uid].nil?
                 :arg
               else
                 :uid
               end
          width = result.map { |entry| entry[id].size}.max
          result.map do |entry|
            "- #{entry[id].ljust(width)}: #{entry[:title]}"
          end.join("\n")
        else
          result
        end
      end
    end

    ##
    # Formatter for Alfred output
    module Alfred
      ##
      # Runs a block, captures its output, formats it for Alfred and returns it.
      def self.format
        result = yield
        if result.is_a? Array
          output = {
            items: result
          }
          output.to_json
        else
          result
        end
      end
    end
  end
end

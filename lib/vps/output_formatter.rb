module VPS
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
  #   print format(output)
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
    # Formatter for console output
    module Console
      # @param output [StringArray,nil] output to format for the console
      # @return [String]
      def self.format(output)
        if output.is_a?(Array)
          id = if !output.empty? && output[0][:uid].nil?
                 :arg
               else
                 :uid
               end
          width = output.map { |entry| entry[id].size }.max
          output.map do |entry|
            if entry[id] == entry[:title]
              "- #{entry[id]}"
            else
              "- #{entry[id].ljust(width)}: #{entry[:title]}"
            end
          end.join("\n") + "\n"
        elsif !output.nil?
          output
        else
          ''
        end
      end
    end

    # Formatter for Alfred output
    module Alfred
      # @param output [String,Array,nil] output to format for Alfred
      # @return [String]
      def self.format(output)
        if output.is_a? Array
          output = {
            items: output
          }
          output.to_json
        elsif !output.nil?
          output
        else
          ''
        end
      end
    end
  end
end

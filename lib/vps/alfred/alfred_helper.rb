##
# Helper methods for massaging output in a format that Alfred likes.
#
# @see https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
#   Alfred's Script Filter JSON Format
module Alfred

  ##
  # Performs a block whose output is a single String, to be used as output
  # from an Alfred action. This output is sent to standard out as is.
  #
  # In case of an error, the error message itself is sent to standard output.
  #
  # @yieldreturn [String] Output of the block in a single line.
  def self.action
    puts yield
  rescue RuntimeError => e
    puts "Error: #{e}"
  end

  ##
  # Performs a block whose output is a list of items, to be used as input
  # for an Alfred Script Filter. The output of the block is wrapped inside
  # an Alfred result list.
  #
  # In case of an error, the error message is wrapped in a single, un-actionable
  # item, which is then sent to standard output.
  #
  # @yieldreturn [JSON] an array of items to be sent to the output. Each item must
  #   be a valid according to the Script Filter JSON Format.
  def self.filter
    puts_items(yield)
  rescue RuntimeError => e
    puts_exception_as_items(e)
  end

  private

  def self.puts_items(items)
    result = {
      items: items
    }
    puts result.to_json
  end

  def self.puts_exception_as_items(exception)
    result = {
      items: [
        {
          title: "Error: #{exception}",
          valid: false
        }
      ]
    }
    puts result.to_json
  end
end

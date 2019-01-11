# For Alfred's Script Filter JSON Format, see:
# https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
module Alfred

  # Perform a block whose output is a single String,
  # to be used as output from an Alfred action.
  def self.action
    puts yield
  rescue RuntimeError => e
    puts "Error: #{e}"
  end

  # Perform a block whose output is a list of items,
  # to be used as input for an Alfred Script Filter.
  def self.filter
    puts_items(yield)
  rescue RuntimeError => e
    puts_exception_as_items(e)
  end

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
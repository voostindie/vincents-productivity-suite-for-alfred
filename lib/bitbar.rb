require_relative 'config'
require_relative 'system'

class BitBar

  def initialize(runner = System::Runner.new)
    @runner = runner
  end

  def change(area, defaults)
    @runner.execute("open -g bitbar://refreshPlugin?name=#{defaults[:plugin]}")
  end

end
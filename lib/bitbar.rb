require_relative 'config'
require_relative 'shell'

class BitBar

  def initialize(runner = Shell::SystemRunner.new)
    @runner = runner
  end

  def change(area, defaults)
    @runner.execute("open -g bitbar://refreshPlugin?name=#{defaults[:plugin]}")
  end

end
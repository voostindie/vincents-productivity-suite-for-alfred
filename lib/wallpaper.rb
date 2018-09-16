require_relative 'config'
require_relative 'jxa'

class Wallpaper

  def initialize(runner = Jxa::Runner.new)
    @runner = runner
  end

  def change(area, defaults)
    wallpaper = area[:wallpaper] || {}
    path = wallpaper[:path] || defaults[:default]
    @runner.execute('wallpaper-change', path)
  end

end
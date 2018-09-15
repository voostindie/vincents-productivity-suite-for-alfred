require_relative 'jxa'

module Wallpaper

  def self.change(area, runner: Jxa::Runner.new)
    wallpaper = area[:wallpaper]
    return if wallpaper.nil?
    path = wallpaper[:path]
    unless path.nil?
      runner.execute('wallpaper-change', path)
    end
  end

end
##
# Changes the desktop wallpaper.
#
# The wallpaper to change to must be configured in the +wallpaper+ section of
# the area, in the single +path+ property. If no wallpaper is defined, the
# plugin will fallback on a global default.
#
# == Configuration sample
#
#   areas:
#     myarea:
#       wallpaper:
#         path: '/path/to/my/special/wallpaper.jpg'
#   actions:
#     wallpaper:
#       default: '/Library/Desktop Pictures/High Sierra.jpg' # default value, can be omitted
#
class WallpaperPlugin < FocusPlugin

  def initialize(runner = Jxa::Runner.new(__FILE__))
    @runner = runner
  end

  ##
  # Changes the desktop wallpaper. It does so by invoking a JXA script.
  def focus_changed(area, defaults)
    wallpaper = area[:wallpaper] || {}
    path = wallpaper[:path] || defaults[:default]
    @runner.execute('change-wallpaper', path)
  end

end
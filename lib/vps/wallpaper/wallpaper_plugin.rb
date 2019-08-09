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
module VPS
  class WallpaperPlugin < FocusPlugin

    def initialize(defaults = {}, runner: Jxa::Runner.new('wallpaper'))
      @default_wallpaper = defaults['path'] || '/Library/Desktop Pictures/High Sierra.jpg'
      @runner = runner
    end

    ##
    # Changes the desktop wallpaper. It does so by invoking a JXA script.
    def focus_changed(area, old_area_config)
      wallpaper = area['wallpaper'] || {}
      path = wallpaper['path'] || @default_wallpaper
      @runner.execute('change-wallpaper', path)
    end
  end
end
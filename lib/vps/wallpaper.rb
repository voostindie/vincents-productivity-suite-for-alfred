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
  module Wallpaper

    def self.read_area_configuration(area, hash)
      if hash['path'].nil?
        {}
      else
        {
          path: hash['path']
        }
      end
    end

    def self.read_action_configuration(hash)
      {
        path: hash['path'] || '/Library/Desktop Pictures/High Sierra.jpg'
      }
    end

    class Replace
      include PluginSupport

      def run(environment, runner = Jxa::Runner.new('wallpaper'))
        path = if @state.focus[:wallpaper]
                 @state.focus[:wallpaper][:path]
               else
                 nil
               end || @configuration.actions[:wallpaper][:path]
        runner.execute('change-wallpaper', path)
      end
    end
  end
end
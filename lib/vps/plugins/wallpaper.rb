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
  module Plugins
    module Wallpaper
      include Plugin

      class Configurator < BaseConfigurator
        def process_area_configuration(area, hash)
          if hash['path'].nil?
            {}
          else
            {
              path: force(hash['path'], String)
            }
          end
        end

        def process_action_configuration(hash)
          {
            path: force(hash['path'], String) || '/Library/Desktop Pictures/Frog.jpg'
          }
        end
      end

      class Wallpaper < BaseAction
        def run(context, runner = Jxa::Runner.new('wallpaper'))
          path = if context.area['wallpaper']
                   context.area['wallpaper'][:path]
                 else
                   nil
                 end || context.configuration.actions['wallpaper'][:path]
          runner.execute('change-wallpaper', path)
        end
      end
    end
  end
end
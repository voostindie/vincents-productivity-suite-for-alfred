module VPS
  module Plugins
    # Plugin that changes the desktop wallpaper when the focus changes.
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
    module Wallpaper
      include Plugin

      # Configures the Wallpaper plugin
      class WallpaperConfigurator < Configurator
        def process_area_configuration(_area, hash)
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

      # Action that changes the wallpaper whenever the focus changes.
      class Wallpaper < Action
        def run(context, runner = JxaRunner.new('wallpaper'))
          path = if context.area['wallpaper']
                   context.area['wallpaper'][:path]
                 end || context.configuration.actions['wallpaper'][:path]
          runner.execute('change-wallpaper', path)
        end
      end
    end
  end
end

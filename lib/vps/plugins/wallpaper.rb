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

        def run(runner = Jxa::Runner.new('wallpaper'))
          path = if @context.focus['wallpaper']
                   @context.focus['wallpaper'][:path]
                 else
                   nil
                 end || @context.configuration.actions['wallpaper'][:path]
          runner.execute('change-wallpaper', path)
        end
      end

      def self.configure_plugin(plugin)
        plugin.with_action(Replace)
      end
    end
  end
end
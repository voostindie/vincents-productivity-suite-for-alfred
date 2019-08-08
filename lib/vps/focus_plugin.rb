##
# Base class for plugins that can be triggered when the focus changes.
#
# When the focus changes, each FocusPlugin that is enabled in the configuration
# is instantiated, after which the {#focus_changed} method is called.
#
# @abstract
module VPS
  class FocusPlugin

    def initialize(defaults = {})

    end

    ##
    # Called when the focus has changed. A plugin can do anything it wants, except
    # raise an error. All plugins are executed sequentially, in the order they are
    # defined in the user's configuration file. If a plugin raises an error, the
    # whole program stops. So don't do that.
    #
    # @param area [Hash] the configuration of the activated area.
    def focus_changed(area, old_area_config)
      raise "TODO: override this method!"
    end

    def self.plugins
      @@plugins
    end

    private

    @@plugins = {}

    def self.inherited(plugin)
      key = plugin.name.gsub(/^VPS\:\:/, '').downcase.gsub(/plugin$/, '')
      @@plugins[key] = plugin
    end
  end
end
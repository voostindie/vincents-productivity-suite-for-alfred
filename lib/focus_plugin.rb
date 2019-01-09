##
# Base class for plugins that can be triggered when the focus changes.
#
# When the focus changes, each FocusPlugin that is enabled in the configuration
# is instantiated, after which the {#focus_changed} method is called.
#
# @abstract
class FocusPlugin

  ##
  # Called when the focus has changed. A plugin can do anything it wants, except
  # raise an error. All plugins are executed sequentially, in the order they are
  # defined in the user's configuration file. If a plugin raises an error, the
  # whole program stops. So don't do that.
  #
  # @param area [Hash] the configuration of the activated area.
  # @param defaults [Hash] the default configuration for this plugin
  def focus_changed(area, defaults)
    raise "TODO: override this method!"
  end
end
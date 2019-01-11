##
# Triggers BitBar to refresh the bundled +focused-area.1d.rb+ plugin.
#
# The configuration supports a single property +plugin+, which can be set
# to the name of the plugin in BitBar. This is needed only if it was renamed
# while symlinking. (See the +focused-area.1d.rb+ script for more info.)
#
# == Configuration sample
#
#   actions:
#     bitbar:
#       plugin: 'focused-area.1d.rb' # default value, can be omitted
#
class BitBarPlugin < FocusPlugin

  def initialize(runner = Shell::SystemRunner.new)
    @runner = runner
  end

  ##
  # Triggers the URL callback for BitBar to refresh our "focused-area" plugin.
  def focus_changed(area, defaults)
    @runner.execute("open -g bitbar://refreshPlugin?name=#{defaults[:plugin]}")
  end

end
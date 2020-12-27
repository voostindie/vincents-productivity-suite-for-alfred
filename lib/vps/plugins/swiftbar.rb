module VPS
  module Plugins
    # Action plugin to trigger SwiftBar when the focus changes.
    #
    # Note: to set labels, use the +bitbar+ plugin! All this plugin does
    # is call SwiftBar's +refreshplugin+ URL scheme.
    module SwiftBar
      include Plugin

      # Configures the SwiftBar plugin.
      class SwiftBarConfigurator < Configurator
        def process_action_configuration(hash)
          {
            plugin: force(hash['plugin'], String) || 'focused-area'
          }
        end
      end

      # Action to refresh SwiftBar whenever the focus changes.
      class Refresh < Action
        def run(context, runner = Shell::SystemRunner.instance)
          plugin = context.configuration.actions['swiftbar'][:plugin]
          runner.execute("open -g swiftbar://refreshplugin?name=#{plugin}")
        end
      end
    end
  end
end

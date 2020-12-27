module VPS
  module Plugins
    # Action plugin to refresh certain GeekTool geeklets after changing the focus.
    #
    # Configuration:
    #
    #   actions:
    #     geektool:
    #       geeklets:
    #         - <name>
    #
    module GeekTool
      include Plugin

      # Configures the GeekTool plugin.
      class GeekToolConfiguration < Configurator
        def process_action_configuration(hash)
          {
            geeklets: force_array(hash['geeklets'], String) || []
          }
        end
      end

      # Action to refresh geeklets in GeekTool when the focus changes.
      class Refresh < Action
        def run(context, runner = JxaRunner.new('geektool'))
          geeklets = context.configuration.actions['geektool'][:geeklets]
          runner.execute('refresh', geeklets.to_json)
        end
      end
    end
  end
end

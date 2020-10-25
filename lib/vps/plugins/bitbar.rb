module VPS
  module Plugins
    ##
    # Action plugin to set a label in BitBar for the focused area whenever the focus changes.
    #
    # The label to show must be set in the +bitbar+ section of the area configuration.
    # It defaults to the name of the area. Tip: use emoji's as labels. They show up like icons.
    #
    # The BitBar action itself can be configured with the name of the plugin that must be refreshed
    # by BitBar. By default this is +focused-area.1d.rb+, which is the name of the plugin as it
    # exists in this application.
    #
    # == Minimal configuration
    #
    #   actions:
    #     bitbar:
    #
    # This will set the label in BitBar to the name of each area.
    #
    # == Extended configuration sample
    #
    #   areas:
    #     myarea:
    #       bitbar:
    #         label: '👍'
    #   actions:
    #     bitbar:
    #       plugin: 'focus.1d.rb'
    #
    # This triggers the plugin +focus.1d.rb+ whenever the focus changes. The label for the
    # area +myarea+ is set to a thumbs up.
    #
    module BitBar
      include Plugin

      ##
      # Returns the label for the currently focused area.
      # This method is called by the `focused-area.1d.rb` BitBar plugin.
      def self.label(config_file = Configuration::DEFAULT_FILE, state_file = State::DEFAULT_FILE)
        configuration = VPS::Configuration::load(config_file)
        state = VPS::State::load(state_file, configuration)
        state.focus['bitbar'][:label]
      end

      class BitBarConfigurator < Configurator
        def process_area_configuration(area, hash)
          {
            label: force(hash['label'], String) || area[:name]
          }
        end

        def process_action_configuration(hash)
          {
            plugin: force(hash['plugin'], String) || 'focused-area.1d.rb'
          }
        end
      end

      class Refresh < Action
        def run(context, runner = Shell::SystemRunner.instance)
          plugin = context.configuration.actions['bitbar'][:plugin]
          runner.execute("open -g bitbar://refreshPlugin?name=#{plugin}")
        end
      end
    end
  end
end
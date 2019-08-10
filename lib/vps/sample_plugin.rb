module VPS
  ##
  # An example plugin that actually does nothing; it's not even loaded. But it can be
  # used as a template for new plugins.
  #
  # A plugin can do the following things:
  # - Provide commands to the CLI.
  # - Provide an action that's called whenever the focus changes.
  #
  # To create a plugin, do two things:
  # 1. Implement it, like below.
  # 2. Requitre it in `lib/vps.rb`
  #
  # Plugins are configured through the program configuration.
  #
  module SamplePlugin

    ##
    # Read the area configuration for the plugin. The idea here is to create a sound and complete
    # configuration hash. This hash is passed back to the plugin, as part of the complete
    # configuration, when the plugin is executed.
    #
    # Every plugin MUST implement this method.
    #
    # @return The area configuration for the plugin to store in memory.
    # @param area [Hash] a hash that expose the +:key+, +:name+ and +:root+ of the area
    # @param hash [Hash] the configuration of the plugin as read from the YAML configuration file.
    def self.read_area_configuration(area, hash)
      {
      }
    end

    ##
    # A sample command. This command is exposed to the CLI.
    #
    # Put this is in the registry as follows:
    #
    #   sample: {
    #     module: VPS::SamplePlugin
    #     commands: {
    #       list: {
    #         class: VPS::SamplePlugin::SampleCommand
    #         type: :list
    #       }
    #     }
    #   }
    #
    # A command can be one of two types:
    # 1. +:list+, in which case it must produce an array of (Alfred) results.
    # 2. +:single+, in which case it must produce a single string
    #
    class SampleCommand
      include PluginSupport

      ##
      # Returns an option parser. This is, at the moment, used only to produce help information
      # for the command. You could, of course, use it within your own +can_run?+ and/or +run+
      # methods.
      #
      # Every comand MUST implement this initializer.
      def self.option_parser
        OptionParser.new do |parser|
          parser.banner = 'Sample command that does nothing, really'
          parser.separator 'Usage: sample list'
        end
      end


      ##
      # Returns whether this command can actually run. This is where you check input arguments,
      # the current context, and whatever else is needed to run the command successfully.
      #
      # This is also where you can write warnings and/or errors to +$stderr+.
      #
      # Implementing this method is optional. If you don't, +true+ is assumed.
      #
      # Access +@context+ to get information about the environment, it's a +Context+.
      #
      # @param arguments All arguments passed to the command through the CLI.
      def can_run?
        true
      end

      ##
      # Run the command. Raising exceptions should never be needed, since all prerequisites
      # are already verified by the +can_run?+ method that was executed earlier..
      #
      # Access +@context+ to get information about the environment, it's a +Context+.
      #
      # @param arguments All arguments passed to the command through the CLI.
      def run
        []
      end
    end

    ##
    # Read the action configuration for the plugin. The idea here is to create a sound and complete
    # configuration hash. This hash is passed back to the plugin, as part of the complete
    # configuration, when the plugin is executed.
    #
    # Every action plugin MUST implement this method.
    #
    # @return The action configuration for the plugin to store in memory.
    # @param hash [Hash] the configuration of the plugin as read from the YAML configuration file.
    def self.read_action_configuration(hash)
      {
      }
    end

    ##
    # A sample action. This is called whenever the focus is changed.
    #
    # Put this is in the registry as follows:
    #
    #   sample: {
    #     module: VPS::SamplePlugin,
    #     action: SamplePlugin::SampleAction
    #   }
    #
    class SampleAction
      include PluginSupport

      ##
      # Runs the action; this happens when the focus changes
      def run(environment)

      end
    end

    Registry.register(SamplePlugin) do |plugin|
      plugin.add_command(SampleCommand, :single)
      plugin.add_action(SampleAction)
    end
  end
end
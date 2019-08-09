module VPS

  ##
  # Registration of all plugins, the commands they support, and so on.
  # Any new plugin needs to be added here.
  module Registry
    PLUGINS = {
      area: {
        module: VPS::Area,
        commands: {
          list: {
            class: VPS::Area::List,
            type: :list
          },
          commands: {
            class: VPS::Area::Commands,
            type: :list
          },
          focus: {
            class: VPS::Area::Focus,
            type: :single
          }
        },
      },
      bitbar: {
        module: VPS::BitBar,
        action: VPS::BitBar::Refresh
      },
      wallpaper: {
        module: VPS::Wallpaper,
        action: VPS::Wallpaper::Replace
      }
      # mail: [:new],
      # bear: [:new],
      # markdown: [:new, :find],
      # omnifocus: [:browse, :actions],
      # contacts: [:browse, :actions]
    }
    private_constant :PLUGINS

    def self.commands
      PLUGINS.select { |_, definition| definition.has_key? :commands }
    end

    def self.plugins
      PLUGINS
    end
  end
end
module Area
  PLUGINS = {
    wallpaper: {
      path: 'wallpaper/wallpaper_plugin',
      class: 'WallpaperPlugin'
    },
    bitbar: {
      path: 'bitbar/bitbar_plugin',
      class: 'BitBarPlugin',
    },
    omnifocus: {
      path: 'omnifocus/omnifocus_plugin',
      class: 'OmniFocusPlugin'
    }
  }.freeze

  def self.list(config: Config.load)
    focus = config.focused_area[:key]
    config.areas.map do |name|
      area = config.area(name)
      postfix = area[:key].eql?(focus) ? ' (focused)' : ''
      {
        uid: area[:key],
        arg: area[:key],
        title: area[:name] + postfix,
        autocomplete: area[:name]
      }
    end
  end

  def self.focus(key, config: Config.load)
    area = config.focus(key)
    config.save
    config.actions.each do |key|
      action = instantiate_action(key)
      action.focus_changed(area, config.action(key))
    end
    "#{area[:name]} is now the focused area"
  end

  def self.instantiate_action(key)
    plugin = PLUGINS[key]
    return if plugin.nil?
    require_relative(plugin[:path])
    Object.const_get(plugin[:class]).new
  end
end

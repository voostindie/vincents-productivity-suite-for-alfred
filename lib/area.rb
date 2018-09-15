require_relative 'config'
require_relative 'wallpaper'

module Area
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

  def self.focus(area, config: Config.load, wallpaper: Wallpaper)
    config.focus(area)
    config.save
    area = config.focused_area
    wallpaper::change(area)
    "#{area[:name]} is now the focused area"
  end
end
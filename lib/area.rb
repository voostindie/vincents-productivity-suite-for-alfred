require_relative 'config'

module Area
  ACTION_CLASSES = {
    wallpaper: 'Wallpaper'
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
    config.actions.each do | key|
      action = instantiate_action(key)
      action.change(area, config.action(key))
    end
    "#{area[:name]} is now the focused area"
  end

  def self.instantiate_action(key)
    require_relative(key.to_s)
    Object.const_get(ACTION_CLASSES[key]).new
  end
end
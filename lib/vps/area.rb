class Area

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

  def self.focus(key, config: Config.load, new_config: NewConfig.new)
    config.focus(key)
    config.save
    area = new_config.areas[key]
    new_config.instantiate_actions.each {|a|a.focus_changed(area, config.area(key))}
    "#{config.area(key)[:name]} is now the focused area"
  end
end

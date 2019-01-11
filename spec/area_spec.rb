require 'spec_helper'
require 'area'

describe Area, '#instantiate_action' do

  context 'when loading the :bitbar plugin' do
    it 'instantiates the BitBarPlugin class' do
      plugin = Area.instantiate_action(:bitbar)
      expect(plugin).to_not be(nil)
      expect(plugin).to be_a(FocusPlugin)
      expect(plugin.class.to_s).to eq('BitBarPlugin')
    end
  end

  context 'when loading the :wallpaper plugin' do
    it 'instantiates the WallpaperPlugin class' do
      plugin = Area.instantiate_action(:wallpaper)
      expect(plugin).to_not be(nil)
      expect(plugin).to be_a(FocusPlugin)
      expect(plugin.class.to_s).to eq('WallpaperPlugin')
    end
  end

  context 'when loading the :omnifocus plugin' do
    it 'instantiates the OmniFocus class' do
      plugin = Area.instantiate_action(:omnifocus)
      expect(plugin).to_not be(nil)
      expect(plugin).to be_a(FocusPlugin)
      expect(plugin.class.to_s).to eq('OmniFocusPlugin')
    end
  end

  context 'when loading an :unknown plugin' do
    it 'returns nil' do
      plugin = Area.instantiate_action(:foo)
      expect(plugin).to be(nil)
    end
  end
end

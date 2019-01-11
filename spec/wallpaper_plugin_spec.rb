require 'spec_helper'

describe WallpaperPlugin, '#change' do
  context 'when passed a valid configuration' do

    config = {
      areas: {
        wallpaper: {
          path: 'test.jpg'
        }
      },
      actions: {
        wallpaper: {
          default: 'foo.jpg'
        }
      }
    }

    it 'sets the desktop wallpaper to the configured path' do
      stub = WallpaperStubRunner.new
      WallpaperPlugin.new(stub).focus_changed(config[:areas], config[:actions])
      expect(stub.path).to eq('test.jpg')
    end
  end
end

class WallpaperStubRunner
  attr_reader :path
  def execute(script, path)
    @path = path
  end
end
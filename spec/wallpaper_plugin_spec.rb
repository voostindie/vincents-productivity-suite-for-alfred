require 'spec_helper'

module VPS
  describe WallpaperPlugin, '#change' do
    context 'when passed the simplest configuration possible' do
      it 'sets the wallpaper to the system default' do
        stub = WallpaperStubRunner.new
        WallpaperPlugin.new({}, runner: stub).focus_changed({}, {})
        expect(stub.path).to eq('/Library/Desktop Pictures/High Sierra.jpg')
      end
    end

    context 'when passed a valid configuration' do
      defaults = {
        'path' => 'default.jpg'
      }

      empty_area = {
      }

      override_area = {
        'wallpaper' => {
          'path' => 'override.jpg'
        }
      }

      it 'uses the default wallpaper when none is specified in the area' do
        stub = WallpaperStubRunner.new
        WallpaperPlugin.new(defaults, runner: stub).focus_changed(empty_area, {})
        expect(stub.path).to eq('default.jpg')
      end

      it 'uses the wallpaper from the area it is specified there' do
        stub = WallpaperStubRunner.new
        WallpaperPlugin.new(defaults, runner: stub).focus_changed(override_area, {})
        expect(stub.path).to eq('override.jpg')
      end
    end
  end

  class WallpaperStubRunner
    attr_reader :path

    def execute(script, path)
      @path = path
    end
  end
end
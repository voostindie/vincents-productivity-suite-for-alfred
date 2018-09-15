require 'spec_helper'
require 'area'

describe Area, '#list' do
  context 'with a valid configuration' do

    it 'lists all areas when no focus is set' do
      config = ConfigStub.new
      expected = [
        {
          uid: 'one',
          arg: 'one',
          title: 'First',
          autocomplete: 'First'
        },
        {
          uid: 'two',
          arg: 'two',
          title: 'Second',
          autocomplete: 'Second'
        }
      ]
      list = Area::list(config: ConfigStub.new)
      expect(list).to eq(expected)
    end

    it 'lists all areas when the focus is set' do
      config = ConfigStub.new
      expected = [
        {
          uid: 'one',
          arg: 'one',
          title: 'First',
          autocomplete: 'First'
        },
        {
          uid: 'two',
          arg: 'two',
          title: 'Second (focused)',
          autocomplete: 'Second'
        }
      ]
      list = Area::list(config: ConfigStub.new(:two))
      expect(list).to eq(expected)
    end
  end
end

class ConfigStub

  def initialize(focus = nil)
    @focus = focus
    @areas = {
      one: {
        key: 'one',
        name: 'First'

      },
      two: {
        key: 'two',
        name: 'Second'
      }
    }
  end

  def focused_area
    return {} if @focus == nil
    @areas[@focus]
  end

  def areas
    @areas.keys
  end

  def area(name)
    @areas[name]
  end
end
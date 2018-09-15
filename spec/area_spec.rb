require 'spec_helper'
require 'area'

describe Area do
  context 'with a valid configuration' do

    it 'lists all areas when no focus is set' do
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

    it 'allows a different area to be focused' do
      config = ConfigStub.new(:two)
      expect(config.saved).to be(false)
      result = Area::focus(:one, config: config)
      expect(result).to eq("First is now the focused area")
      expect(config.saved).to be(true)
    end
  end
end

class ConfigStub

  attr_reader :saved

  def initialize(focus = nil)
    @saved = false
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

  def focus(key)
    @focus = key
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

  def save
    @saved = true
  end
end
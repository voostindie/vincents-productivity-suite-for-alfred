require 'spec_helper'
require 'omnifocus'

describe OmniFocus, '#projects' do
  context 'when passed a valid configuration' do

    area = {
      omnifocus: {
        folder: 'Foo',
      }
    }

    it 'lists all projects in the configured OmniFocus folder' do
      expected = [
        {
          uid: 'foo',
          title: 'Foo',
          arg: 'Foo',
          autocomplete: 'Foo',
          mods: {
            alt: {
              valid: false,
              arg: 'Foo',
              subtitle: 'Markdown notes are not available for the focused area'
            }
          }
        }
      ]
      projects = OmniFocus::projects(area: area, runner: StubRunner.new)
      expect(projects).to eq(expected)
    end
  end
end

class StubRunner
  def execute(script, *args)
    folder = args[0]
    [{
      'id' => folder.downcase,
      'name' => folder
    }]
  end
end
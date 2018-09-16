require 'spec_helper'
require 'omnifocus'

describe OmniFocus, '#projects' do
  context 'when passed a valid configuration' do

    area = {
      omnifocus: {
        folder: 'Foo',
      }
    }

    it 'lists all projects in the configured OmniFocus folder in shortcut mode' do
      expected = [
        {
          uid: 'foo',
          title: 'Foo',
          subtitle: "Open 'Foo' in OmniFocus",
          arg: 'omnifocus://task/foo',
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
      projects = OmniFocus::projects(area: area, runner: OmniFocusStubRunner.new)
      expect(projects).to eq(expected)
    end

    it 'lists all projects in the configured OmniFocus folder in snippet mode' do
      expected = [
        {
          uid: 'foo',
          title: 'Foo',
          subtitle: "Paste 'Foo' in the frontmost application",
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
      projects = OmniFocus::projects(true, area: area, runner: OmniFocusStubRunner.new)
      expect(projects).to eq(expected)
    end

    it 'can set the focus in OmniFocus to the right folder' do
      stub = OmniFocusStubRunner.new
      omnifocus = OmniFocus.new(stub)
      omnifocus.change(area, {})
      expect(stub.script[:name]).to eq('omnifocus-set-focus')
      expect(stub.script[:arg]).to eq('Foo')
    end
  end
end

class OmniFocusStubRunner
  attr_reader :script

  def execute(script, *args)
    @script = {name: script, arg: args[0]}
    folder = args[0]
    [{
       'id' => folder.downcase,
       'name' => folder
     }]
  end
end
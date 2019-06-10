require 'spec_helper'

describe BitBarPlugin, '#change_focus' do
  context 'when using the default configuration' do
    it 'uses the default plugin name' do
      stub = BitBarStubRunner.new
      BitBarPlugin.new(runner: stub).focus_changed({}, {})
      expect(stub.command).to eq('open -g bitbar://refreshPlugin?name=focused-area.1d.rb')
    end
  end

  context 'when passed a configuration with a different plugin name' do

    defaults = {
      'plugin' => 'plugin'
    }

    it 'uses the configured plugin name' do
      stub = BitBarStubRunner.new
      BitBarPlugin.new(defaults, runner: stub).focus_changed({}, {})
      expect(stub.command).to eq('open -g bitbar://refreshPlugin?name=plugin')
    end
  end
end

class BitBarStubRunner
  attr_reader :command

  def execute(command)
    @command = command
  end
end
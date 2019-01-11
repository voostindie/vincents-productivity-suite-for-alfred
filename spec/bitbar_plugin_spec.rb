require 'spec_helper'
require 'bitbar/bitbar_plugin'

describe BitBarPlugin, '#change_focus' do
  context 'when passed a valid configuration' do

    defaults = {
      plugin: 'plugin'
    }

    it 'sets the desktop wallpaper to the configured path' do
      stub = BitBarStubRunner.new
      BitBarPlugin.new(stub).focus_changed({}, defaults)
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
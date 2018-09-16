require 'spec_helper'
require 'bitbar'

describe BitBar, '#change' do
  context 'when passed a valid configuration' do

    defaults = {
      plugin: 'plugin'
    }

    it 'sets the desktop wallpaper to the configured path' do
      stub = BitBarStubRunner.new
      BitBar.new(stub).change({}, defaults)
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
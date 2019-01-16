require 'spec_helper'

describe FocusPlugin do

  it 'registers all subclasses of FocusPlugin' do
    count = FocusPlugin.plugins.size
    expect(FocusPlugin.plugins['dummy']).to be(nil)
    class LocalDummyFocusPlugin < FocusPlugin
    end
    expect(FocusPlugin.plugins.size).to eq(count + 1)
    expect(FocusPlugin.plugins['localdummyfocus']).to eq(LocalDummyFocusPlugin)
  end

end
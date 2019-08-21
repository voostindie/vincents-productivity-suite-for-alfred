require 'spec_helper'

module VPS
  describe Registry, '#initialize' do

    it 'registers all plugins under the Plugins module' do
      r = Registry.new
      expect(r.plugins['omnifocus']).to be_a(VPS::Registry::Plugin)
      expect(r.plugins['bear']).to be_a(VPS::Registry::Plugin)
      expect(r.plugins['mail']).to be_a(VPS::Registry::Plugin)
    end
  end
end
require 'spec_helper'
require 'config'

describe Config, "#load" do
  context "with a missing configuration file" do
    it "raises an error" do
      expect {
        Config.load('MISSING_FILE')
      }.to raise_error(RuntimeError, /Couldn't read/)
    end
  end

  context "with a full-blown sample configuration file" do
    it "loads successfully" do
      config = Config.load('spec/plsrc.yaml')
      expect(config.areas.size).to be(2)
      expect(config.areas['work'][:name]).to eq('Work')
      expect(config.areas['personal'][:name]).to eq('Personal Stuff')
    end
  end
end
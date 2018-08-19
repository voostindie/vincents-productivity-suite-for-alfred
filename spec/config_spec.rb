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
      expect(config.areas.include? 'work').to be(true)

      work_expected = {
          key: 'work',
          name: 'Work'
      }
      expect(config.area('work')).to eq(work_expected)

      personal_expected = {
          key: 'personal',
          name: 'Personal Stuff'
      }
      expect(config.area('personal')).to eq(personal_expected)
    end
  end
end
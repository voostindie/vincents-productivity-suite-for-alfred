require 'spec_helper'

module VPS
  describe NewConfig do

    it 'loads configuration and state from disk' do
      config = NewConfig.new('spec/vpsrc.yaml')
      expect(config.areas).to_not be(nil)
      expect(config.areas['work']).to_not be(nil)
      expect(config.areas['personal']).to_not be(nil)
      expect(config.instantiate_actions).to_not be(nil)
    end

    it 'raises an error when configuration is missing' do
      expect do
        NewConfig.new('spec/vpsrc-missing.yaml')
      end.to raise_error(RuntimeError, /Can't read/)
    end

    it 'raises an error when configuration is not YAML' do
      expect do
        NewConfig.new('README.md')
      end.to raise_error(RuntimeError, /Can't read/)
    end

    it 'instantiates all focus plugins in the actions section' do
      class DummyFocusPlugin < FocusPlugin
        attr_reader :foo

        def initialize(defaults)
          @foo = defaults['foo']
        end
      end
      config = NewConfig.new('spec/dummy_focus_plugin.yaml')
      actions = config.instantiate_actions
      expect(actions.size).to be(1)
      expect(actions[0].class).to eq(DummyFocusPlugin)
      expect(actions[0].foo).to eq('bar') # default value from the configuration file
    end
  end
end
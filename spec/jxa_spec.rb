require 'spec_helper'
require 'jxa'

describe Jxa::Runner, '#execute' do
  context 'with the echo script' do
    it 'returns the script result as parsed JSON' do
      expected = {
        'echo' => ['foo', 'bar']
      }
      result = Jxa::Runner.new(__FILE__).execute('echo', 'foo', 'bar')
      expect(result).to eq(expected)
    end
  end
  
  context 'with an unknown script' do
    it 'raises an eror' do
      expect do
        Jxa::Runner.new(__FILE__).execute('foo')
      end.to raise_exception(/JXA script not found/)
    end
  end

  context 'with a script that throws an error' do
    it 'raises an error' do
      expect do
        Jxa::Runner.new(__FILE__).execute('error')
      end.to raise_exception(/JXA script execution failed/)
    end
  end
end
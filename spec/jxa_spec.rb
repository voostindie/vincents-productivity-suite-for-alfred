require 'spec_helper'

module VPS
  describe JxaRunner, '#execute' do
    context 'with the echo script' do
      it 'returns the script result as parsed JSON' do
        expected = {
          'echo' => %w[foo bar]
        }
        result = JxaRunner.new(File.join('..', 'spec')).execute('echo', 'foo', 'bar')
        expect(result).to eq(expected)
      end
    end

    context 'with an unknown script' do
      it 'raises an eror' do
        expect do
          JxaRunner.new(__FILE__).execute('foo')
        end.to raise_exception(/JXA script not found/)
      end
    end

    context 'with a script that throws an error' do
      it 'raises an error' do
        expect do
          JxaRunner.new(File.join('..', 'spec')).execute('error')
        end.to raise_exception(/JXA script execution failed/)
      end
    end
  end
end

require 'spec_helper'
require 'jxa'

describe Jxa::Runner, "#execute" do
  context "with the echo script" do
    it "returns the script result as parsed JSON" do
      expected = {
        'echo' => ['foo', 'bar']
      }
      result = Jxa::Runner.new.execute('echo', 'foo', 'bar')
      expect(result).to eq(expected)
    end
  end
end
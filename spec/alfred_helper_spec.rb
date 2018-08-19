require 'spec_helper'
require 'alfred_helper'

describe '#alfred_items' do
  context 'with code that returns a list of items' do
    it 'prints an Alfred JSON result with that list' do
      expected = '{"items":[1,2,3]}'
      expect do
        alfred_items do
          [1, 2, 3]
        end
      end.to output("#{expected}\n").to_stdout
    end
  end

  context 'with code that throws an exception' do
    it 'prints an Alfred JSON result with that exception' do
      expected = '{"items":[{"title":"Error: Oops!","valid":false}]}'
      expect do
        alfred_items do
          raise "Oops!"
        end
      end.to output("#{expected}\n").to_stdout
    end
  end
end

describe '#alfred_single' do
  context 'with code that returns a string' do
    it 'prints the string as is' do
      expect do
        alfred_single do
          'output'
        end
      end.to output("output\n").to_stdout
    end
  end

  context 'with code that throws an exception' do
    it 'prints the exception as is' do
      expect do
        alfred_single do
          raise 'Oops!'
        end
      end.to output("Error: Oops!\n").to_stdout
    end
  end
end
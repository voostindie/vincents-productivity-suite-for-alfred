require 'spec_helper'

module VPS
  module OutputFormatter
    describe Console, '#format' do
      context 'with code that returns a list of items' do
        it 'prints newline separated list' do
          expected = "- 1: One\n- 2: Two\n- 3: Three"
          result = Console.format(
            [
              { uid: '1', title: 'One' },
              { uid: '2', title: 'Two' },
              { uid: '3', title: 'Three' }
            ]
          )
          expect(result).to eq(expected)
        end
      end
    end

    describe Console, '#format' do
      context 'with code that returns a string' do
        it 'prints the string as is' do
          expect(Console.format('output')).to eq('output')
        end
      end
    end

    describe Alfred, '#format' do
      context 'with code that returns a list of items' do
        it 'prints an Alfred JSON result with that list' do
          expected = '{"items":[1,2,3]}'
          result = Alfred.format([1, 2, 3])
          expect(result).to eq(expected)
        end
      end
    end

    describe Alfred, '#format' do
      context 'with code that returns a string' do
        it 'prints the string as is' do
          expect(Alfred.format('output')).to eq('output')
        end
      end
    end
  end
end

require 'spec_helper'

module VPS
  module OutputFormatter
    describe Console, '#format' do
      context 'with code that returns a list of items' do
        it 'prints newline separated list' do
          expected = "- 1: One\n- 2: Two\n- 3: Three"
          expect do
            Console::format do
              [
                {uid: '1', title: 'One'},
                {uid: '2', title: 'Two'},
                {uid: '3', title: 'Three'}]
            end
          end.to output("#{expected}\n").to_stdout
        end
      end
    end

    describe Console, '#format' do
      context 'with code that returns a string' do
        it 'prints the string as is' do
          expect do
            Console::format do
              'output'
            end
          end.to output("output\n").to_stdout
        end
      end
    end

    describe Alfred, '#format' do
      context 'with code that returns a list of items' do
        it 'prints an Alfred JSON result with that list' do
          expected = '{"items":[1,2,3]}'
          expect do
            Alfred::format do
              [1, 2, 3]
            end
          end.to output("#{expected}\n").to_stdout
        end
      end
    end

    describe Alfred, '#format' do
      context 'with code that returns a string' do
        it 'prints the string as is' do
          expect do
            Alfred::format do
              'output'
            end
          end.to output("output\n").to_stdout
        end
      end
    end
  end
end

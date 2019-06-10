require 'spec_helper'

describe Bear::Note, '#initialize' do

  context 'with valid configuration' do

    area = {
      bear: {
        tags: [
          '$year/$month/$day'
        ]
      }
    }

    it 'prepare a note with tags according to the tag templates' do
      note = Bear::Note.new('Title', area: area, date: Date.new(2019, 06, 10))
      expect(note.tags).to eq(['2019/06/10'])
    end

    it 'creates a note in Bear through an x-callback script' do
      note = Bear::Note.new('Title', area: area, date: Date.new(2019, 06, 10))
      runner = DummyRunner.new
      note.create_file(runner)
      expect(runner.command).to eq('open bear://x-callback-url/create?title=Title&tags=2019%2F06%2F10')
    end

  end
end

class DummyRunner
  attr_reader :command
  def execute(*args)
    @command = args.join ' '
  end
end
require 'spec_helper'

describe Markdown::Note, '#initialize' do

  context 'with valid configuration' do

    area = {
      root: File.join(Dir.home, 'tmp', 'test'),
      markdown_notes: {
        editor: '/usr/bin/my-preferred-editor',
        path: 'Notes',
        extension: 'md',
        name_template: '$year-$month-$day/$slug',
        file_template: '# $title'
      }
    }

    it 'cleans up invalid characters from the title for the filename' do
      note = Markdown::Note.new("!@\#$\t\nnote...%^&*", area: area)
      expect(note.context[:safe_title]).to eq('note')
    end
    
    it 'replaces slashes with hyphens in the safe title' do
      note = Markdown::Note.new('a/b/c', area: area)
      expect(note.context[:safe_title]).to eq('a-b-c')
    end

    it 'creates a slug from the title' do
      note = Markdown::Note.new('This is a dummy note', area: area)
      expect(note.context[:slug]).to eq('this-is-a-dummy-note')
    end

    it 'creates a path according to the name template' do
      note = Markdown::Note.new(
        'This is a dummy note',
        area: area,
        date: Date.new(2018, 8, 19))
      expected_path = File.join(Dir.home, 'tmp', 'test', 'Notes', '2018-08-19', 'this-is-a-dummy-note.md')
      expect(note.path).to eq(expected_path)
    end

    it 'creates note content according to the file template' do
      note = Markdown::Note.new('Title', area: area)
      expect(note.content).to eq('# Title')
    end

    it 'can open notes with the preferred editor' do
      runner = DummyRunner.new
      Markdown::edit_note(__FILE__, area: area, runner: runner)
      expect(runner.command).to eq("/usr/bin/my-preferred-editor \"#{__FILE__}\"")
    end

    it 'can search for notes using Spotlight' do
      runner = DummyRunner.new
      Markdown::search_notes('query', area: area, runner: runner)
      path = File.join(Dir.home, 'tmp', 'test', 'Notes')
      expect(runner.command).to eq("mdfind -onlyin \"#{path}\" query")
    end
  end
end

class DummyRunner
  attr_reader :command
  def execute(command)
    @command = command
  end
end
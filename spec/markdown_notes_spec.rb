require 'spec_helper'
require 'markdown_notes'

describe MarkdownNotes::Note, '#initialize' do

  context 'with valid configuration' do

    config = {
      root: File.join(Dir.home, 'tmp', 'test'),
      markdown_notes: {
        path: 'Notes',
        extension: 'md',
        name_template: '$year-$month-$day/$slug',
        file_template: '# $title'
      }
    }

    it 'cleans up invalid characters from the title for the filename' do
      note = MarkdownNotes::Note.new("!@\#$\t\nnote%^&*", area: config)
      expect(note.filename).to eq('note')
    end

    it 'creates a slug from the title' do
      note = MarkdownNotes::Note.new('This is a dummy note', area: config)
      expect(note.slug).to eq('this-is-a-dummy-note')
    end

    it 'creates a path according to the name template' do
      note = MarkdownNotes::Note.new(
        'This is a dummy note',
        area: config,
        date: Date.new(2018, 8, 19))
      expected_path = File.join(config[:root], 'Notes', '2018-08-19', 'this-is-a-dummy-note.md')
      expect(note.path).to eq(expected_path)
    end

    it 'creates initial content according to the file template' do
      note = MarkdownNotes::Note.new('Title', area: config)
      expect(note.content).to eq('# Title')
    end
  end

end
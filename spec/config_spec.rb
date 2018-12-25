require 'spec_helper'
require 'config'

describe Config, '#load' do

  TEST_CONFIG_FILE = 'spec/vpsrc.yaml'.freeze

  context 'with a missing configuration file' do
    it 'raises an error' do
      expect {
        Config.load('MISSING_FILE')
      }.to raise_error(RuntimeError, /Couldn't read/)
    end
  end

  context 'with a full-blown sample configuration file' do

    config = Config.load(TEST_CONFIG_FILE)

    it 'loads successfully' do
      work_expected = {
        key: 'work',
        name: 'Work',
        root: File.join(Dir.home, "Work"),
        markdown_notes: {
          path: 'Notes',
          extension: 'markdown',
          editor: 'open -a Byword.app',
          name_template: '$year/Week $week/$year-$month-$day/$safe_title',
          file_template: <<EOT
---
date: $day-$month-$year
slug: $slug
---
# $title
EOT
        },
        omnifocus: {
          folder: 'Professional life'
        },
        contacts: {
          group: 'Business associates',
          mail: {
            client: 'Microsoft Outlook',
            from: nil
          }
        },
        project_files: {
          path: 'Files',
          documents: 'Docs',
          reference: 'Refs'
        },
        wallpaper: {
          path: 'work.jpg'
        }
      }
      expect(config.area('work')).to eq(work_expected)

      personal_expected = {
        key: 'personal',
        name: 'Personal Stuff',
        root: File.join(Dir.home, "Personal"),
        markdown_notes: {
          path: 'Notes',
          extension: 'md',
          editor: 'open',
          name_template: '$year-$month-$day-$slug',
          file_template: <<EOT
---
date: $day-$month-$year
---
# $title

EOT
        },
        omnifocus: {
          folder: 'Personal Stuff'
        },
        contacts: {
          group: 'Personal Stuff',
          mail: {
            client: 'Mail',
            from: 'Me Myself <me@example.com>'
          }
        },
        project_files: {
          path: 'Projects',
          documents: 'Documents',
          reference: 'Reference Material'
        }
      }
      expect(config.area('personal')).to eq(personal_expected)
    end

    it 'returns all areas listed in order, sorted on key' do
      expect(config.areas).to eq ['personal', 'work']
    end

    it 'allows an existing area to be selected' do
      config.focus('work')
      expect(config.focused_area[:key]).to eq('work')
    end

    it 'returns the wallpaper action' do
      expect(config.actions).to include :wallpaper
      expect(config.action(:wallpaper)[:default]).to eq('/Library/Desktop Pictures/High Sierra.jpg')
    end

    it 'returns the bitbar action' do
      expect(config.actions).to include :bitbar
      expect(config.action(:bitbar)[:plugin]).to eq('focused-area.1d.rb')
    end

    it 'returns the omnifocus action' do
      expect(config.actions).to include :omnifocus
    end

    it 'allows state to be saved to disk' do
      state = "#{TEST_CONFIG_FILE}.state"
      expect(File.exist?(state)).to be(false)
      config.focus('work')
      config.save
      expect(File.exist?(state)).to be(true)

      config2 = Config.load(TEST_CONFIG_FILE)
      expect(config2.focused_area[:key]).to eq('work')

      File.delete(state)
    end
  end

end
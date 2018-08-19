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
          name_template: '$year/Week $week/$year-$month-$day/$title',
          file_template: <<EOT
---
date: $day-$month-$year
slug: $slug
---
# $title
EOT
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
          name_template: '$year-$month-$day-$slug',
          file_template: <<EOT
---
date: $day-$month-$year
---
# $title

EOT
        }
      }
      expect(config.area('personal')).to eq(personal_expected)
    end

    it 'returns all areas listed in order, sorted on key' do
      expect(config.areas).to eq ['personal', 'work']
    end

    it 'allows an existing area to be selected' do
      config.set_area('work')
      expect(config.active_area[:key]).to eq('work')
    end

    it 'allows state to be saved to disk' do
      state = "#{TEST_CONFIG_FILE}.state"
      expect(File.exist?(state)).to be(false)
      config.set_area('work')
      Config.save_state(config, TEST_CONFIG_FILE)
      expect(File.exist?(state)).to be(true)

      config2 = Config.load(TEST_CONFIG_FILE)
      expect(config2.active_area[:key]).to eq('work')

      Config.delete_state(TEST_CONFIG_FILE)
      expect(File.exist?(state)).to be(false)
    end
  end

end
require 'spec_helper'
require 'contacts'

describe Contacts, '#people' do
  context 'when passed a valid configuration' do

    area = {
      contacts: {
        group: 'Foo',
        mail: {
          client: 'Mail',
          from: 'Me Myself <me@example.com>'
        }
      }
    }

    it 'lists all names in the configured Contacts group in shortcut mode' do
      expected = [
        {
          uid: 'foo',
          title: 'Foo',
          subtitle: 'View this contact in Alfred',
          arg: 'Foo',
          autocomplete: 'Foo',
          mods: {
            alt: {
              valid: false,
              arg: 'Foo',
              subtitle: 'Markdown notes are not available for the focused area'
            }
          }
        }
      ]
      people = Contacts::people(area: area, runner: StubRunner.new)
      expect(people).to eq(expected)
    end

    it 'lists all names in the configured Contacts group in snippet mode' do
      expected = [
        {
          uid: 'foo',
          title: 'Foo',
          subtitle: 'Paste this name in the frontmost application',
          arg: 'Foo',
          autocomplete: 'Foo',
          mods: {
            alt: {
              valid: false,
              arg: 'Foo',
              subtitle: 'Markdown notes are not available for the focused area'
            }
          }
        }
      ]
      people = Contacts::people(true, area: area, runner: StubRunner.new)
      expect(people).to eq(expected)
    end

    it 'creates e-mail using the configured from address' do
      expected = {
        script: 'mail-create-email-message',
        to: 'test@example.com',
        from: 'Me Myself <me@example.com>'
      }
      runner = MailStubRunner.new
      Contacts::create_email('test@example.com', area: area, runner: runner)
      expect(runner.command).to eq(expected)
    end
  end
end

class StubRunner
  def execute(script, *args)
    group = args[0]
    [{
       'id' => group.downcase,
       'name' => group
     }]
  end
end

class MailStubRunner
  attr_reader :command

  def execute(script, *args)
    @command = {
      script: script,
      to: args[0],
      from: args[1]
    }
  end
end
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
          subtitle: 'Write an e-mail to Foo',
          arg: 'Foo',
          autocomplete: 'Foo',
          variables: {
            id: 'foo',
            name: 'Foo',
            email: 'foo@example.com'
          },
          mods: {
            cmd: {
              valid: true,
              arg: 'Foo',
              subtitle: "Show 'Foo' in the Contact Viewer"
            },
            alt: {
              valid: false,
              arg: 'Foo',
              subtitle: 'Markdown notes are not available for the focused area'
            }
          }
        }
      ]
      people = Contacts::people(area: area, runner: ScriptStubRunner.new)
      expect(people).to eq(expected)
    end

    it 'lists all names in the configured Contacts group in snippet mode' do
      expected = [
        {
          uid: 'foo',
          title: 'Foo',
          subtitle: "Paste 'Foo' in the frontmost application",
          arg: 'Foo',
          autocomplete: 'Foo',
          variables: {
            id: 'foo',
            name: 'Foo',
            email: 'foo@example.com'
          },
          mods: {
            cmd: {
              valid: false,
              arg: 'Foo',
              subtitle: "Show 'Foo' in the Contact Viewer"
            },
            alt: {
              valid: false,
              arg: 'Foo',
              subtitle: 'Markdown notes are not available for the focused area'
            }
          }
        }
      ]
      people = Contacts::people(true, area: area, runner: ScriptStubRunner.new)
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

class ScriptStubRunner
  def execute(script, *args)
    group = args[0]
    [{
       'id' => group.downcase,
       'name' => group,
       'email' => "#{group.downcase}@example.com"
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
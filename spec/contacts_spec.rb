require 'spec_helper'

module VPS
  describe Contacts, '#people' do
    context 'when passed a valid configuration' do

      area = {
        contacts: {
          group: 'Foo',
          mail: {
            client: 'Mail',
            from: 'Me Myself <me@example.com>'
          }
        },
        markdown_notes: {}
      }

      it 'lists all names in the configured Contacts group in shortcut mode' do
        expected = [
          {
            uid: 'foo',
            title: 'Foo',
            subtitle: "Select an action for 'Foo'",
            arg: 'Foo',
            autocomplete: 'Foo',
            variables: {
              id: 'foo',
              name: 'Foo',
              email: 'foo@example.com'
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
            }
          }
        ]
        people = Contacts::people(true, area: area, runner: ScriptStubRunner.new)
        expect(people).to eq(expected)
      end

      it 'lists all available actions for a specific contact' do
        expected = [
          {
            title: "Open in Contacts",
            arg: 'addressbook://foo',
            variables: {
              action: 'open'
            }
          },
          {
            title: "Create note",
            arg: 'Foo',
            variables: {
              action: 'create-note'
            },
            icon: {
              path: 'icons/bear.png'
            }
          },
          {
            title: "Search notes",
            arg: 'Foo',
            variables: {
              action: 'search-markdown-notes'
            }
          },
          {
            title: "Write e-mail",
            arg: 'Foo',
            variables: {
              action: 'create-email',
              id: 'foo',
              name: 'Foo',
              email: 'foo@example.com'
            },
            icon: {
              path: 'icons/mail.png'
            }
          },
          {
            title: "Show in Contact Viewer",
            arg: 'Foo',
            variables: {
              action: 'contact-viewer'
            }
          },
          {
            title: "Paste in frontmost application",
            arg: 'Foo',
            variables: {
              action: 'snippet'
            }
          }
        ]
        actions = Contacts::actions({id: 'foo', name: 'Foo', email: 'foo@example.com'}, area: area)
        expect(actions).to eq(expected)
      end

      it 'creates e-mail using the configured from address' do
        expected = {
          script: 'create-mail-message',
          to: 'Test <test@example.com>',
          from: 'Me Myself <me@example.com>'
        }
        runner = MailStubRunner.new
        Contacts::create_email({name: 'Test', email: 'test@example.com'}, area: area, runner: runner)
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
end
#!/usr/bin/osascript -l JavaScript
/*
 * Paste text to the frontmost app. This uses the clipboard, as the text to paste
 * may hold things like emoji's. You can't just "keystroke" those.
 *
 * Open issue: resetting the clipbaord after pasting doesn't really work well.
 *
 * Requires one argument: the text to paste.
 */

function run(arguments) {
    if (arguments[0] == null) {
        throw ('No text specified')
    }

    let text = arguments.join(' ');

    let app = Application.currentApplication();
    app.includeStandardAdditions = true;
    let clipboard = app.theClipboard;

    app.setTheClipboardTo(text);
    Application('System Events').keystroke('v', {using: 'command down'});
    delay(0.2);

    app.setTheClipboardTo(clipboard);
    return true;
}
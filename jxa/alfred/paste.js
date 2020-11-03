#!/usr/bin/osascript -l JavaScript
/*
 * Paste text to the frontmost app. This triggers the Alfred workflow,
 * which in turn uses the clipboard.
 *
 * The text to paste may hold things like emoji's. You can't just "keystroke" those.
 *
 * Requires one argument: the text to paste.
 */

function run(arguments) {
    if (arguments[0] == null) {
        throw ('No text specified')
    }

    let text = arguments.join(' ');

    let app = Application('Alfred');
    app.runTrigger('paste', {inWorkflow: 'nl.ulso.vps', withArgument: text});

    return true;
}
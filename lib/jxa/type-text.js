#!/usr/bin/osascript -l JavaScript
/*
 * Type text in the front-most app. This script is a replacement for Alfred's
 * "Copy to Clipboard". Although that feature allows anything  to be pasted in
 * the front-most application, it also keeps this in the clipboard, which
 * is not needed and rather annoying.
 *
 * This script also uses the clipboard. Why? Because
 *  'app.keystroke('long text here')';
 * is really slow. You'll see each character appear individually. Pasting it out
 * of the clipboard (with one keystroke) is much faster.
 *
 * The "delay(0.10)" is needed to make sure that the text being pasted from
 * is actually the text to type, and not the original (or reverted) contents.
 *
 * Requires one argument: the text to type.
 */
function run(arguments) {
    if (arguments[0] == null) {
        throw ('No text specified')
    }

    var app = Application('System Events');
    app.includeStandardAdditions = true;

    var clipboard = app.theClipboard();
    var text = arguments[0];
    app.setTheClipboardTo(text);
    app.keystroke('v', { using: 'command down' });
    delay(0.10);
    app.setTheClipboardTo(clipboard);
}
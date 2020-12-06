#!/usr/bin/osascript -l JavaScript
/*
 * Activates Bear.
 */

function run(arguments) {
    let obsidian = Application('Bear');
    obsidian.activate();
    return true;
}

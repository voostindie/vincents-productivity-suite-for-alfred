#!/usr/bin/osascript -l JavaScript
/*
 * Activates Obsidian.
 */

function run(arguments) {
    let obsidian = Application('Obsidian');
    obsidian.activate();
    return true;
}
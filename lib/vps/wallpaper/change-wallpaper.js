#!/usr/bin/osascript -l JavaScript
/*
 * Changes the picture of the current desktop.
 *
 * Requires one argument: the path to the picture to set.
 */
function run(arguments) {
    var path = arguments[0];
    if (path == null) {
        throw "No path specified";
    }
    var system = Application('System Events');
    system.currentDesktop.picture = path;
    return '{}';
}
#!/usr/bin/osascript -l JavaScript
/*
 * Tells GeekTool to refresh one or more plugins
 *
 * Requires one argument: a JSON array of geeklet IDs
 */
function run(arguments) {
    let json = arguments[0];
    if (json == null) {
        throw "No geeklets specified";
    }
    let geektool = Application('Geektool Helper')
    let geeklets = JSON.parse(json);
    geeklets.forEach(function (name) {
        geektool.geeklets.byName(name).refresh();
    });
    return '{}';
}
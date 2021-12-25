#!/usr/bin/osascript -l JavaScript
/*
 * Browse files in Alfred for a specific folder.
 *
 * Requires one argument: the folder to browse.
 */

function run(arguments) {
    if (arguments[0] == null) {
        throw ('No folder specified')
    }

    let folder = arguments[0];

    Application('Alfred').browse(folder);
    return true;
}
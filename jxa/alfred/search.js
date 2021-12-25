#!/usr/bin/osascript -l JavaScript
/*
 * Search in Alfred and press "Enter" on it.
 *
 * Requires one argument: the search string.
 */

const RETURN_KEYCODE = 36;

function run(arguments) {
    if (arguments[0] == null) {
        throw ('No search argument specified')
    }

    let query = arguments[0];

    Application('Alfred').search(query);
    Application('System Events').keyCode(RETURN_KEYCODE);
}
#!/usr/bin/osascript -l JavaScript
/*
 * Echo's the input arguments. For testing.
 */
function run(arguments) {
    return JSON.stringify({ echo: arguments });
}

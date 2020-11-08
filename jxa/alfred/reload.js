#!/usr/bin/osascript -l JavaScript
function run(arguments) {
    if (arguments[0] == null) {
        throw ('No ID specified')
    }
    let id = arguments[0];
    let app = Application('Alfred');
    app.reloadWorkflow(id);
    return true;
}
#!/usr/bin/osascript -l JavaScript
/*
 * Lists groups from Contacts
 *
 * Requires one argument: the name prefix used to select groups
 */
function run(argv) {
    let prefix = argv[0];
    if (prefix == null) {
        throw "No prefix specified as argument";
    }
    let contacts = Application('Contacts');
    let groups = contacts.groups.whose(
        { name: { _beginsWith: prefix }}
    );
    let ids = groups.id();
    let names = groups.name();
    var i = 0;
    let result = ids.map(function(id) {
        return {
            id: id,
            name: names[i++]
        }
    });
    return JSON.stringify(result);
}

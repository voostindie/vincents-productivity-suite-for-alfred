#!/usr/bin/osascript -l JavaScript
/*
 * Lists people from Contacts
 *
 * Requires one argument: the name of the group to pull people from.
 */
function run(argv) {
    var groupName = argv[0];
    if (groupName == null) {
        throw "No group specified as argument";
    }

    var contacts = Application('Contacts');
    var people = contacts.groups.byName(groupName).people;

    var ids = people.id();
    var names = people.name();
    var emails = people.emails.value();
    var i = 0;

    var result = ids.map(function(id) {
        return {
            id: id,
            name: names[i],
            email: emails[i++][0]
        }
    });

    return JSON.stringify(result);
}

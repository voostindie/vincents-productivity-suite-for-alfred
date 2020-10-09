#!/usr/bin/osascript -l JavaScript
/*
 * Lists people from Contacts
 *
 * Requires one argument: the ID of the group to pull people from.
 */
function run(argv) {
    let groupId = argv[0];
    if (groupId == null) {
        throw "No group specified as argument";
    }

    let contacts = Application('Contacts');
    let people = contacts.groups.byId(groupId).people;

    let ids = people.id();
    let names = people.name();
    let emails = people.emails.value();
    var i = 0;

    let list = ids.map(function(id) {
        return {
            id: id,
            name: names[i],
            email: emails[i++][0]
        }
    });
    let result = {
        id: groupId,
        people: list
    }
    return JSON.stringify(result);
}

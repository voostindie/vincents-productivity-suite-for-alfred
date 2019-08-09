#!/usr/bin/osascript -l JavaScript
/*
 * Retrieves details for a single contact from Contacts.
 *
 * Requires one argument: the id of thw contact to retrieve details for.
 */
function run(argv) {
    var contactId = argv[0];
    if (contactId == null) {
        throw "No contact ID specified as argument";
    }

    var contact = Application('Contacts')
        .people
        .byId(contactId);

    var result = {
        id: contact.id(),
        name: contact.name(),
        email: contact.emails.value()[0]
    };

    return JSON.stringify(result);
}

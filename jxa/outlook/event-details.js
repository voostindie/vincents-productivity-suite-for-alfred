#!/usr/bin/osascript -l JavaScript
/*
 * Fetches details for a single event from Outlook.
 *
 * Requires one argument: the ID of the event to get the details for
 */
function run(argv) {
    let eventId = argv[0];
    if (eventId == null) {
        throw "No event ID specified as argument";
    }

    let event = Application('Outlook')
        .calendarEvents
        .byId(eventId);

    let result = {
        id: event.id(),
        title: event.subject(),
        organizer: event.organizer(),
        attendees: event.attendees.emailAddress()
    };

    return JSON.stringify(result);
}


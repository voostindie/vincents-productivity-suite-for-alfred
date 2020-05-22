#!/usr/bin/osascript -l JavaScript
/*
 * Lists today's events from Microsoft Outlook.
 *
 * Requires two arguments:
 * 1. the name of the account to read events from,
 * 2. the name of the calendar (within the account) to read events from
 *
 * Note: this script is slow, and incomplete. It doesn't find recurring items.
 */
function run(argv) {
    let account = argv[0];
    if (account == null) {
        throw "No account specified as 1st argument";
    }
    let calendar = argv[1];
    if (calendar == null) {
        throw "No calendar specified as 2nd argument";
    }
    let startDate = computeStartDate();
    let endDate = computeEndDate();


    let outlook = Application('Microsoft Outlook');

    let items = outlook.calendarEvents.whose({
        _and: [
            {startTime: {'>': startDate}},
            {endTime: {'<': endDate}},
            {_match: [ObjectSpecifier().account.name, account]},
            {_match: [ObjectSpecifier().calendar.name, calendar]}
        ]
    }).properties().map(function (event) {
        return {
            id: event.id.toString(),
            title: event.subject
        };
    });
    return JSON.stringify(items);
}

function computeStartDate() {
    var now = new Date();
    var yesterday = new Date();
    yesterday.setDate(now.getDate() - 1);
    yesterday.setHours(23);
    yesterday.setMinutes(59);
    yesterday.setSeconds(59);
    return yesterday;
}

function computeEndDate() {
    var now = new Date();
    var tomorrow = new Date();
    tomorrow.setDate(now.getDate() + 1);
    tomorrow.setHours(0);
    tomorrow.setMinutes(0);
    tomorrow.setSeconds(0);
    return tomorrow;
}
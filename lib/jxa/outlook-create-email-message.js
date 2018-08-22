#!/usr/bin/osascript -l JavaScript
/*
 * Creates a new e-mail message in Microsoft Outlook.
 *
 * Requires two arguments:
 * - the e-mail address to send the mail to.
 * - the e-mail address to send mail from (optional).
 */
function run(arguments) {
    var to = arguments[0];
    if (to == null) {
        throw "No e-mail address specified";
    }
    var outlook = Application('Microsoft Outlook');
    var message = outlook.OutgoingMessage().make();
    message.toRecipients.push(outlook.ToRecipient({emailAddress: {address: to}}));
    outlook.open(message);
    outlook.activate();
    return '{}';
}
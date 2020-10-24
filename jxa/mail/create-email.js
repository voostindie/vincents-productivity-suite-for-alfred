#!/usr/bin/osascript -l JavaScript
/*
 * Creates a new e-mail message in Apple Mail.
 *
 * Requires two arguments:
 * - the e-mail addresses to send the mail to, in a JSON array
 * - the e-mail address to send mail from (optional).
 */
function run(arguments) {
    let to = arguments[0];
    if (to == null) {
        throw "No e-mail address specified";
    }

    let mail = Application('Mail');
    let message = mail.OutgoingMessage().make();
    let from = arguments[1];
    if (from != null) {
        message.sender = from;
    }
    addresses = JSON.parse(to);
    addresses.forEach(function(address) {
        message.toRecipients.push(mail.Recipient({address: address}));
    });
    message.visible = true;
    mail.activate();
    return '{}'
}
#!/usr/bin/osascript -l JavaScript
/*
 * Lists open projects from OmniFocus.
 *
 * Requires one argument: the name of the folder to pull projects from.
 */
function run(argv) {
    var folderName = argv[0];
    if (folderName == null) {
        throw "No folder specified as argument";
    }

    var projects = Application('OmniFocus')
        .defaultDocument()
        .folders
        .byName(folderName)
        .flattenedProjects
        .whose({
            _or: [
                { _match: [ ObjectSpecifier().status, 'active' ] },
                { _match: [ ObjectSpecifier().status, 'on hold']}
            ]
        });

    var ids = projects.id();
    var names = projects.name();
    var i = 0;
    var items = ids.map(function (id) {
        return {
            id: id,
            name: names[i++],
        };
    });

    return JSON.stringify(items);
}

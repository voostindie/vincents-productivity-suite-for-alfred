#!/usr/bin/osascript -l JavaScript
/*
 * Fetches details for a single project.
 *
 * Requires one argument: the ID of the project to get the details for
 */
function run(argv) {
    let projectId = argv[0];
    if (projectId == null) {
        throw "No project ID specified as argument";
    }

    let project = Application('OmniFocus')
        .defaultDocument()
        .projects
        .byId(projectId);

    let result = {
        id: project.id(),
        name: project.name(),
        note: project.note.text()
    };

    return JSON.stringify(result);
}

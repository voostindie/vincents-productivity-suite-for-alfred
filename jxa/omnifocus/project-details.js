#!/usr/bin/osascript -l JavaScript
/*
 * Fetches details for a single project.
 *
 * Requires one argument: the ID of the project to get the details for
 */
function run(argv) {
    var projectId = argv[0];
    if (projectId == null) {
        throw "No project ID specified as argument";
    }

    var project = Application('OmniFocus')
        .defaultDocument()
        .projects
        .byId(projectId);

    var result = {
        id: project.id(),
        name: project.name(),
    };

    return JSON.stringify(result);
}

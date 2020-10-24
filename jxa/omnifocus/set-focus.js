#!/usr/bin/osascript -l JavaScript
/*
 * Sets the focus to a specific folder
 *
 * Requires one argument: the name of the folder to set the focus to.
 */
function run(argv) {
    let folderName = argv[0];
    if (folderName == null) {
        throw "No folder specified as argument";
    }

    let omnifocus = Application('OmniFocus');
    let folder = omnifocus.defaultDocument.folders.byName(folderName);
    let mainWindow = omnifocus.defaultDocument.documentWindows()[0];
    mainWindow.focus = folder;
    return '{}';
}

#!/usr/bin/osascript -l JavaScript
/*
 * Sets the focus to a specific folder
 *
 * Requires one argument: the name of the folder to set the focus to.
 */
function run(argv) {
    var folderName = argv[0];
    if (folderName == null) {
        throw "No folder specified as argument";
    }

    var omnifocus = Application('OmniFocus');
    var folder = omnifocus.defaultDocument.folders.byName(folderName);
    var mainWindow = omnifocus.defaultDocument.documentWindows()[0];
    mainWindow.focus = folder;
    return '{}';
}

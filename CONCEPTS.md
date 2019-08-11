# Concepts

While extending VPS - or at least thinking about it - I found it was time to introduce some concepts. Lacking concepts, code is starting to become muddy.

## Area

A collection of related **entities**. At any time at most one area is active (or: has **focus**). An area represents an "area of responsibility" in GTD.

## Focus

The pointer to the **area** that is currently active. It's worth mentioning on its own because the focus is persistent and it steers everything the system does when invoked.

## Plugin

A module and a set of classes that extend the application by providing
actions and commands.

## Action

A piece of code that is triggered when the focus changes.

Example: 'Replace the wallpaper', or 'Update the BitBar icon'.

## Command

A piece of code that is exposed as a command in the CLI and in the
Alfred workflow.

Example: 'List all projects', or 'Write an e-mail to a contact'.

## Entity Class

The class of the items managed by a **plugin**. Examples are "project", "contact" and "note". Within an **area**, each type can be represented at most once by a plugin. So, if the OmniFocus plugin is enabled to provide projects, then you can't have some other plugin also providing projects.

## Collaboration

A contribution from one plugin for an entity class managed by another
plugin. 

Example: the Bear note plugin manages the Note entity, and it collaborates
with the Project, Contact and Event entities to allow notes to be created
for those.

This concept is necessary to allow plugins to work with each other, without knowing each other. From the example above: the Bear's plugin
collaboration for projects should work with any plugin that manages the Project entity class; that means the Bear plugin can't directly use one
of the Project plugins.

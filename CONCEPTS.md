# Concepts

While extending VPS - or at least thinking about it - I found it was time to introduce some concepts. Lacking concepts, code is starting to become muddy.

## Area

A collection of related entities. At any time at most one area is active (or: has "focus"). An area represents an "area of responsibility" in GTD.

## Focus

The pointer to the area that is currently active. It's worth mentioning on its own because the focus is persistent and it steers everything the system does when invoked.

## Plugin

A module and a set of classes that extend the application by providing, repositories, actions and commands.

## Action

A piece of code that is triggered when the focus changes.

Example: 'Replace the wallpaper', or 'Update the BitBar icon'.

## Entity Type

The type of the items managed by a plugin. Examples are "project", "contact" and "note". Within an area, each type can be represented at most once by a plugin. So, if the OmniFocus plugin is enabled to provide projects, then you can't have some other plugin also providing projects.

## Repository

Manages a single type of entity. A bit like a data access object (DAO).

## Command

A piece of code that is exposed as a command in the CLI and in the
Alfred workflow.

Example: 'List all projects', or 'Write an e-mail to a contact'.

There are 4 different types of commands:

1. EntityType command: acts on a type, e.g. "Create new note"
2. EnitityInstance command: acts on an instance of a type, e.g. "Edit note *x*"
3. Collaboration command: acts an instance of one entity type, and on the type of entity type, e.g. "For this project, create a note".
4. System command: acts on the system as a whole, e.g. "List all available areas"

# How things are coupled

The idea is that invidual commands, repositories and actions are decoupled as much as possible. A command does not, for example, directly call a repository, even if it's defined the same plugin. Instead the command asks the system to do that for it. This decoupling ensures fair play: all commands access data in the same way, independent of where they're defined.

This, in turn, allows plugins to define commands on any kind of entity type. A plugin should represent an application, like OmniFocus, or Contacts, or Safari, and should as such provide commands that make sense for that application.

A good example is the Mail plugin, which contributes the "e-mail" command to both Contacts and Groups. It doesn't manage these entities by itself.

When VPS starts up it reads the configuration and from that builds up a set of commands, grouped by entity type, per area. `vps help` shows you all the available commands. If you switch area (with `vps area focus <area>`), additional commands may appear, or commands may disappear.

And if two different areas support the same entity but with different plugins, then roughly the same set of commands will appear, but they will actually trigger different applications in the background.

These are all reasons why commands, actions and repositories are decoupled as much as possible.

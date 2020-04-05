# Vincent's Productivity Suite (for Alfred)

## Beware!

This project isn't called "*Vincent's* Productivity Suite for Alfred" for nothing. It might not be of any use to anyone but myself. But there's also no reason not to make it public; it could be useful to at least one other person beside me. So why not share?

But please remember that I've had exactly one person in mind while creating this suite: me. *Your mileage may vary!*

**Update August 2019**: This is version 2.0 of this tool. It's, among others, a big refactoring. I deleted some plugins, added some new ones, revamped the Alfred workflow and added a CLI. Version 2 is **not** backwards compatible with the previous version. So, first check below whether this tool is still for you. If not, don't upgrade!

## So, what's this all about?

This is a command-line interface (CLI) as well as an [Alfred](https://www.alfredapp.com) workflow on top of a set of Ruby scripts that make my daily computer work a lot more efficient. So, yes it's macOS only, and specifically it works with:

- Alfred (duh!)
- iA Wrtier
- Bear
- OmniFocus
- Apple Contacts
- Apple Mail
- Apple Calendar
- Desktop wallpapers
- BitBar

A lot of activity at my computer consists of managing projects and tasks in OmniFocus, keeping notes in Bear, writing e-mails in Mail and tracking people in Contacts. This workflow gives me the means to quickly create notes and e-mails and refer to projects and people, either through keyboard shortcuts, keywords, or snippets.

An important aspect of this tool is that it works with *areas of responsibility* (a [Getting Things Done (GTD)](https://gettingthingsdone.com) term), like work, family, sports, and software projects (like this one). At any time, exactly one area has focus. The CLI commands and the keyboard hotkeys, keywords and snippets for Alfred are always the same, but they do different things depending on the area that has the focus.

This CLI and Alfred workflow can:

- Set focus to an area and
    - Show the name of the area (or a nice label) in BitBar
    - Change the desktop wallpaper
- Create a new notes according to a template in iA Writer
- Select a note and:
    - Open it in iA Writer for editing
    - Open it in Marked 2 for viewing
- Select a contact and:
    - Open it in Contacts
    - Create a note for it
    - Write an e-mail
    - Paste its name into the frontmost application
- Select a project and:
    - Open it in OmniFocus
    - Create a note for it
    - Browse project files with Alfred's built-in file browser
    - Paste its name into the frontmost application
- Select an event and:
    - Create a note for it
    - Paste its title into the frontmost application

It may not sound like much, but for me this is an enormous time saver.

## Alfred features

### Keywords and hotkeys

- `focus` / *ctrl* + *opt* + *cmd* + A: sets the focus to an area of responsibility.
- `find`: selects one of the available global note finders. *ctrl* + *opt* + *cmd* + F runs the global note finder `all`, if available.
- `note` / *ctrl* + *opt* + *cmd* + ,: creates a new note and opens it for editing in after you specify the title.
- `notes` / *ctrl* + *opt* + *cmd* + N: selects a note and shows an action list
- `contact` / *ctrl* + *opt* + *cmd* + C: selects a person from Contacts and shows an action list.
- `project` / *ctrl* + *opt* + *cmd* + P: selects a project from OmniFocus and shows an action list.
- `browse` / *ctrl* + *opt* + *cmd* + B: browses the files for the selected area in Alfred's file browser.

The list of actions available for a contact or project depends on the configuration of the focused area of responsibility. E.g. if Bear is enabled, the action to create a note on a contact, project or event will
automatically show up. 

### Snippets

Using the shared prefix `;` and no suffix for snippets:

- `;c`: copies a contact's name into the frontmost application.
- `;p`: copies a project's name into the frontmost application.
- `;n`: copies a note's ID into the frontmost application as a Wiki-link

## How to configure

Create a file `.vpsrc` in your home folder and put something like this in there:

```yaml
areas:
   work:
        bear:
        omnifocus:
        contacts:
        mail:
        alfred:
```

In case you were wondering: yes, this is [YAML](http://yaml.org).

This sets up a single *area of responsibility* with the Bear, OmniFocus, Contacts, Mail, Alfred plugins enabled. These plugins all have default configurations, which is why you don't see anything here.

Once the configuration file exists, use `vps area focus` command in the Terminal, or the `focus` keyword (or ⌃⌥⌘-A) in Alfred to focus on a specific area.

## How to configure, in detail

The minimal configuration sample above means exactly the same as:

```yaml
areas:
    work:
        name: 'Work'
        root: '~/Work'
        iawriter:
        omnifocus:
            folder: 'Work'
        contacts:
            group: 'Work'
        mail:
            from: null
        alfred:
            path: 'Projects'
        bitbar:
            label: 'Work'
```

Again, this is the exact same configuration as the one mentioned earlier. From this full example, you probably get the gist. Below there's detailed information on every separate plugin.

To define an additional area, just add one at the same level as 'work'. Name it however you like. To disable a certain feature for an area, remove its reference completely. E.g. if you remove the `markdown-notes` section, creating notes is not possible in that area.

### Areas

An area looks as follow:

```yaml
key:
    name:
    root:
```

Where:

- `key`: the technical key to use internally. It doesn't really matter what you name an area, except that the name is derived from it, and that you'll have to use it in CLI when switching focus.
- `name`: the name of the area as shown in Alfred, and as used by the other features as default values. The default value is the `key`, capitalized.
- `root`: the directory under which all files for this reside on disk. The default is set to `~/<name>`.

### iA Writer

As of April 2020 I've switched to iA Writer for all my note keeping. I've used Bear for almost a year, and before that I had all my notes in plaintext Markdown notes. I started to miss that, so I switched back.

(Bear support is still available, but not actively maintained.)
 
The default configuration for iA Writer is the following:

```yaml
iawriter:
    location:
    path:
    token:
    creators:
        default:
            title: '{{input}}'
            text: ''
            tags: []
```

With:

- `location`: the location in iA Writer for this area, defaults to the name of the area.
- `path`: the root of the notes on disk, defaults to the name of the URL.
- `token`: the authentication token required by iA Writer to control it using URL Commands. See iA Writer's Preferences. Make sure to check the *Enable URL Commands* settings and click on the *Manage...* button to acquire a copy of the token.

This is the same as just:

```yaml
iawriter:
```

With this default configuration it's not possible to create new notes. Make sure to set the `token` to be able to do that.

#### A note on IDs

This plugin works by assuming that the filename of each note, excluding its extension, is unique. That means that you can move notes around in subdirectories (for example to an archive folder) without breaking anything.

What's there to break? Two things:

1. Note selections. If you do a `vps note list` you'll get all note IDs.
2. Note links. Pressing `;n` allows you to put a link to a note anywhere. This link is not actually a link, but just plaintext: `[[Like This]]`. Several editors support this out of the box. iA Writer does not, as of yet, but that's no problem: a link is just text.

#### Template

The iA Writer support in VPS allows you to set up templates for different types of entities. Each template consists of a set of property, where the value of each property is a [Liquid template](https://shopify.github.io/liquid/) template.

Each note has a title, text, and a set of tags for the note. The defaults are shown above. 

You can:

- Change the defaults and
- Override the defaults, partly or in full, for a different template set. The available sets are `default`, `plain`, `contact`, `event` and `project`.

For example:

```yaml
bear:
    templates:
        default:
            title: '{{year}}-{{month}}-{{day}} {{input}}'
            tags:
                - 'Journal/{{year}}'
                - 'NeedsWork'
        event:
            text: |
                ## Attendees
                
                {% for name in names %}- {{name}}
                {% endfor %}
```

This prepends the current date to every note and also adds two tags. This happens for every note type, since these 2 rules are in the `defaults` section. Then, for events, the text is pre-filled with the list of attendees at the event.

The available variables depend on the thing you're creating a note for:

##### Every note type

- `day`: the number of the day in the current month, zero-padded
- `month`: the number of the current month
- `year`: the current year
- `week`: the number of the week in the current month, zero padded
- `query`: the arguments passed to the command as a string, separated by a space
- `input`: same as query

The arguments are passed both in `query` and in `input`. `input` is meant to be overridden by different note types so that the default template (`{{input}}`) is always sensible. But, if you want, the arguments are still available.

##### Plain

- `input`: the input text specified by the user

##### Contact

- `input`: the name of the contact
- `name`: the name of the contact

##### Event

- `input`: the title of the event
- `title`: the title of the event
- `names`: an array of contact names

##### Project

- `input`: the name of the project
- `name`: the name of the project

#### Marked link resolver

The plugin also provides a custom preprocessor for [Marked 2](https://marked2app.com). This preprocessor replaces [[Note Links]] with actual working links to notes, to be opened in Marked. In other words, you can click through your notes this way within Marked itself.

If a link cannot be resolved, the text of the link will be italiced, and a question mark placed after it. That way you now what to fix right away.

Links to notes are resolved only once, and then cached on disk, in a file called `.marked`, at the root of the note repository. If you find that links don't work anymore because you've moved files around for a bit, just remove that file (or edit it; it's just YAML). Also, don't stick it in a Git repository.

### OmniFocus

I use OmniFocus to keep track of all projects and tasks in my life. As most OmniFocus users will have done, I've created top-level folders in the project tree, one for each area of responsibility. This is why the configuration looks like this:

```yaml
omnifocus:
    folder:
```

Where `folder` is the name of the folder to get projects from. It defaults to the name of the area.

In my work folder, where I have the biggest list of projects, I have created several subfolders. That doesn't matter for this workflow, because it gets all projects from all subfolders.

Projects are sorted in the order they appear in OmniFocus, but thanks to Alfred's smart filtering the more you use a project, the higher it will get on the list.

### Alfred

I like to store files for projects in a directory specific to that project. To that end, I've set up a directory under each area of focus, typically called `Projects` that has in turn a directory for each project I store files for. 

By enabling the `alfred` plugin on top of the OmniFocus plugin, project files can be browsed after selecting a project in Alfred. For now that's it. The plan is to later extend this with more functionality, for example for filing files directly into the right folder.

The configuration looks as follows:

```yaml
alfred:
    path:
```

With:

* `path` (optional): the subdirectory under the area's root directory to project files under. Defaults to `Projects`.

### Contacts

For me, the default Contacts app from Apple is good enough to manage all my contacts. For that to work across my areas of responsibility, I have set up several groups. (You can create and edit groups only on macOS, not on iOS, but once you have them, you can see and use them on all your devices!)

The configuration for Contacts looks as follows:

```yaml
contacts:
    group:
```

With:

- `group`: the name of the Contacts group to show contacts from. This defaults to the name of the area.

Contacts are sorted by name. But thanks to Alfred, the more you use a name, the higher it will get in the result list.

### Mail

The mail plugin is useful as an extension on top of the Contacts plugin,
to send e-mails to contacts.

The configuration looks as follows:

```yaml
mail:
    from:
```

With:

- `from`: in case you have several accounts configured in Mail, here you can configure which one to use for the area. The format of this field is `Name <address>`. Both the name of the address must match *exactly* what's configured in Mail. If the account is not found, Mail will fall back to its default.

### BitBar

In case you enable the BitBar action that's triggered when the focus changes (see below), you can override the name that the BitBar will show as a label. By default it's the name of the area.

The configuration for BitBar looks as follows:

```yaml
bitbar:
    label:
```

With:

- `label`: the text to show in the menu bar. (Hint: try emoji's!)


## Performing actions when the focus changes

Apart from the `areas` section, the configuration also supports an `actions` section, where you can list things that must happen whenever the focus changes. Currently there are three for:

1. Showing the name of the focused area in BitBar
2. Changing the desktop wallpaper
3. Changing the focus in OmniFocus

To enable all actions, add this to your configuration:

```yaml
actions:
    bitbar:
    wallpaper:
    omnifocus:
```

See below for details on configuration of each action.

### Show the name of the focused area in BitBar

[BitBar](https://getbitbar.com) is a nice utility that can show all kinds of texts in the menubar. I use it to show the name of the focused area, so that I always know for sure which area I'm working in. (That's getting more and more important, with any new plugin this tool gets.)

To enable this plugin, first:

- Install BitBar
- Symlink (!) to the `bitbar/focused-area.1d.rb` script from your BitBar plugins folder. **Do not copy the script, otherwise it won't work! Really do make a symlink!**

With this done, BitBar will already show the name of the focused area. But, you'll also want it to update itself whenever you change the focus. One way is polling, but I think that's silly for this use case (which is why the script ends with "1d", or: "refresh only once each day"). Instead, this suite can explicitly tell BitBar to refresh the name. To do that, add BitBar to the `actions` configuration, like:

```yaml
bitbar:
    plugin:
```

With:

- `plugin` (optional): the exact name of the plugin. You only need to set this if you changed the name of the symlink.

To override what BitBar shows in the menubar for the focused, see the BitBar configuration on area level, described above.

### Change the desktop wallpaper

To be able to see which area has the focus, it's possible to have the wallpaper on the current desktop change when changing the focus.

To enable this action, put it in the `actions` configuration, like:

```yaml
wallpaper:
    default:
```

With:

- `default` (optional): the path to the default picture to select when no specific picture is configured for an area. If you don't specifiy this value, you get the built-in High Sierra wallpaper.

This only enables the action. To make it do anything useful, you'll also want to configure a different wallpaper per area. You do that by adding a `wallpaper` section in each area, like so:

```yaml
wallpaper:
    path:
```

With:

- `path`: the path to the picture to use as desktop wallpaper. If not specified, the default will be used (see above).

Unfortunately this plugin works only on the desktop (space) that's currently being shown. If you have multiple desktops, you'll probably end up with different wallpapers. Since I use mostly one desktop at a time, I haven't come around to fixing this.

## Change the focus in OmniFocus

To set the focus to the group configured for the active area, simply add an action for OmniFocus:

```yaml
omnifocus:
```

That's it. The section has no default settings as of yet.

What this action does is pick the very first OmniFocus window it can find, and change its focus. For me this is just fine, since I always have exactly one OmniFocus window open anyway.

## Future steps

After the major overhaul in August 2019 (my summer holiday) I now have lots of new ideas, and a much easier way to implement them. Searching through notes, project files, and so on, it's all on the list now!

## About the icon

Icons made by [Freepik](http://www.freepik.com) from [Flaticon](https://www.flaticon.com) are licensed by a [Creative Commons BY 3.0](http://creativecommons.org/licenses/by/3.0).

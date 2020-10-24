# Vincent's Productivity Suite (for Alfred)

## Beware!

This project isn't called "*Vincent's* Productivity Suite for Alfred" for nothing. It might not be of any use to anyone but myself. But there's also no reason not to make it public; it could be useful to at least one other person beside me. So why not share?

But please remember that I've had exactly one person in mind while creating this suite: me. *Your mileage may vary!*

**Update October 2020**: This is version 3.0 of this tool. A little over one year since version 2.0 from August 2019! The biggest change on the outside is that commands are now grouped by the type of entity instead of by the plugin that provides them. That seems like a small change, but actually it makes the naming of the commands much more reasonable. Internally a lot has changed as well. There's now a much better decoupling of plugin classes from each other. There's more reuse between plugins, and plugins require less code. But, the configuration file hasn't actually changed.

## So, what's this all about?

This is a command-line interface (CLI) as well as an [Alfred](https://www.alfredapp.com) workflow on top of a set of Ruby scripts that make my daily computer work a lot more efficient. So, yes it's macOS only, and specifically it works with:

- Alfred (duh!)
- Obsidian
- iA Writer
- Bear
- OmniFocus
- Apple Contacts
- Apple Mail
- Apple Calendar
- Outlook Calendar
- Desktop wallpapers
- BitBar

A lot of activity at my computer consists of managing projects and tasks in OmniFocus, editing notes in Obsidian, writing e-mails in Mail and tracking people in Contacts. This workflow gives me the means to quickly edit notes and write e-mails and refer to projects and people, either through keyboard shortcuts, keywords, or snippets.

An important aspect of this tool is that it works with *areas of responsibility* (a [Getting Things Done (GTD)](https://gettingthingsdone.com) term), like work, family, sports, and software projects (like this one). At any time, exactly one area has focus. The CLI commands and the keyboard hotkeys, keywords and snippets for Alfred are always the same, but they do different things depending on the area that has the focus.

This CLI and Alfred workflow can:

- Set focus to an area and
    - Show the name of the area (or a nice label) in BitBar
    - Change the desktop wallpaper
    - Change the focus in Alfred
- Create new notes according to a template in iA Writer
- Browse documents in Alfred
- Browse reference material in Alfred
- Select a note and:
    - Open it in iA Writer / Obsidian / Bear for editing
    - Open it in Marked 2 for viewing
- Select a contact and:
    - Open it in Contacts
    - Create a note for it
    - Write an e-mail
    - Paste its name into the frontmost application
- Select a contact group and:
    - Create a note for it
    - Paste all contacts in it into the frontmost application
- Select a project and:
    - Open it in OmniFocus
    - Create a note for it
    - Browse project files with Alfred's built-in file browser
    - Paste its name into the frontmost application
- Select an event and:
    - Create a note for it
    - Paste its title into the frontmost application
    - Paste its attendees into the frontmost application

...and more!

## Installation

### Command-line

1. Clone this repository: `git clone https://github.com/voostindie/vincents-productivity-suite-for-alfred.git`
2. Go to the project root: `cd vincents-productivity-suite-for-alfred`
3. Install all required libraries: `bundle install`

**Important**: if you use macOS's system Ruby, you will need to use `sudo` for the last command! 

After all this, an `exe/vps help` should work. For easier use on the command-line you might want to add the `exe` directory to your `PATH`.

### Alfred

1. Go to Alfred's plugin directory: `cd ~/Library/Application\ Support/Alfred/Alfred.alfredpreferences/workflows`
2. Set up a symlink to the git clone: `ln -s /path/to/vincents-productivity-suite-for-alfred`

This will make the "Vincent's Productivity Suite" workflow automatically show up in Alfred and any `git pull` you do will immediately work in Alfred too.

### About Ruby versions

I'm taking care that this plugin works with the Ruby version that comes with the latest macOS. At the moment that's `2.6.3`. But I actually use the latest version of Ruby myself. To manage multiple Ruby versions I use [rbenv](https://github.com/rbenv/rbenv) as provided by [Homebrew](https://brew.sh).

To make Alfred use the same version of Ruby as the command-line tools, you can set up the `RUBY_PATH` workflow environment variable. For me it points to `/Users/vincent/.rbenv/shims`.

I haven't yet found a way to make the BitBar plugin use the same version. it always uses the system Ruby. But I'm making sure that also works.

## Alfred features

### Keywords and hotkeys

- `focus` / *ctrl* + *opt* + *cmd* + A: sets the focus to an area of responsibility.
- `flush`: flushes all caches for the focused area of responsibility.
- `note` / *ctrl* + *opt* + *cmd* + ,: creates a new note and opens it for editing in after you specify the title.
- `notes` / *ctrl* + *opt* + *cmd* + N: selects a note and shows an action list
- `today` / *ctrl* + *opt* + *cmd* + T: open today's note
- `contact` / *ctrl* + *opt* + *cmd* + C: selects a person from Contacts and shows an action list.
- `project` / *ctrl* + *opt* + *cmd* + P: selects a project from OmniFocus and shows an action list.
- `docs` / *ctrl* + *opt* + *cmd* + D: browses the Documents for the selected area in Alfred's file browser.
- `refs` / *ctrl* + *opt* + *cmd* + D: browses the Reference Material for the selected area in Alfred's file browser.

The list of actions available for a contact or project depends on the configuration of the focused area of responsibility. E.g. if iA Writer is enabled, the action to create a note on a contact, project or event will
automatically show up. 

### Snippets

Using the shared prefix `;` and no suffix for snippets:

- `;c`: copies a contact's name into the frontmost application.
- `;e`: copies an event's name into the frontmost application.
- `;p`: copies a project's name into the frontmost application.
- `;g`: copies all contacts from a contact group into the frontmost application
- `;n`: copies a note's ID into the frontmost application as a Wiki-link

### Icons

Unfortunately the icons in the Alfred workflow are hardcoded, and independent of the active plugins in an area. That means, for example, that you see an Obsidian icon, even if you configured the focused area to use iA Writer or Bear.

Of course you can change the icons yourself in the workflow through Alfred, but any changes made by me might override that at some point.

I have some idea on how to fix this, but haven't come around to trying this out and implementing it for real. It's not high on my priority list, because I use one set of tools across all areas. 

## How to configure

Create a file `.vpsrc` in your home folder and put something like this in there:

```yaml
areas:
   work:
        obsidian:
        omnifocus:
        contacts:
        calendar:
        alfred:
```

In case you were wondering: yes, this is [YAML](http://yaml.org).

This sets up a single *area of responsibility* with the Obsidian, OmniFocus, Contacts, Groups, Calendar and Alfred plugins enabled. These plugins all have default configurations, which is why you don't see anything here.

Once the configuration file exists, use `vps area focus` command in the Terminal, or the `focus` keyword (or ⌃⌥⌘-F) in Alfred to focus on a specific area.

## How to configure, in detail

The minimal configuration sample above means exactly the same as:

```yaml
areas:
    work:
        name: 'Work'
        root: '~/Work'
        obsidian:
            vault: 'Work'
            path: 'Notes'
        omnifocus:
            folder: 'Work'
        contacts:
            group: 'Work'
            prefix: 'Work -'
            cache: false
        calendar:
            name: 'Work'
        alfred:
            path: 'Projects'
        bitbar:
            label: 'Work'
```

Again, this is the exact same configuration as the one mentioned earlier. From this full example, you probably get the gist. Below there's detailed information on every separate plugin.

To define an additional area, just add one at the same level as 'work'. Name it however you like. To disable a certain feature for an area, remove its reference completely. E.g. if you remove the `obsidian` section, creating notes is not possible in that area. Alternatively you can select a different plugin that supports the same entities, to have the same shortcuts magically use a different application when you switch focus!

### Areas

An area looks as follow:

```yaml
key:
    name:
    root:
```

Where:

- `key`: the technical key. It doesn't really matter what it is, except that the name is derived from it, and that you'll have to use it in CLI when switching focus.
- `name`: the name of the area as shown in Alfred, and as used by the other features as default values. The default value is the `key`, capitalized.
- `root`: the directory under which all files for this reside on disk. The default is set to `~/<name>`.

### Obsidian (and note applications in general!)

Since October 2020 I'm using Obsidian for note keeping. It's my current editor of choice. It uses Markdown files on disk. I prefer that over having all my notes - thousands of them, collected over many years - hidden in some database.

The Obsidian plugin supports creating notes from scratch or from existing entities (contacts, events, projects) using *templates*. This templating system is explained here, but it **also applies to the other note keeping applications: iA Writer and Bear**. It works across all apps!

Overall instructions on the usage of Obsidian are:

```yaml
obsidian:
    vault:
    path:
    templates:
        default:
            filename: null
            title: '{{input}}'
            text: ''
            tags: []
```

With:

- `vault`: the name (or ID) of the Vault in Obsidian. This defaults to the area name.
- `path`: the root of the notes on disk, defaults to the root of the area followed by `Notes`. Tip: run `ls \`vps note root\`` to test!
- `templates`: these are explained below, in a separate section.

#### A note on IDs

This plugin works by assuming that the filename of each note, excluding its extension, is unique. That means that you can move notes around in subdirectories (for example to an archive folder) without breaking anything. 

What's there to break? Two things:

1. Note selections. If you do a `vps note list` you'll get all note IDs.
2. Note links. Pressing `;n` allows you to put a link to a note anywhere. This link is not actually a link, but just plaintext: `[[Like This]]`.

This is, by the way, fully compatible with how Obsidian works.

#### Templates

The note templating support in VPS allows you to set up templates for different types of entities, and for all parts of a note separately. Every individual property you can configure is actually a [Liquid template](https://shopify.github.io/liquid/).

Each note has a filename, a title, a text and a set of tags, the defaults are shown in the configuration of Obsidian above. 

You can:

- Change the defaults that apply to each type of note.
- Change settings for a specific type of note. 

The available note types are 

- `default` 
- `plain` (for the `note create` command)
- `contact` 
- `event`
- `project`
- `today` (for "Today's note")

Here's an example to give you a better idea:

```yaml
iawriter:
    templates:
        default:
                filename: '{{year}}-{{month}}-{{day}} {{input}}'
            title: '{{input}} {{day}}-{{month}}-{{year}}'
            tags:
                - 'journal/{{year}}'
                - 'todo'
        event:
            text: |
                ## Attendees
                
                {% for name in names %}- {{name}}
                {% endfor %}
```

This sets up the defaults to prepend the current date to every note filename in YY-MM-DD format, appends it to the title in DD-MM-YY format and also adds two tags. Since these are the defaults, this happens for every note type. But, for events, the text is override with a template that lists the attendees of the event.

The default template for the filename is `null` (in YAML). In that case VPS uses the template for the title instead. This saves you the trouble of having to define the same thing twice if you want filename and title to be the same.

The variables available to each template depend on the type of note you're configuring:

##### Every note type

- `day`: the number of the day in the current month, zero-padded
- `month`: the number of the current month
- `year`: the current year
- `week`: the number of the week in the current month, zero padded
- `query`: the arguments passed to the command as a string, separated by a space
- `input`: same as query

You can see here that the arguments are passed both in `query` and in `input`. That's on purpose. `input` is meant to be overridden by different note types so that the default template (`{{input}}`) is always sensible. Yet the original arguments are then still available, in `query`.

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

For projects managed in OmniFocus (see later) there's a special add-on: you can override the templates for the title, the text and the tags, *per project*. You do that by adding a "Yaml Back Matter" section at the end of the note of the project, like so:

```yaml
---
<plugin>:
    title: YOUR TITLE TEMPLATE
    text: YOUR TEXT HERE
    tags: YOUR TAGS HERE
```

Just to be sure: put this at the **bottom** of the note, not at the top!

You can have configurations for different plugins next to each other; VPS will pick the right one.

##### Today

- `input`: empty; there is no input text

Tip: Obsidian has a nice *Daily notes* plugin but if you use VPS I advise you to disable it and use VPS instead. Why? Because VPS gives you much more powerful templates, the template is stored outside of your vault (so, no garbage), and you can trigger it from any application using Alfred's global shortcut, not just from within Obsidian. By setting the filename template to `{{year}}-{{month}}-{{day}}` compatibility is guaranteed.

### iA Writer

Between April 2020 and October 2020 I've used iA Writer for all my note keeping, going back to trusty old Markdown on disk, after using Bear for a little under a year. 

The configuration values for iA Writer are:

```yaml
iawriter:
    location:
    path:
    token:
```

With:

- `location`: the location in iA Writer for this area, defaults to the name of the area.
- `path`: the root of the notes on disk, defaults to the root of the area followed by `Notes`.
- `token`: the authentication token required by iA Writer to control it using URL Commands. See iA Writer's Preferences. Make sure to check the *Enable URL Commands* settings and click on the *Manage...* button to acquire a copy of the token.

This is the same as just:

```yaml
iawriter:
```

With this default configuration it's not possible to create new notes. Make sure to set the `token` to be able to do that.

**And of course you can add a `templates` section!** See the Obsidian plugin for information on how that works.

### Bear

I've used Bear for a little under a year, and stopped using it in August 2020. This plugin still works however!

The configuration values for Bear are:

```yaml
bear:
    token:
```

With:

- `token`: the authentication token required by Bear to control it using URL Commands. To get your token, switch to Bear, select the Help menu and in there the API Token section.

**And of course you can add a `templates` section!** See the Obsidian plugin for information on how that works.

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

I store files on disk for an area in two separate directories:

1. Documents: everything I create myself (or collaborate on with others)
2. Reference Material: all documents I get from others as reference or support material.

By enabling the `alfred` plugin on top of the OmniFocus plugin, project files can be browsed inside the Reference Material directory.

The configuration looks as follows:

```yaml
alfred:
    documents:
    reference material:
```

With:

* `documents` (optional): the subdirectory under the area's root directory where documents are stored. Defaults to `Documents`.
* `reference material` (optional): the subdirectory under the area's root directory where documents are stored. Defaults to `Reference Material`.

#### Project Files

The Alfred plugin also adds a command to projects: you can browse the files belonging to that project.

The way the plugin resolves the directory on disk is by taking the path to the reference material (see previous section) and appending the name of the project to it.

In case of OmniFocus you can have a different specified in the note of the project, in the "YAML Back Matter", for example:

```yaml
---
alfred:
    folder: My Project
```

This will make Alfred browse the "My Project" folder in the reference material, even if the project is named differently.

### Apple Contacts

For me, the default Contacts app from Apple is good enough to manage all my contacts. For that to work across my areas of responsibility, I have set up several groups. (You can create and edit groups only on macOS, not on iOS, but once you have them, you can see and use them on all your devices!)

This plugin supports contacts as well as groups of contacts. 

The configuration for Contacts looks as follows:

```yaml
contacts:
    group:
    prefix:
    cache:
```

With:

- `group`: the name of the Contacts group to show contacts from. This defaults to the name of the area.
- `prefix`: the prefix of all names of the groups in this area. This defaults to the value of the `group` setting followed by "` - `"
- `cache`: whether caching of contacts is enabled or not. To prevent surprises this defaults to `false`

Contacts are sorted by name. But thanks to Alfred, the more you use a name, the higher it will get in the result list.

When groups are large, fetching their contacts can take some time. To speed up VPS, you can enable the cache. This stores output on disk, speeding up consecutive runs. The cache is pretty dumb; it doesn't automatically refresh in any way. To flush the cache, run `vps area flush`, which deletes all existing caches for the active area. Since I don't add or delete contacts that much, this is good enough for me!

### Apple Mail

The mail plugin adds a command to Contact and Group entities, by allowing you to send e-mails to them.

The configuration looks as follows:

```yaml
mail:
    from:
```

With:

- `from`: in case you have several accounts configured in Mail, here you can configure which one to use for the area. The format of this field is `Name <address>`. Both the name of the address must match *exactly* what's configured in Mail. If the account is not found, Mail will fall back to its default.

So, how do you quickly send a regular mail to a bunch of people? Stick them in a group, select the group in Alfred, select "Write an e-mail", and watch the magic happen ;-)

### Apple Calendar

This plugin uses SQL to fetch data from the the Apple Calendar cache, and is definitely not perfect. It doesn't always find all events for the day, even though it tries a nice of job of combining one-time events and recurring events. And it's fast.

It also fetches the attendees from the events, and makes them available to other commands.

The configuration looks as follows:

```yaml
calendar:
    name:
    me:
    replacements:
```

With:

- `name`: the name of the calendar to fetch events from.
- `me`: your own name, as it shows up in events. Filling this in ensures that your own name is filtered from the list of attendees for a meeting.
- `replacements`: a list of key-value pairs of people's names, see below.

#### Replacements

Although this plugin does a pretty good job of unmangling people's names from the Calendar, it doesn't always work. On top of that some people are simply published under the wrong name. With the replacements you have the option to fix that. For example:

```yaml
replacements:
    "Bert Simpson": "Bart Simpson"
```

This can save you a lot of repetitive manual work that's easy to forget. 

### Outlook Calendar

WARNING: this plugin is limited, in two ways:

1. It's sloooooow. The plugin uses scripting to fetch today's calendar events from Outlook. This takes many seconds, at least in my case.
2. It doesn't find all events for the day. Recurring items that have not been adapted for today are not found.

It's boggling my mind how hard it is to fetch all events that happen on a particular day. I would expect this to be one simple API call away. (This is just as true for Apple's Calendar, by the way.)

Anyway, although hampered, this plugin is still useful I think, because it allows me to create notes for events fairly quickly, including a list of all attendees. That saves me a lot of typing.

The configuration looks as follows:

```yaml
outlookcalendar:
    account: 
    calendar:
    me:
```

Where:

- `account`: the name of the account in Outlook. This defaults to the name of the area.
- `calendar`: the name of the calendar to fetch events from. This defaults to `Calendar`.
- `me`: your e-mail address. This defaults to nothing. Filling this in ensures that your own name is filtered from the list of attendees for a meeting.

### BitBar

In case you enable the BitBar action that's triggered when the focus changes (see below), you can override the name that the BitBar will show as a label. By default it's the name of the area.

The configuration for BitBar looks as follows:

```yaml
bitbar:
    label:
```

With:

- `label`: the text to show in the menu bar. (Hint: try emoji's!)


### Paste

The "Paste" plugin has no configuration and it's automatically enabled for all area's. What it does is provide a command named `paste` to various entity types, allowing you to paste it to the frontmost application. That can save you some typing in the long run.

For events it adds another command: `paste-attendees`, which pastes the names of all attendees from the selected event, straight from you calendar.

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

## About the icon

Icons made by [Freepik](http://www.freepik.com) from [Flaticon](https://www.flaticon.com) are licensed by a [Creative Commons BY 3.0](http://creativecommons.org/licenses/by/3.0).

# Vincent's Productivity Suite for Alfred

## Beware!

This project isn't called "*Vincent's* Productivity Suite for Alfred" for nothing. It might not be of any use to anyone but myself. But there's also no reason not to make it public; it could be useful to at least one other person beside me. So why not share?

But please remember that I've had exactly one person in mind while creating this suite: me.

"Your mileage may vary!"

## So, what's this all about?

This is is an [Alfred](https://www.alfredapp.com) workflow on top of a set of Ruby scripts that make my daily computer work a lot more efficient. So, yes it's Mac only, and specifically it works with:

- Alfred (duh!)
- Plaintext files (Markdown)
- OmniFocus
- Apple Contacts
- Apple Mail
- Microsoft Outlook 2016

A lot of activity at my computer consists of managing projects and tasks in OmniFocus, keeping notes in Markdown files, writing e-mails and tracking people in Contacts. This workflow gives me the means to quickly create notes and e-mails and refer to projects and people, either through keyboard shortcuts, keywords, or snippets.

This Alfred workflow can:

- Create new notes according to a template and open them for editing in a text editor.
- Select a person and:
	- Copy his/her name into the frontmost application
	- Create a note on that contact
	- Write an e-mail to the contact
	- View details on the contact
- Select a project and:
	- Copy its name into the frontmost application
	- Create a note on that project
	- Open the project in OmniFocus

It may not sound like much, but for me this is an enormous time saver.

Another important aspect of this Alfred workflow is that it works with *areas of responsibility* (a [Getting Things Done (GTD)](https://gettingthingsdone.com) term), like work, family, sports, and software projects (like this one). At any time, exactly one area is active. The keyboard shortcuts, keywords and snippets for Alfred are always the same, but they show different things depending on the area that has the focus. For example, I use a different e-mail client for work (Microsoft Outlook) than for all other areas (Apple Mail).

## Alfred features

### Keywords and hotkeys

- `focus` / ⌃⌥⌘-F: sets the focus to an area of responsibility
- `note` / ⌃⌥⌘-N: creates a new note and opens it for editing after you specify the title.
- `contact` / ⌃⌥⌘-C: select a person from Contacts and:
	- ↵: write an e-mail to this person
	- ⌘↵: show this person in the Contact Viewer
	- ⌥↵: write a note on this person
- `project` / ⌃⌥⌘-P: select a project from OmniFocus and:
	- ↵: show this project in OmniFocus
	- ⌥↵: write a note on this project

The alternative action for writing a note is available only if Markdown notes are configured for the focused area.

### Snippets

Using the shared prefix `;` and no suffix for snippets:

- `;c`: copies a person's name into the frontmost application.
- `;p`: copies a project's name into the frontmost application.

### Contact action

The workflow contains a Contact action *Write e-mail using the focused area's preferred mail client'* that you can link to the *Email* field in Aflred's Contacts feature. Once done, after selecting an e-mail address in Alfred Contact Viewer, pressing ↵ will create a new blank message using the the e-mail client that is configured for the focused area. Additionally, for Apple Mail, it's possible to configure the sender address per area. See the documentation of the Contacts feature below.

## How to configure

Create a file `.vpsrc` in your home folder and put something like this in there:

	areas:
		work:
			markdown-notes:
			omnifocus:
			contacts:
			
In case you were wondering: yes, this is [YAML](http://yaml.org).

This sets up a single *area of responsibility* with all available features -- Markdown notes, OmniFocus and Contacts -- enabled. All features have default configurations, which is why you don't see anything here.

Once the configuration file exists, use the `focus` keyword (or ⌃⌥⌘-F) in Alfred to focus on a specific area.

## How to configure, in detail

The minimal configuration sample above means exactly the same as:

	areas:
		work:
			name: 'Work'
			root: '~/Work'
			markdown-notes:
				path: 'Notes'
				extension: 'md'
				editor: 'open'
				name-template: '$year-$month-$day-$slug'
				file-template: |
					---
					date: $day-$month-$year
					---
					# $title
			omnifocus:
				folder: 'Work'
			contacts:
				group: 'Work'
				mail:
					client: 'Mail'
					from: null
				
Again, this is the exact same configuration as the one mentioned earlier. From this full example, you probably get the gist. Below there's detailed information on every separate feature.

To define an additional area, just add one at the same level as 'work'. Name it however you like. To disable a certain feature for an area, remove its reference completely. E.g. if you remove the `markdown-notes` section, creating notes is not possible in that area.

### Areas

An area looks as follow:

	key:
		name: 
		root:
		
Where:

- `key`: the technical key to use internally. It doesn't really matter what you name an area, except that the name is derived from it.
- `name`: the name of the area as shown in Alfred, and as used by the other features as default values. The default value is the `key`, capitalized.
- `root`: the directory under which all files for this reside on disk. The default is set to `~/<name>`.

### Markdown notes

I write all my notes in separate plaintext files. (I've tried Evernote, Bear, Agenda, Ulysses, VoodooPad... The list goes on. All great apps, but they don't work for me. In the end I always gravitate back to good ol' trusty plaintext. Call me a fossil.) I store these files in a specific directory structure. Depending on the area of responsibility this structure is less or more complex: where I write a lot of notes (e.g. work) I have a more complex directory structure than where I write fewer notes (e.g. my personal journal).

Each note is intended to be self-contained. The filename or the directory structure the file resides in are not very important. That's why I put a bit of YAML front matter in each file. At least the date is in there. (By the way, this makes this workflow also a great tool for writing blog posts for static site generators like [Hugo](https://gohugo.io); just saying!)

The configuration for Markdown notes within an area looks as follows:

	markdown-notes:
		path:
		editor:
		extension:
		name-template:
		file-template
		
Where:

- `path` is the subdirectory under the area's root directory to store notes under. Defaults to `Notes`.
- `editor` is the Terminal command to use to open the text editor. Defaults to `open`.
- `extension` is the file extension to use for notes. Defaults to `md`.
- `name-template`: is the template to use to create new file names. See below.
- `file-template`: is the template to use as file contents for new files. Again, see below.

### Templates

The name and file templates are pieces of text that may contain special placeholders. These placeholders are replaced by dynamically computed values. The available placeholders and their meaning are:

- `$day`: the number of the day in the current month, zero-padded
- `$month`: the number of the current month
- `$year`: the current year
- `$week`: the number of the week in the current month, zero padded
- `$title`: the title of the note entered in Alfred
- `$safe_title`: the title of the note with all special characters removed, for use in filenames
- `$slug`: the $safe_title set to lowercase and with spaces replaced by hyphens

All that the scripts do is replace these placeholders with their actual values. Nothing fancy; pure text replacement. No calculations, no filters, nothing. The scripts also don't protect you from silly mistakes, like formatting dates incorrectly, or using the title in filenames. So, take care.

### Name template

The default name template is:

	$year-$month-$day-$slug

This means that all notes will reside in the same directory. For example, a note with title *Yes! It works!* written on August 23, 2018 will be created at the path

	~/Area/Notes/2018-08-23-yes-it-works.md
	
Here `~/Area` is the area's root directory, `Notes` is the path to the Markdown notes, and `md` is the file extension.

For work, where I write lots of notes per day and want to be able to browse them by week, I use:

	$year/Week $week/$year-$month-$day/$safe_title
	
So the same note as before will now end up at the path:

	~/Area/Notes/2018/Week 34/2018-08-23/Yes It Works.md

### File template

The default file template is:

	---
	date: $day-$month-$year
	---
	# $title

I always have exactly one heading at level 1 in my Markdown notes: the title of the note. Others prefer to have the title in the front matter, and use headings for other things. And maybe the slug is stored in the front matter as well. That's easy to set up, with a template such as the following:

	---
	date: $day-$month-$year
	title: $title
	slug: $slug
	---
	# 

Whatever floats your boat!

### OmniFocus

I use OmniFocus to keep track of all projects and tasks in my life. As most OmniFocus users will have done, I've created top-level folders in the project tree, one for each area of responsibility. This is why the configuration looks like this:

	omnifocus:
		folder:

Where `folder` is the name of the folder to get projects from. It defaults to the name of the area.

In my work folder, where I have the biggest list of projects, I have created several subfolders. That doesn't matter for this workflow, because it gets all projects from all subfolders.

Projects are sorted in the order they appear in OmniFocus, but thanks to Alfred's smart filtering the more you use a project, the higher it will get on the list.

### Contacts

For me, the default Contacts app from Apple is good enough to manage all my contacts. For that to work across my areas of responsibility, I set up several groups. (You still can't create or edit groups on iOS, but once you have them, you do see them and you can use them there!)

The configuration for Contacts looks as follows:

	contacts:
		group:
		mail:
			client:
			from:
			
With:

- `group`: the name of the Contacts group to show contacts from. This defaults to the name of the area.
- `client`: the name of the mail client you use for this area. The default is `Mail`. Alternatively, `Microsoft Outlook` is also supported.
- `from`: **Only for Apple Mail!** In case you have several accounts configured in Mail, here you can configure which one to use for the area. The format of this field is `Name <address>`. Both the name of the address must match *exactly* what's configured in Mail.  If the account is not found, Mail will fall back on its default one.

Contacts are sorted by name. But thanks to Alfred, the more you use a name, the higher it will get.
		
## Future steps

I have some ideas on improvements and additions for this workflow, specifically for managing files on disk. For each area of responsibility I typically have a `Projects` directory (within the root directory) in which I store my own documents and the reference material per project. Currently I maintain that directory structure by hand, completely. With this worklow as a basis, I should be able to store and find files under the right structure fully automatically. I'm still thinking on it though. 

(Wild idea: when a project is done (in OmniFocus) why not archive the project directory (move it), and add extracts from other sources to it, like my notes, and the bookmarks I tagged for the project in Pinboard, and the articles I added to Pocket, and the actual list of actions I completed from OmniFocus? In a fully automated manner, of course!)

## About the icon

Icons made by [Freepik](http://www.freepik.com) from [Flaticon](https://www.flaticon.com) are licensed by a [Creative Commons BY 3.0](http://creativecommons.org/licenses/by/3.0).

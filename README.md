# editor-settings package

Adds support for per-language, file extension and directory editor settings.

## How to use it
### Global configuration

Open a file you'd like to configure the settings for, ensure that its grammar is correctly
detected (look at the grammar selector in the bottom right corner of Atom or press ⌃⇧L)
and open the command palette (⌘⇧P or ⌃⇧P). Type `Editor Settings: Open Grammar Config`
and press ⏎.

A new `.cson` file for the grammar of the file you had open should show with the current
editor settings for the given grammar. Edit it and save.

The language/grammar settings files are saved in the `grammar-config` directory located
in the main Atom configuration directory with a lower-case file name format.

For example, the config file for CoffeeScript would be `coffeescript.cson`.

### Local configuration

For a per directory based configuration, you can create a `.editor-settings` file in the
concerned directories.

### Supported settings

The API for setting editor settings currently only supports:

- Tab length (tabLength)
- Soft/hard tabs (softTabs)
- Soft wrap (softWrap)
- Encoding (encoding)
- Atom and Syntax theme (themes)

### Example configuration

The following example is for CoffeeScript, it sets the tab length to `2`, but if
the file extension is `.cson` it sets it to `4`.

    tabLength: 2
    extensionConfig:
      cson:
        tabLength: 4

#### Experimental settings:

    fontFamily: 'Source Code Pro'
    grammarConfig:
      'GitHub Markdown':
        fontFamily: 'monospace'


#### Example project and directory configuration

All options not nested under a specific grammar are used for all grammar and extensions.

    tabLength: 2
    themes: ['atom-light-ui', 'atom-light-syntax']
    grammarConfig:
      'PHP':
        tabLength: 4
        softTabs: true
        extensionConfig:
          phtml:
            softTabs: false

## Features

- Per-language support
- Per-file extension support
- Per-project support
- Per-directory support

### Planned

- Change configuration directory

If there is a feature you'd like added simply create an issue or fork and implement it and send a pull request.

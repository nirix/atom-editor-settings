# editor-settings package

Adds support for per-language, file extension and directory editor settings.

## How to use it

The language/grammar settings files are saved in the `grammar-config` directory located
in the main Atom configuration directory with a lower-case file name format.

For example, the config file for CoffeeScript would be `coffeescript.cson`.

### Supported settings

The API for setting editor settings currently only supports:

- Font family (fontFamily)
- Font size (fontSize)
- Tab length (tabLength)
- Soft/hard tabs (softTabs)
- Soft wrap (softWrap)
- Invisible characters (invisibles)
- Showing/hiding invisibles (showInvisibles)
- Showing/hiding indent guide (showIndentGuide)
- Encoding (encoding)

### Example configuration

The following example is for CoffeeScript, it sets the tab length and shows invisible
characters, however it hides invisible characters if the file extension is `.cson`.

    'tabLength': 2
    'showInvisibles': true
    'invisibles':
      'space': '*'
      'tab': '-'
    'extensionConfig':
      'cson':
        'showInvisibles': false

#### Example project configuration

All options not nested under a specific grammar are used for all grammar and extensions.

    'tabLength': 2
    'php'
      'tabLength': 4
      'softTabs': true
      'extensionConfig':
        'phtml':
          'softTabs': false

## Features

- Per-language support
- Per-file extension support
- Per-project support
- Per-directory support

If there is a feature you'd like added simply create an issue or fork and implement it and send a pull request.

# editor-settings package

Adds support for per-language, file extension and directory editor settings.

## How to use it

The language/grammar settings files are saved in the `grammar-config` directory located
in the main Atom configuration directory with a lower-case file name format.

For example, the config file for CoffeeScript would be `coffeescript.cson`.

### Supported settings

The API for setting editor settings currently only supports:

- Font family
- Font size
- Tab length
- Soft/hard tabs
- Soft wrap
- Invisible characters
- Showing/hiding invisibles
- Showing/hiding indent guide

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

## Features

### Completed

- Per-language support
- Per-file extension support

### Planned

- Per-directory support

## Not so frequently asked questions

#### How will per-directory support work?

Still thinking about that, there are two ways of doing it. The first being scanning
each directory in the files path for a config file and stopping there.

Where as the second would continue scanning until it reaches the topmost directory
then merging the them together. The settings in the config file closest to the file
takes precedence.

#### Why no per-project support

The per-directory feature can be used as per-project simply by placing the config
file in the projects root directory.

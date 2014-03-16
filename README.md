# editor-settings package

Adds support for per-language, file extension and directory editor settings.

## How to use it

The language/grammar settings files are saved in the `grammar-config` directory
located in the main Atom configuration directory.

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

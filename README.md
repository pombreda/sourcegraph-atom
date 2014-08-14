# Sourcegraph Atom Integration
A plugin for Github's Atom editor that integrates with srclib and the Sourcegraph API.

Current Features
- Jump To Definition
- See Documentation
- Find Usage Examples on Sourcegraph

## Installation
### Requirements
This plugin requries that the srclib tool is installed, as well
as the language toolchains for the individual languages that you wish to use.

Follow the [srclib installation instructions here](http://srclib.org/gettingstarted/#install-srclib).

### Installing from APM
### Installing from Source

Note: this plugin queries Sourcegraph. Your private code is never uploaded,
but information about the identifier under the cursor is
used to construct the query. This includes information such as the clone URL of
the repository you're currently in, the filename and character position, and
the name of the identifier's definition.

## TODO
- Add Sourcegraph Search Command
- Publish to APM

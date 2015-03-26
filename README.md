# Sourcegraph-Atom

A plugin for Github's Atom editor that integrates with srclib and the Sourcegraph API.

![Screenshot](https://raw.githubusercontent.com/sourcegraph/sourcegraph-atom/master/screenshot.png)

## Current Features:

 - Jump To Definition
 - See Documentation
 - Find Usage Examples on Sourcegraph

## Installation

### Requirements

This plugin requries that the srclib tool is installed, as well
as the language toolchains for the individual languages that you wish to use.

Follow the [srclib installation instructions here](http://srclib.org/gettingstarted/#install-srclib).

### Installing from APM

To install from APM you can either install from command line:

```bash
apm install sourcegraph-atom
```

or open Atom and go to `Preferences > Packages`, search for `sourcegraph-atom`, and install it.

> This plugin queries Sourcegraph. Your private code is never uploaded,
> but information about the identifier under the cursor is
> used to construct the query. This includes information such as the clone URL of
> the repository you're currently in, the filename and character position, and
> the name of the identifier's definition.

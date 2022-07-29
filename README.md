# prettyping

[Donation - buy me a coffee](https://denilson.sa.nom.br/donate.html)

`prettyping` is a wrapper around the standard `ping` tool with the objective of
making the output prettier, more colorful, more compact, and easier to read.

`prettyping` runs the standard `ping` in the background and parses its output,
showing the ping responses in a *graphical* way at the terminal (by using
colors and Unicode characters).

`prettyping` is written in `bash` and `awk`, and is reported to work on many
different systems (Linux, Mac OS X, BSD…), as well as running on different
versions of `awk` (`gawk`, `mawk`, `nawk`, `busybox awk`).

Read about the history of this project, as well as detailed information,
screenshots, videos at: <http://denilsonsa.github.io/prettyping/>

## Requirements

* `bash` (tested on 4.20, should work on versions as old as 2008)
* `awk` (either `gawk`, `mawk`, `nawk` or `busybox awk`; should work on `gawk`
   versions as old as 2008; should probably work on any other awk
   implementation)
* `ping` (from `iputils`, or any other version that prints essentially the same
   output, like Mac OS X ping or [oping][])
* Optional dependency on `stty` or `tput` to auto-detect the terminal size.

## Installation

### Manual

1. Download [prettyping][] script and save it anywhere.
2. Make it executable: `chmod +x prettyping`

That's all! No root permission is required. You can save and run it from any
directory. As long as your user can run `ping`, `bash` and `awk`, then
`prettyping` will work.

### GitHub

Alternatively, you can download the latest tarball from GitHub: [![Latest release](https://img.shields.io/github/release/denilsonsa/prettyping.svg)](https://github.com/denilsonsa/prettyping/releases/latest)

For people building a `prettyping` package (for any Linux distro or for Mac OS X), just install the `prettyping` script into `/usr/bin/`, or whatever
directory is appropriate. No other file is necessary.

### ZSH Frameworks

#### Zgenom

If you're using [Zgenom](https://github.com/jandamm/zgenom):

1. Add `zgenom load unixorn/prettyping` to your `.zshrc` along with your other `zgenom load` commands.
2. `zgenom reset && zgenom save`

#### Antigen

If you're using [Antigen](https://github.com/zsh-users/antigen):

1. Add `antigen bundle unixorn/prettyping` to your `.zshrc` where you've listed your other plugins.
2. Close and reopen your Terminal/iTerm window to **refresh context** and use the plugin. Alternatively, you can run `antigen bundle unixorn/prettyping` in a running shell to have `antigen` load the new plugin.

[oping]: http://verplant.org/liboping/
[prettyping]: https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping

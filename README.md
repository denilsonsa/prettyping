[![Donate using PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=denilsonsa%40gmail%2ecom&lc=US&item_name=Denilson&item_number=prettyping&currency_code=BRL) [![Flattr this project](https://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=denilsonsa&url=https%3A%2F%2Fgithub.com%2Fdenilsonsa%2Fprettyping&title=prettyping&description=prettyping+is+a+wrapper+around+the+standard+ping+tool+with+the+objective+of+making+the+output+prettier,+more+colorful,+more+compact,+and+easier+to+read.&tags=github&category=software)

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

Requirements
============

* `bash` (tested on 4.20, should work on versions as old as 2008)
* `awk` (either `gawk`, `mawk`, `nawk` or `busybox awk`; should work on `gawk`
   versions as old as 2008; should probably work on any other awk
   implementation)
* `ping` (from `iputils`, or any other version that prints essentially the same
   output, like Mac OS X ping or [oping][])

Installation
============

1. Download [prettyping][] script and save it anywhere.
2. Make it executable: `chmod +x prettyping`

That's all! No root permission is required. You can save and run it from any
directory. As long as your user can run `ping`, `bash` and `awk`, then
`prettyping` will work.

For people building a `prettyping` package (for any Linux distro or for Mac OS
X), just install the `prettyping` script into `/usr/bin/`, or whatever
directory is appropriate. No other file is necessary.

[oping]: http://verplant.org/liboping/
[prettyping]: https://github.com/denilsonsa/prettyping/raw/master/prettyping

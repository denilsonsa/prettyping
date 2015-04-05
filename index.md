---
layout: page
---
Do you run `ping` tool very often? Do you find yourself squeezing your eyes to see if a packet has been lost? Do you want to have a better view of the latency and of the lost packets over time?

Then `prettyping` is the tool for you!

`prettyping` runs the standard `ping` in the background and parses its output, showing the ping responses in a *graphical* way at the terminal (by using colors and Unicode characters). Don't have support for UTF-8 in your terminal? No problem, you can disable it and use standard ASCII characters instead. Don't have support for colors? No problem, you can also disable them.

`prettyping` is written in `bash` and `awk`, and should work out-of-the-box in most systems (Linux, BSD, Mac OS X, …). It is self-contained in only one file, so it is trivial to install and run.

## Quick install and run

```
curl -O https://github.com/denilsonsa/prettyping/raw/master/prettyping
chmod +x prettyping
./prettyping whatever.host.you.want.to.ping
```

Check out the [prettyping repository on GitHub][prettyping].

## Features

* Detects missing/lost packets and marks them at the output.
* Shows live statistics, updated after each response is received.
* Two sets of statistics are calculated: one for the most recent 60 responses, and another for all responses since the start of the script.
* Correctly handles "unknown" lines, such as error messages, without messing up the output.
* Detects repeated messages and avoids printing them repeatedly.
* Fast startup, very few and lightweight dependencies.
* No installation required, just run the script from anywhere (and make sure you have the 3 dependencies, most Linux distros already have them).
* Sane defaults, auto-detects terminal width, auto-detects if the output is a terminal. Basically, just run the script and don't worry about the options until you need to.
* Options not recognized by prettyping are passed to the ping tool. As a wrapper, you can use the most common ping parameters in prettyping as well.
* As a wrapper, it can run as normal user. Root access is NOT required.
* The output can be redirected to a file (using shell redirection or pipeline). In such mode, prettyping will avoid using cursor-control escape codes.
* Colorful output (can be disabled by command-line option).
* Graphical output of the latency using unicode characters (can be disabled by command-line option).
* Intuitive, easy-to-read output.
* It looks pretty!

## What does it look like?

Animated GIF (sped up to 4×) showing what `prettyping` can do:<br>
![Animated GIF (4× the actual speed)](prettyping-4x.gif)

[YouTube demonstration by Yu-Jie Lin](https://youtu.be/ziEMY1BcikM):<br>
<iframe width="560" height="315" src="https://www.youtube.com/embed/ziEMY1BcikM?autohide=1" frameborder="0" allowfullscreen></iframe>

## Comparison between tools

|                      | [ping][iputils] | [mtr][] | [oping][] | [prettyping][] |
|----------------------|-----------------|---------|-----------|----------------|
| Programming language | C | C | C | bash and awk |
| How easy to install? | Should already come with your system | Medium (C compiler + root privileges) | Medium (C compiler + ncurses + root privileges) | Trivial (just one file) |
| Requires root to install? | Yes (suid) | Yes (suid) | Yes (suid) | No (wrapper for ping, which is suid) |
| How many hosts?      | One | All hosts in path | One or more | One |
| Minimum ping interval | 0.2s for non-root users | 1.0s for non-root users | 0.001s | The same as `ping` or `oping` |
| How easy to read the latency? | Precise individual values are printed, average is only printed upon exit | Statistics for each host are updated on each response, plus a non-intuitive legend for the graph | `oping`: Looks the same as `ping`<br>`noping`: Enhances the normal output with colors and live statistics and `prettyping`-inspired graphics | Statistics for each host are updated on each response, plus an intuitive and colorful graph |
| How easy to see lost packets? | Hard (lost packages aren't printed on the Linux `ping`) | Easy (`?` at the graphic, plus listed in the statistics) | Very easy (`oping` prints missing responses, `noping` additionally shows them in the graph) | Very easy (red `!` at the graphic, plus listed in the statistics) |
| Statistics | Only shown upon exit | Updated in real-time, considers all responses since the beginning of the run | `oping`: Only shown upon exit<br>`noping`: Updated in real-time, considers all responses since the beginning of the run | Updated in real-time, shows statistics for all responses since the beginning of the run, as well as statistics for the most recent 60 responses |
| Redirecting output to file | Yes | No | `oping`: Yes<br>`noping`: No | Yes |
| Terminal behavior | Standard output | Curses full-screen app | `oping`: Standard output<br>`noping`: Curses full-screen app | Standard output with optional colors and VT100 escapes |
| Terminal dimensions | Ignores the terminal size | Reacts immediately to the terminal size | `oping`: Ignores the terminal size<br>`noping`: Adapts to the terminal size | Adapts to the terminal size (only the future responses, the past responses are not changed) |

## FAQ and troubleshooting

**I don't see the block characters, all I see are weird characters such as "â..".**

Your terminal does not seem to support UTF-8. Configure your terminal correctly, switch to another terminal, or just use the `--nounicode` option. Also, [do not copy-paste the code from the browser](http://www.reddit.com/r/linux/comments/1op98a/prettypingsh_a_better_ui_for_watching_ping/ccuefny), download it instead.

**What if I am using [PuTTY][]?**

Inside *Window → Translation*, set the remote character set to *UTF-8* (as in [this screenshot](http://i.imgur.com/Q7LI5MW.png) by [battery_go user on reddit](http://www.reddit.com/r/linux/comments/1op98a/prettypingsh_a_better_ui_for_watching_ping/ccueh06])).

## A bit of history

`prettyping` was originally written in January of 2008, while I was working at [Vialink][]. I noticed that, very often, we were looking at the output of the ping tool to measure the quality of network links, by looking at a combination of packet loss ratio and latency. However, the standard ping output is too verbose, making it hard to have a quick glance at latency. Not just that, but missing/lost packets are not reported at all. Finally, the statistics of the run are only printed at the very end, after ping finishes running. This helpful piece of information should be available all the time.

I observed a common use-case, a common pattern in our daily work, and I noticed that our workflow could have been improved by having better tools. And so I built a better tool. (By the way, this paragraph describes something I do ALL the time.)

Thus `prettyping` was born. And it received essentially no updates after 2008.

In October 2013, I discovered the [spark shell script in github][spark], which made me want to implement a similar output in `prettyping`. After a few days, I had implemented many features I wanted to implement for a long time, in addition to the spark-like output. After finishing all these features and polishing them, I submitted this tool to [reddit /r/linux][reddit1] and to [/r/commandline][reddit2] and received a lot of positive feedback.

Afterwards, it was fixed to works on multiple `awk` implementations, to work on Mac OS X (in addition to Linux). People have even made packages for some Linux distros and for Mac OS X brew.

On April 2015, this tool got [its own repository on GitHub][prettyping] (it was previously on [small_scripts repository on Bitbucket][small_scripts]).

## Other interesting projects

* [mtr][] - Combines the functionality of the `traceroute` and `ping`, shows responses for all hosts in the path.
* [oping][] - `liboping` is a C library to generate ICMP echo requests; `oping` is a tool that behaves just like the standard `ping`, but detects and prints missing responses, and also allows pinging multiple hosts simultaneously; `noping` is a tool with ncurses interface with the same features as `oping`, but also highlighting the rtt value and showing live statistics. Recently, it has included the same graphical output feature as `prettyping`.
* [spark][] - Draws graphs in the shell using Unicode characters.

[iputils]: http://www.skbuff.net/iputils/
[mtr]: http://www.bitwizard.nl/mtr/
[oping]: http://noping.cc/
[prettyping]: https://github.com/denilsonsa/prettyping
[PuTTY]: http://www.chiark.greenend.org.uk/~sgtatham/putty/
[reddit1]: https://www.reddit.com/r/linux/comments/1op98a/prettypingsh_a_better_ui_for_watching_ping/
[reddit2]: https://www.reddit.com/r/commandline/comments/1oq5nz/prettypingsh_a_better_ui_for_watching_ping/
[small_scripts]: http://bitbucket.org/denilsonsa/small_scripts/
[spark]: https://github.com/holman/spark
[Vialink]: http://www.vialink.com.br/

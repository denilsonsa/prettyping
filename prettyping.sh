#!/bin/bash
#
# Written by Denilson Figueiredo de Sá <denilsonsa@gmail.com>
# MIT license
#
# Requirements:
# * bash (tested on 4.20, should work on older versions too)
# * awk (works with GNU awk, nawk, busybox awk, mawk)
# * ping (from iputils)
#
# More information:
# http://my.opera.com/CrazyTerabyte/blog/2013/10/18/prettyping-sh-a-better-ui-for-watching-ping-responses
# http://www.reddit.com/r/linux/comments/1op98a/prettypingsh_a_better_ui_for_watching_ping/
# https://bitbucket.org/denilsonsa/small_scripts/

# TODO: Detect the following kinds of message and avoid printing it repeatedly.
# From 192.168.1.11: icmp_seq=4 Destination Host Unreachable
# Request timeout for icmp_seq 378
#
# TODO: print the destination (also) at the bottom bar. Useful after leaving
# the script running for quite some time.
#
# TODO: Implement audible ping.
#
# TODO: Autodetect the width of printf numbers, so they will always line up correctly.
#
# TODO: Test the behavior of this script upon receiving out-of-order packets, like these:
#   http://www.blug.linux.no/rfc1149/pinglogg.txt
#
# TODO? How will prettyping behave if it receives a duplicate response?

print_help() {
	cat << EOF
Usage: $MYNAME [prettyping parameters] <standard ping parameters>

This script is a wrapper around the system's "ping" tool. It will substitute
each ping response line by a colored character, giving a very compact overview
of the ping responses.

prettyping parameters:
  --[no]color      Enable/disable color output. (default: enabled)
  --[no]multicolor Enable/disable multi-color unicode output. Has no effect if
                     either color or unicode is disabled. (default: enabled)
  --[no]unicode    Enable/disable unicode characters. (default: enabled)
  --[no]legend     Enable/disable the latency legend. (default: enabled)
  --[no]terminal   Force the output designed to a terminal. (default: auto)
  --last <n>       Use the last "n" pings at the statistics line. (default: 60)
  --columns <n>    Override auto-detection of terminal dimensions.
  --lines <n>      Override auto-detection of terminal dimensions.
  --rttmin <n>     Minimum RTT represented in the unicode graph. (default: auto)
  --rttmax <n>     Maximum RTT represented in the unicode graph. (default: auto)
  --awkbin <exec>  Override the awk interpreter. (default: awk)
  --pingbin <exec> Override the ping tool. (default: ping)
  -6               Shortcut for: --pingbin ping6

ping parameters handled by prettyping:
  -a  Audible ping is not implemented yet.
  -f  Flood mode is not allowed in prettyping.
  -q  Quiet output is not allowed in prettyping.
  -R  Record route mode is not allowed in prettyping.
  -v  Verbose output seems to be the default mode in ping.

All other parameters are passed directly to ping.
EOF
}

# Thanks to people at #bash who pointed me at
# http://bash-hackers.org/wiki/doku.php/scripting/posparams
parse_arguments() {
	USE_COLOR=1
	USE_MULTICOLOR=1
	USE_UNICODE=1
	USE_LEGEND=1

	if [ -t 1 ]; then
		IS_TERMINAL=1
	else
		IS_TERMINAL=0
	fi

	LAST_N=60
	OVERRIDE_COLUMNS=0
	OVERRIDE_LINES=0
	RTT_MIN=auto
	RTT_MAX=auto

	PING_BIN="ping"
	#PING_BIN="./mockping.awk"
	PING_PARAMS=( )

	AWK_BIN="awk"
	AWK_PARAMS=( )

	while [[ $# != 0 ]] ; do
		case "$1" in
			-h | -help | --help )
				print_help
				exit
				;;

			# Forbidden ping parameters within prettyping:
			-f )
				echo "${MYNAME}: You can't use the -f (flood) option."
				exit 1
				;;
			-R )
				# -R prints extra information at each ping response.
				echo "${MYNAME}: You can't use the -R (record route) option."
				exit 1
				;;
			-q )
				echo "${MYNAME}: You can't use the -q (quiet) option."
				exit 1
				;;
			-v )
				# -v enables verbose output. However, it seems the output with
				# or without this option is the same. Anyway, prettyping will
				# strip this parameter.
				;;
			# Note:
			#  Small values for -s parameter prevents ping from being able to
			#  calculate RTT.

			# New parameters:
			-a )
				# TODO: Implement audible ping for responses or for missing packets
				;;

			-color        | --color        ) USE_COLOR=1 ;;
			-nocolor      | --nocolor      ) USE_COLOR=0 ;;
			-multicolor   | --multicolor   ) USE_MULTICOLOR=1 ;;
			-nomulticolor | --nomulticolor ) USE_MULTICOLOR=0 ;;
			-unicode      | --unicode      ) USE_UNICODE=1 ;;
			-nounicode    | --nounicode    ) USE_UNICODE=0 ;;
			-legend       | --legend       ) USE_LEGEND=1 ;;
			-nolegend     | --nolegend     ) USE_LEGEND=0 ;;
			-terminal     | --terminal     ) IS_TERMINAL=1 ;;
			-noterminal   | --noterminal   ) IS_TERMINAL=0 ;;

			-awkbin  | --awkbin  ) AWK_BIN="$2"  ; shift ;;
			-pingbin | --pingbin ) PING_BIN="$2" ; shift ;;
			-6 ) PING_BIN="ping6" ;;

			#TODO: Check if these parameters are numbers.
			-last    | --last    ) LAST_N="$2"           ; shift ;;
			-columns | --columns ) OVERRIDE_COLUMNS="$2" ; shift ;;
			-lines   | --lines   ) OVERRIDE_LINES="$2"   ; shift ;;
			-rttmin  | --rttmin  ) RTT_MIN="$2"          ; shift ;;
			-rttmax  | --rttmax  ) RTT_MAX="$2"          ; shift ;;

			* )
				PING_PARAMS+=("$1")
				;;
		esac
		shift
	done

	if [[ "${RTT_MIN}" -gt 0 && "${RTT_MAX}" -gt 0 && "${RTT_MIN}" -ge "${RTT_MAX}" ]] ; then
		echo "${MYNAME}: Invalid --rttmin and -rttmax values."
		exit 1
	fi

	if [[ "${#PING_PARAMS[@]}" = 0 ]] ; then
		echo "${MYNAME}: Missing parameters, use --help for instructions."
		exit 1
	fi

	# Workaround for mawk:
	# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=593504
	local version="$(echo | "${AWK_BIN}" -W version 2>&1)"
	if [[ "${version}" == mawk* ]] ; then
		AWK_PARAMS+=(-W interactive)
	fi
}

MYNAME=`basename "$0"`
parse_arguments "$@"


export LC_ALL=C

# Warning! Ugly code ahead!
# The code is so ugly that the comments explaining it are
# bigger than the code itself!
#
# Suppose this:
#
#   cmd_a | cmd_b &
#
# I need the PID of cmd_a. How can I get it?
# In bash, $! will give me the PID of cmd_b.
#
# So, I came up with this ugly solution: open a subshell, like this:
#
# (
# 	cmd_a &
# 	echo "This is the PID I want $!"
# 	wait
# ) | cmd_b


# Ignore Ctrl+C here.
# If I don't do this, this shell script is killed before
# ping and gawk can finish their work.
trap '' 2

# Now the ugly code.
(
	"${PING_BIN}" "${PING_PARAMS[@]}" &
	# Commented out, because it looks like this line is not needed
	#trap "kill -2 $! ; exit 1" 2  # Catch Ctrl+C here
	wait
) 2>&1 | "${AWK_BIN}" "${AWK_PARAMS[@]}" '
# Weird that awk does not come with abs(), so I need to implement it.
function abs(x) {
	return ( (x < 0) ? -x : x )
}

# Ditto for ceiling function.
function ceil(x) {
	return (x == int(x)) ? x : int(x) + 1
}

# Currently, this function is called once, at the beginning of this
# script, but it is also possible to call this more than once, to
# handle window size changes while this program is running.
#
# Local variables MUST be declared in argument list, else they are
# seen as global. Ugly, but that is how awk works.
function get_terminal_size(SIZE,SIZEA) {
	if( HAS_STTY ) {
		if( (STTY_CMD | getline SIZE) == 1 ) {
			split(SIZE, SIZEA, " ")
			LINES   = SIZEA[1]
			COLUMNS = SIZEA[2]
		} else {
			HAS_STTY = 0
		}
		close(STTY_CMD)
	}
	if ( int('"${OVERRIDE_COLUMNS}"') ) { COLUMNS = int('"${OVERRIDE_COLUMNS}"') }
	if ( int('"${OVERRIDE_LINES}"')   ) { LINES   = int('"${OVERRIDE_LINES}"')   }
}

############################################################
# Functions related to cursor handling

# Function called whenever a non-dotted line is printed.
#
# It will move the cursor to the line next to the statistics and
# restore the default color.
function other_line_is_printed() {
	if( IS_PRINTING_DOTS ) {
		if( '"${IS_TERMINAL}"' ) {
			printf( ESC_DEFAULT ESC_NEXTLINE ESC_NEXTLINE "\n" )
		} else {
			printf( ESC_DEFAULT "\n" )
			print_statistics_bar()
		}
	}
	IS_PRINTING_DOTS = 0
	CURR_COL = 0
}

# Function called whenever a non-dotted line is repeated.
function other_line_is_repeated() {
	if (other_line_times < 2) {
		return
	}
	if( '"${IS_TERMINAL}"' ) {
		printf( ESC_DEFAULT ESC_ERASELINE "\r" )
	}
	printf( "Last message repeated %d times.", other_line_times )
	if( ! '"${IS_TERMINAL}"' ) {
		printf( "\n" )
	}
}

# Function called whenever the repeating line has changed.
function other_line_finished_repeating() {
	if( other_line_times >= 2 ) {
		if( '"${IS_TERMINAL}"' ) {
			printf( "\n" )
		} else {
			other_line_is_repeated()
		}
	}
	other_line = ""
	other_line_times = 0
}

# Prints the newlines required for the live statistics.
#
# I need to print some newlines and then return the cursor back to its position
# to make sure the terminal will scroll.
#
# If the output is not a terminal, break lines on every LAST_N dots.
function print_newlines_if_needed() {
	if( '"${IS_TERMINAL}"' ) {
		# COLUMNS-1 because I want to avoid bugs with the cursor at the last column
		if( CURR_COL >= COLUMNS-1 ) {
			CURR_COL = 0
		}
		if( CURR_COL == 0 ) {
			if( IS_PRINTING_DOTS ) {
				printf( "\n" )
			}
			#printf( "\n" "\n" ESC_PREVLINE ESC_PREVLINE ESC_ERASELINE )
			printf( ESC_DEFAULT "\n" "\n" ESC_CURSORUP ESC_CURSORUP ESC_ERASELINE )
		}
	} else {
		if( CURR_COL >= LAST_N ) {
			CURR_COL = 0
			printf( ESC_DEFAULT "\n" )
			print_statistics_bar()
		}
	}
	CURR_COL++
	IS_PRINTING_DOTS = 1
}

############################################################
# Functions related to the data structure of "Last N" statistics.

# Clears the data structure.
function clear(d) {
	d["index"] = 0  # The next position to store a value
	d["size"]  = 0  # The array size, goes up to LAST_N
}

# This function stores the value to the passed data structure.
# The data structure holds at most LAST_N values. When it is full,
# a new value overwrite the oldest one.
function store(d, value) {
	d[d["index"]] = value
	d["index"]++
	if( d["index"] >= d["size"] ) {
		if( d["size"] < LAST_N ) {
			d["size"]++
		} else {
			d["index"] = 0
		}
	}
}

############################################################
# Functions related to processing the received response

function process_rtt(rtt) {
	# Overall statistics
	last_rtt = rtt
	total_rtt += rtt
	if( last_seq == 0 ) {
		min_rtt = max_rtt = rtt
	} else {
		if( rtt < min_rtt ) min_rtt = rtt
		if( rtt > max_rtt ) max_rtt = rtt
	}

	# "Last N" statistics
	store(lastn_rtt,rtt)
}

############################################################
# Functions related to printing the fancy ping response

# block_index, n, w, oddeven are just local variables.
function print_response_legend(i, n, w, oddeven) {
	if( ! '"${USE_LEGEND}"' ) {
		return
	}
	if( BLOCK_LEN > 1 ) {
		# w counts the cursor position in the current line. Because of the
		# escape codes, I need to jump through some hoops in order to count the
		# position correctly.
		w = 0
		n = sprintf( "%4d ", 0 )
		w += 1 + length(n)

		printf( BLOCK[0] ESC_DEFAULT n )

		for( i=1 ; i<BLOCK_LEN ; i++ ) {
			# Workaround for when there is a background color change right at
			# the edge of the screen. When it happens, the entire next line
			# will have that background color, which is not desired.
			if( '"${IS_TERMINAL}"' && w == COLUMNS ) {
				printf( "\n" )
				w = 0
				oddeven = ! oddeven
				if ( oddeven ) {
					printf( " " )
					w++
				}
			}
			n = sprintf( "%4d ", BLOCK_RTT_MIN + ceil((i-1) * BLOCK_RTT_RANGE / (BLOCK_LEN - 2)) )
			w += 1 + length(n)

			# Avoid breaking the legend at the end of the line.
			if( '"${IS_TERMINAL}"' && w > COLUMNS ) {
				printf( "\n" )
				w = 1 + length(n)
				oddeven = ! oddeven
				if ( oddeven ) {
					printf( " " )
					w++
				}
			}

			printf( BLOCK[i] ESC_DEFAULT n )
		}
		printf( "\n" )
	}

	# Useful code for debugging.
	#for( i=0 ; i<=BLOCK_RTT_MAX ; i++ ) {
	#	print_received_response(i)
	#	printf( ESC_DEFAULT "%4d\n", i )
	#}
}

# block_index is just a local variable.
function print_received_response(rtt, block_index) {
	if( rtt < BLOCK_RTT_MIN ) {
		block_index = 0
	} else if( rtt >= BLOCK_RTT_MAX ) {
		block_index = BLOCK_LEN - 1
	} else {
		block_index = 1 + int((rtt - BLOCK_RTT_MIN) * (BLOCK_LEN - 2) / BLOCK_RTT_RANGE)
	}
	printf( BLOCK[block_index] )
}

function print_missing_response(rtt) {
	printf( ESC_RED "!" )
}

############################################################
# Functions related to printing statistics

function print_overall() {
	if( '"${IS_TERMINAL}"' ) {
		printf( "%2d/%3d (%2d%%) lost; %4.0f/" ESC_BOLD "%4.0f" ESC_DEFAULT "/%4.0fms; last: " ESC_BOLD "%4.0f" ESC_DEFAULT "ms",
			lost,
			lost+received,
			(lost*100/(lost+received)),
			min_rtt,
			(total_rtt/received),
			max_rtt,
			last_rtt )
	} else {
		printf( "%2d/%3d (%2d%%) lost; %4.0f/" ESC_BOLD "%4.0f" ESC_DEFAULT "/%4.0fms",
			lost,
			lost+received,
			(lost*100/(lost+received)),
			min_rtt,
			(total_rtt/received),
			max_rtt )
	}
}

function print_last_n(i, sum, min, avg, max, diffs) {
	# Calculate and print the lost packets statistics
	sum = 0
	for( i=0 ; i<lastn_lost["size"] ; i++ ) {
		sum += lastn_lost[i]
	}
	printf( "%2d/%3d (%2d%%) lost; ",
		sum,
		lastn_lost["size"],
		sum*100/lastn_lost["size"] )

	# Calculate the min/avg/max rtt times
	sum = diffs = 0
	min = max = lastn_rtt[0]
	for( i=0 ; i<lastn_rtt["size"] ; i++ ) {
		sum += lastn_rtt[i]
		if( lastn_rtt[i] < min ) min = lastn_rtt[i]
		if( lastn_rtt[i] > max ) max = lastn_rtt[i]
	}
	avg = sum/lastn_rtt["size"]

	# Calculate mdev (mean absolute deviation)
	for( i=0 ; i<lastn_rtt["size"] ; i++ ) {
		diffs += abs(lastn_rtt[i] - avg)
	}
	diffs /= lastn_rtt["size"]

	# Print the rtt statistics
	printf( "%4.0f/" ESC_BOLD "%4.0f" ESC_DEFAULT "/%4.0f/%4.0fms (last %d)",
		min,
		avg,
		max,
		diffs,
		lastn_rtt["size"] )
}

function print_statistics_bar() {
	if( '"${IS_TERMINAL}"' ) {
		printf( ESC_SAVEPOS ESC_DEFAULT )

		printf( ESC_NEXTLINE ESC_ERASELINE )
		print_overall()
		printf( ESC_NEXTLINE ESC_ERASELINE )
		print_last_n()

		printf( ESC_UNSAVEPOS )
	} else {
		print_overall()
		printf( "\n" )
		print_last_n()
		printf( "\n" )
	}
}

############################################################
# Initializations
BEGIN {
	# Easy way to get each value from ping output
	FS = "="

	############################################################
	# General internal variables

	# This is needed to keep track of lost packets
	last_seq = 0

	# The previously printed non-ping-response line
	other_line = ""
	other_line_times = 0

	# Variables to keep the screen clean
	IS_PRINTING_DOTS = 0
	CURR_COL = 0

	############################################################
	# Variables related to "overall" statistics
	received = 0
	lost = 0
	total_rtt = 0
	min_rtt = 0
	max_rtt = 0
	last_rtt = 0

	############################################################
	# Variables related to "last N" statistics
	LAST_N = int('"${LAST_N}"')

	# Data structures for the "last N" statistics
	clear(lastn_lost)
	clear(lastn_rtt)

	############################################################
	# Terminal height and width 

	# These are sane defaults, in case we cannot query the actual terminal size
	LINES    = 24
	COLUMNS  = 80

	# Auto-detecting the terminal size
	HAS_STTY = 1
	STTY_CMD = "stty --file=/dev/tty size 2> /dev/null"
	get_terminal_size()
	if( '"${IS_TERMINAL}"' && COLUMNS <= 50 ) {
		print "Warning: terminal width is too small."
	}

	############################################################
	# ANSI escape codes

	# Color escape codes.
	# Fortunately, awk defaults any unassigned variable to an empty string.
	if( '"${USE_COLOR}"' ) {
		ESC_DEFAULT = "\033[0m"
		ESC_BOLD    = "\033[1m"
		#ESC_BLACK   = "\033[0;30m"
		#ESC_GRAY    = "\033[1;30m"
		ESC_RED     = "\033[0;31m"
		ESC_GREEN   = "\033[0;32m"
		ESC_YELLOW  = "\033[0;33m"
		ESC_BLUE    = "\033[0;34m"
		ESC_MAGENTA = "\033[0;35m"
		ESC_CYAN    = "\033[0;36m"
		ESC_WHITE   = "\033[0;37m"
		ESC_YELLOW_ON_GREEN = "\033[42;33m"
		ESC_RED_ON_YELLOW   = "\033[43;31m"
	}
	# Other escape codes, see:
	# http://en.wikipedia.org/wiki/ANSI_escape_code
	# http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
	ESC_NEXTLINE   = "\n"
	ESC_CURSORUP   = "\033[A"
	ESC_SCROLLUP   = "\033[S"
	ESC_SCROLLDOWN = "\033[T"
	ESC_ERASELINE  = "\033[2K"
	ESC_SAVEPOS    = "\0337"
	ESC_UNSAVEPOS  = "\0338"

	# I am avoiding these escapes as they are not listed in:
	# http://vt100.net/docs/vt100-ug/chapter3.html
	#ESC_PREVLINE   = "\033[F"
	#ESC_SAVEPOS    = "\033[s"
	#ESC_UNSAVEPOS  = "\033[u"

	# I am avoiding this to improve compatibility with (older versions of) tmux
	#ESC_NEXTLINE   = "\033[E"

	############################################################
	# Unicode characters (based on https://github.com/holman/spark )
	if( '"${USE_UNICODE}"' ) {
		BLOCK[ 0] = ESC_GREEN "▁"
		BLOCK[ 1] = ESC_GREEN "▂"
		BLOCK[ 2] = ESC_GREEN "▃"
		BLOCK[ 3] = ESC_GREEN "▄"
		BLOCK[ 4] = ESC_GREEN "▅"
		BLOCK[ 5] = ESC_GREEN "▆"
		BLOCK[ 6] = ESC_GREEN "▇"
		BLOCK[ 7] = ESC_GREEN "█"
		BLOCK[ 8] = ESC_YELLOW_ON_GREEN "▁"
		BLOCK[ 9] = ESC_YELLOW_ON_GREEN "▂"
		BLOCK[10] = ESC_YELLOW_ON_GREEN "▃"
		BLOCK[11] = ESC_YELLOW_ON_GREEN "▄"
		BLOCK[12] = ESC_YELLOW_ON_GREEN "▅"
		BLOCK[13] = ESC_YELLOW_ON_GREEN "▆"
		BLOCK[14] = ESC_YELLOW_ON_GREEN "▇"
		BLOCK[15] = ESC_YELLOW_ON_GREEN "█"
		BLOCK[16] = ESC_RED_ON_YELLOW "▁"
		BLOCK[17] = ESC_RED_ON_YELLOW "▂"
		BLOCK[18] = ESC_RED_ON_YELLOW "▃"
		BLOCK[19] = ESC_RED_ON_YELLOW "▄"
		BLOCK[20] = ESC_RED_ON_YELLOW "▅"
		BLOCK[21] = ESC_RED_ON_YELLOW "▆"
		BLOCK[22] = ESC_RED_ON_YELLOW "▇"
		BLOCK[23] = ESC_RED_ON_YELLOW "█"
		if( '"${USE_MULTICOLOR}"' && '"${USE_COLOR}"' ) {
			# Multi-color version:
			BLOCK_LEN = 24
			BLOCK_RTT_MIN = 10
			BLOCK_RTT_MAX = 230
		} else {
			# Simple version:
			BLOCK_LEN = 8
			BLOCK_RTT_MIN = 25
			BLOCK_RTT_MAX = 175
		}
	} else {
		BLOCK[ 0] = ESC_GREEN "_"
		BLOCK[ 1] = ESC_GREEN "."
		BLOCK[ 2] = ESC_GREEN "o"
		BLOCK[ 3] = ESC_GREEN "O"
		# Simple version:
		BLOCK_LEN = 4
		BLOCK_RTT_MIN = 75
		BLOCK_RTT_MAX = 225
	}

	if( int('"${RTT_MIN}"') > 0 && int('"${RTT_MAX}"') > 0 ) {
		BLOCK_RTT_MIN = int('"${RTT_MIN}"')
		BLOCK_RTT_MAX = int('"${RTT_MAX}"')
	} else if( int('"${RTT_MIN}"') > 0 ) {
		BLOCK_RTT_MIN = int('"${RTT_MIN}"')
		BLOCK_RTT_MAX = BLOCK_RTT_MIN * (BLOCK_LEN - 1)
	} else if( int('"${RTT_MAX}"') > 0 ) {
		BLOCK_RTT_MAX = int('"${RTT_MAX}"')
		BLOCK_RTT_MIN = int(BLOCK_RTT_MAX / (BLOCK_LEN - 1))
	}

	BLOCK_RTT_RANGE = BLOCK_RTT_MAX - BLOCK_RTT_MIN
	print_response_legend()
}

############################################################
# Main loop
{
	# Sample line:
	# 64 bytes from 8.8.8.8: icmp_seq=1 ttl=49 time=184 ms
	if( $0 ~ /^[0-9]+ bytes from .*: icmp_[rs]eq=[0-9]+ ttl=[0-9]+ time=[0-9.]+ *ms/ ) {
		if( other_line_times >= 2 ) {
			other_line_finished_repeating()
		}

		# $1 = useless prefix string
		# $2 = icmp_seq
		# $3 = ttl
		# $4 = time

		# This must be called before incrementing the last_seq variable!
		rtt = int($4)
		process_rtt(rtt)

		seq = int($2)

		while( last_seq < seq - 1 ) {
			# Lost a packet
			print_newlines_if_needed()
			print_missing_response()

			last_seq++
			lost++
			store(lastn_lost, 1)
		}

		# Received a packet
		print_newlines_if_needed()
		print_received_response(rtt)

		# In case of receiving multiple responses with the same seq number, it
		# is better to use "last_seq = seq" than to increment last_seq.
		last_seq = seq

		received++
		store(lastn_lost, 0)

		if( '"${IS_TERMINAL}"' ) {
			print_statistics_bar()
		}
	} else if ( $0 == "" ) {
		# Do nothing on blank lines.
	} else {
		other_line_is_printed()
		if ( $0 == other_line ) {
			other_line_times++
			if( '"${IS_TERMINAL}"' ) {
				other_line_is_repeated()
			}
		} else {
			other_line_finished_repeating()
			other_line = $0
			other_line_times = 1
			printf( "%s\n", $0 )
		}
	}

	# Not needed when the output is a terminal, but does not hurt either.
	fflush()
}'

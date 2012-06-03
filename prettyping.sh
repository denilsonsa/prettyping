#!/bin/bash
#
# Written by Denilson Figueiredo de Sa <denilsonsa@gmail.com>
# 2010-11-05 - "ping" changed output from icmp_seq to icmp_req. Fixed.
# 2008-04-16 - Small bug fixes, small improvement to parameter filtering.
# 2008-02-10 - Started writing the second version. Added some live
#              statistics alongside with the colored chars.
# 2008-01-16 - Updated version. Removed [[ bash-ism. Now this script
#              also works on dash.
# 2008-01-12 - First version written and released.

# TODO: print the destination (also) at the bottom bar. Useful after leaving
# the script running for quite some time.
#
# TODO: Test the behavior of this script upon receiving out-of-order packets, like these:
#   http://www.blug.linux.no/rfc1149/pinglogg.txt
#
# TODO: Implement "msg repeating", like...
#   ping: sendmsg: Network is unreachable
#   (repeated xx times)
# where xx gets updated for every repeated line
#
# TODO: Implement audible ping.
#
# TODO: Add a command-line parameter for interactive/log mode.
# TODO: Implement interactive/log modes.
#
# TODO: Update the help message.
#
# TODO: Autodetect the width of printf numbers, so they will always line up correctly.
#
# TODO? How will prettyping behave if it receives a duplicate response?

print_help() {
	cat << EOF
Usage: $MYNAME <standard ping parameters>

TODO: Update me

This script will run the standard "ping" program and will substitute each ping
response line by a colored dot.
EOF
}

# Thanks to people at #bash who pointed me at
# http://bash-hackers.org/wiki/doku.php/scripting/posparams
parse_arguments() {
	USE_COLORS=1
	LAST_N=25

	PING_PARAMS=( -n )

	while [[ $# != 0 ]] ; do
		case "$1" in
			-h | -help | --help )
				print_help
				exit
				;;

			# Forbidden ping parameters within prettyping:
			-f )
				echo "$MYNAME: You can't use the -f (flood) option."
				exit 1
				;;
			-R )
				# -R prints extra information at each ping response.
				echo "$MYNAME: You can't use the -R (record route) option."
				exit 1
				;;
			-q )
				echo "$MYNAME: You can't use the -q (quiet) option."
				exit 1
				;;
			-n )
				# -n prevents ping from doing reverse DNS lookup, speeding
				# the startup up a bit. prettyping will always use this option.
				;;
			-v )
				# -n enables verbose output. However, it seems the output with
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
			--color   ) USE_COLORS=1 ;;
			--nocolor ) USE_COLORS=0 ;;
			--last ) LAST_N="$2" ; shift ;;
			#TODO: Check if this parameter is really a number.

			* )
				PING_PARAMS+=("$1")
				;;
		esac
		shift
	done
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
	ping "${PING_PARAMS[@]}" &
	# Commented out, because it looks like this line is not needed
	#trap "kill -2 $! ; exit 1" 2  # Catch Ctrl+C here
	wait
) 2>&1 | gawk '
# Weird that awk does not come with abs(), so I need to implement it.
function abs(x)
{
	return ( (x < 0) ? -x : x )
}

# Currently, this function is called once, at the beginning of this
# script, but it is also possible to call this more than once, to
# handle window size changes while this program is running.
#
# Local variables MUST be declared in argument list, else they are
# seen as global. Ugly, but that is how awk works.
function get_terminal_size(SIZE,SIZEA)
{
	if( HAS_STTY )
	{
		if( (STTY_CMD | getline SIZE) == 1 )
		{
			split(SIZE, SIZEA, " ")
			LINES   = SIZEA[1]
			COLUMNS = SIZEA[2]
		}
		else
			HAS_STTY = 0
		close(STTY_CMD)
	}
}

############################################################
# Functions related to cursor handling

# Function called whenever a non-dotted line is printed.
#
# It will move the cursor to the line next to the statistics and
# restore the default color.
function other_line_is_printed()
{
	if( IS_PRINTING_DOTS )
		printf( ESC_DEFAULT ESC_NEXTLINE ESC_NEXTLINE "\n" )
	IS_PRINTING_DOTS = 0
	CURR_COL = 0
}

# Prints the newlines required for the live statistics.
#
# I need to print some newlines and then return the cursor back
# to its position to make sure the terminal will scroll.
function print_newlines_if_needed()
{
	# COLUMNS-1 because I want to avoid bugs with the cursor at the last column
	if( CURR_COL >= COLUMNS-1 )
		CURR_COL = 0
	if( CURR_COL == 0 )
	{
		if( IS_PRINTING_DOTS )
			printf( "\n" )
		#printf( "\n" "\n" ESC_PREVLINE ESC_PREVLINE ESC_ERASELINE )
		printf( "\n" "\n" ESC_CURSORUP ESC_CURSORUP ESC_ERASELINE )
	}
	CURR_COL++
	IS_PRINTING_DOTS = 1
}

############################################################
# Functions related to the data structure of "Last N" statistics.

# Clears the data structure.
function clear(d)
{
	d["index"] = 0  # The next position to store a value
	d["size"]  = 0  # The array size, goes up to LASTNMAX
}

# This function stored the value to the passed data structure.
# The data structure holds at most LAST_N values. When it is full,
# a new value overwrite the oldest one.
function store(d,value)
{
	d[d["index"]] = value
	d["index"]++
	if( d["index"] >= d["size"] )
	{
		if( d["size"] < LAST_N )
			d["size"]++
		else
			d["index"] = 0
	}
}

############################################################
# Functions related to processing the received response

function process_rtt(rtt)
{
	# Overall statistics
	last_rtt = rtt
	total_rtt += rtt
	if( last_seq == 0 )
		min_rtt = max_rtt = rtt
	else
	{
		if( rtt < min_rtt ) min_rtt = rtt
		if( rtt > max_rtt ) max_rtt = rtt
	}

	# "Last N" statistics
	store(lastn_rtt,rtt)
}

############################################################
# Functions related to printing statistics

function print_overall()
{
	printf( "%2d/%3d (%2d%%) lost; %4.0f/" ESC_BOLD "%4.0f" ESC_DEFAULT "/%4.0fms; last: %4.0fms",
		lost,
		lost+received,
		(lost*100/(lost+received)),
		min_rtt,
		(total_rtt/received),
		max_rtt,
		last_rtt )
}

function print_last_n(i, sum, min, avg, max, diffs)
{
	# Calculate and print the lost packets statistics
	sum = 0
	for( i=0 ; i<lastn_lost["size"] ; i++ )
		sum += lastn_lost[i]
	printf( "%2d/%3d (%2d%%) lost; ",
		sum,
		lastn_lost["size"],
		sum*100/lastn_lost["size"] )

	# Calculate the min/avg/max rtt times
	sum = diffs = 0
	min = max = lastn_rtt[0]
	for( i=0 ; i<lastn_rtt["size"] ; i++ )
	{
		sum += lastn_rtt[i]
		if( lastn_rtt[i] < min ) min = lastn_rtt[i]
		if( lastn_rtt[i] > max ) max = lastn_rtt[i]
	}
	avg = sum/lastn_rtt["size"]

	# Calculate mdev (mean absolute deviation)
	for( i=0 ; i<lastn_rtt["size"] ; i++ )
		diffs += abs(lastn_rtt[i] - avg)
	diffs /= lastn_rtt["size"]

	# Print the rtt statistics
	printf( "%4.0f/" ESC_BOLD "%4.0f" ESC_DEFAULT "/%4.0f/%4.0fms (last %d)",
		min,
		avg,
		max,
		diffs,
		lastn_rtt["size"] )
}

############################################################
# Initializations
BEGIN{
	# Easy way to get each value from ping output
	FS = "="

	############################################################
	# General internal variables

	# This is needed to keep track of lost packets
	last_seq = 0

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
	LAST_N = '$LAST_N'

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
	STTY_CMD = "stty size --file=/dev/tty 2> /dev/null"
	get_terminal_size()
	if( COLUMNS <= 50 )
		print "Warning: terminal width is too small."

	############################################################
	# ANSI escape codes

	# Color escape codes.
	# Fortunately, awk defaults any unassigned variable to an empty string.
	if('$USE_COLORS')
	{
		ESC_DEFAULT = "\033[0m"
		ESC_BOLD    = "\033[1m"
		ESC_GRAY    = "\033[1;30m"
		ESC_RED     = "\033[1;31m"
		ESC_GREEN   = "\033[1;32m"
		ESC_YELLOW  = "\033[1;33m"
		ESC_BLUE    = "\033[1;34m"
		ESC_MAGENTA = "\033[1;35m"
		ESC_CYAN    = "\033[1;36m"
		ESC_WHITE   = "\033[1;37m"
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
}

############################################################
# Main loop
{
	if( $0 ~ /^[0-9]+ bytes from .*: icmp_[rs]eq=[0-9]+ ttl=[0-9]+ time=[0-9.]+ *ms/ )
	{
		# This must be called before incrementing the last_seq variable!
		process_rtt(int($4))

		seq = int($2)

		while( last_seq < seq-1 )
		{
			# Lost a packet
			print_newlines_if_needed()
			printf( ESC_RED "!" )

			last_seq++
			lost++
			store(lastn_lost,1)
		}

		# Received a packet
		print_newlines_if_needed()
		printf( ESC_GREEN "." )

		last_seq++
		received++
		store(lastn_lost,0)

		printf( ESC_SAVEPOS ESC_DEFAULT )

		printf( ESC_NEXTLINE ESC_ERASELINE )
		print_overall()
		printf( ESC_NEXTLINE ESC_ERASELINE )
		print_last_n()

		printf( ESC_UNSAVEPOS )

		# Not really needed, uncomment if things get buggy
		#fflush()
	}
	else
	{
		other_line_is_printed()
		printf( "%s\n", $0 )
	}
}'

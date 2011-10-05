#!/bin/sh
#
# Written by Denilson Figueiredo de Sa <denilsonsa@gmail.com>
# 2008-01-16 - Updated version. Removed [[ bash-ism. Now this script
#              also works on dash.
# 2008-01-12 - First version written and released.

MYNAME=`basename "$0"`

# TODO: use some crazy escape codes to print the ping time after each dot,
# and then delete it before printing the next dot. Or something as crazy
# as that. Must be careful about the terminal width

print_help() {
	cat << EOF
Usage: $MYNAME <standard ping parameters>

This script will run the standard "ping" program and will substitute each ping
response line by a colored dot.
EOF
}


if [ "$1" = "" -o "$1" = "-h" -o "$1" = "--help" ]; then
	print_help
	exit
fi

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
#
# I don't know why


# Ignore Ctrl+C here.
# If I don't do this, this shell script is killed before
# ping and awk can finish their work.
trap '' 2

# Now the ugly code. Damn, bash sucks! :-P
(
	ping "$@" &
	trap "kill -2 $! ; exit 1" 2  # Catch Ctrl+C here
	wait
) | awk '
BEGIN{
	last_seq = 0
	FS = "="

	# Color escape codes
	ESC_DEFAULT="\033[0m"
	ESC_BOLD="\033[1m"
	ESC_GREEN="\033[1;32m"
	ESC_RED="\033[1;31m"
	ESC_YELLOW="\033[1;33m"
}
{
	if( $0 ~ /^[0-9]+ bytes from .*: icmp_seq=[0-9]+ ttl=[0-9]+ time=[0-9.]+ *ms *$/ )
	{
		seq = $2 + 0
		last_seq++
		while( last_seq < seq )
		{
			printf( ESC_RED "!" )
			last_seq++
		}
		printf( ESC_GREEN "." )
	}
	else
	{
		print ESC_DEFAULT $0
	}
}'

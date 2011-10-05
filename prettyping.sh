#!/bin/sh

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


if [[ $1 == "" || $1 == -h || $1 == --help ]] ; then
	print_help
	exit
fi

trap 'pkill -2 ping ; exit 1' 2
#trap 'pkill -6 ping' 6
#trap 'echo I am trapped' 1 2 3 6 13 15
#trap 'echo I am trapped  1' 1
#trap 'echo I am trapped  2' 2
#trap 'echo I am trapped  3' 3
#trap 'echo I am trapped  6' 6
#trap 'echo I am trapped 13' 13
#trap 'echo I am trapped 15' 15
#while : ; do : ; done

export LC_ALL=C
ping "$@" | awk '
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
			printf( ESC_RED "!" )
		printf( ESC_GREEN "*" )
	}
	else
		print ESC_DEFAULT $0
}' &

# The above command is run at background because of this:
# 2008-01-12 17:12, at irc.freenode.net/#bash
# <twkm> bash can only handle signals while *bash* is running.
# <twkm> when you run other programs they must handle signals themselves.

echo $!

wait

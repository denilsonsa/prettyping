#!/bin/awk -f

BEGIN {
	HUGE_STRING = "\n\
PING registro.br (200.160.2.3) 56(84) bytes of data.\n\
64 bytes from registro.br (200.160.2.3): icmp_seq=1 ttl=56 time=25.5 ms\n\
64 bytes from registro.br (200.160.2.3): icmp_seq=2 ttl=56 time=55.7 ms\n\
64 bytes from registro.br (200.160.2.3): icmp_seq=3 ttl=56 time=75.2 ms\n\
ping: sendto: Network is down\n\
ping: sendto: No route to host\n\
ping: sendto: No route to host\n\
ping: sendto: No route to host\n\
ping: sendto: No route to host\n\
ping: sendto: No route to host\n\
Request timeout for icmp_seq 4\n\
Request timeout for icmp_seq 5\n\
Request timeout for icmp_seq 6\n\
64 bytes from registro.br (200.160.2.3): icmp_seq=7 ttl=56 time=123 ms\n\
64 bytes from registro.br (200.160.2.3): icmp_seq=8 ttl=56 time=149 ms\n\
64 bytes from registro.br (200.160.2.3): icmp_seq=9 ttl=56 time=183 ms\n\
\n\
--- registro.br ping statistics ---\n\
3 packets transmitted, 3 received, 0% packet loss, time 2000ms\n\
rtt min/avg/max/mdev = 36.750/38.535/40.048/1.360 ms\n\
"

	LEN = split(HUGE_STRING, ARRAY, "\n")

	for (i = 0; i < LEN; i++) {
		print ARRAY[i]
		system("sleep 1")
	}
}

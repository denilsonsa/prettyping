#!/bin/bash

sample_output() {
	cat << EOF
PING registro.br (200.160.2.3) 56(84) bytes of data.
Request timeout for icmp_seq 1
64 bytes from registro.br (200.160.2.3): icmp_seq=2 ttl=56 time=25.5 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=3 ttl=56 time=55.7 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=4 ttl=56 time=75.2 ms
ping: sendto: Network is down
ping: sendto: No route to host
ping: sendto: No route to host
ping: sendto: No route to host
ping: sendto: No route to host
ping: sendto: No route to host
Request timeout for icmp_seq 5
Request timeout for icmp_seq 6
Request timeout for icmp_seq 7
64 bytes from registro.br (200.160.2.3): icmp_seq=8 ttl=56 time=123 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=9 ttl=56 time=149 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=10 ttl=56 time=183 ms
Request timeout for icmp_seq 11
Request timeout for icmp_seq 12
Request timeout for icmp_seq 13
64 bytes from registro.br (200.160.2.3): icmp_seq=14 ttl=56 time=123 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=15 ttl=56 time=149 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=16 ttl=56 time=183 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=19 ttl=56 time=183 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=20 ttl=56 time=183 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=21 ttl=56 time=183 ms
From 10.1.1.160 icmp_seq=22 Destination Host Unreachable
From 10.1.1.160 icmp_seq=23 Destination Host Unreachable
From 10.1.1.160 icmp_seq=24 Destination Host Unreachable
From 10.1.1.160 icmp_seq=25 Destination Host Unreachable
From 10.1.1.160 icmp_seq=26 Destination Host Unreachable
From 10.1.1.160 icmp_seq=27 Destination Host Unreachable
From 10.1.1.160 icmp_seq=28 Destination Host Unreachable
64 bytes from registro.br (200.160.2.3): icmp_seq=29 ttl=56 time=183 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=30 ttl=56 time=183 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=31 ttl=56 time=183 ms
64 bytes from registro.br (200.160.2.3): icmp_seq=32 ttl=56 time=183 ms

--- registro.br ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 36.750/38.535/40.048/1.360 ms
EOF
}

sample_output | while read line; do
	echo -E "$line"
	sleep 0.25s
done

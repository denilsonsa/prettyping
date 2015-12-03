#!/usr/bin/env python3

import argparse
import codecs
import datetime
import os
import subprocess
import sys


def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Adds timestamp to (text) stdin, making it easier to compare the prettyping behavior. Outputs to stdout or to a file.',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '-a', '--absolute',
        action='store_true',
        help='Calculate absolute timestamps (relative timestamps are the default).'
    )
    parser.add_argument(
        '--from-launch',
        action='store_true',
        help='Counts time from the launch of this program (the default is to count from the first input).'
    )
    parser.add_argument(
        '-d', '--digits',
        type=int,
        action='store',
        default=1,
        help='Precision of the timestamps, as the amount of fractional digits of a second.'
    )
    parser.add_argument(
        '-e', '--escape',
        action='store_true',
        help='Perform escaping of the text when adding timestamps.'
    )
    parser.add_argument(
        '-o', '--output',
        type=argparse.FileType('wb'),
        help='Saves the timestamped output to a file.'
    )
    parser.add_argument(
        '-t', '--tee',
        action='store_true',
        help='Together with -o, will print the raw version to stdout.'
    )
    args = parser.parse_args()
    return args


def unicode_escape(s):
    if isinstance(s, bytes):
        #s = s.decode('utf-8', 'replace')
        s = s.decode('utf-8', 'strict')
    return codecs.encode(s, 'unicode_escape') + b'\n'


def main():
    global OPTIONS
    OPTIONS = parse_arguments()

    # Python documentation says that sys.stdin/stdout are text streams, and
    # that we can access the binary stream at the ".buffer" object.
    #
    # However, Python's stdin is buffered, so we need to reopen the fd.
    # Alternatively, Python's "-u" command-line option makes stdin unbuffered
    # in some Python versions (but not all).
    in_file = os.fdopen(sys.stdin.fileno(), 'rb', buffering=0)
    out_raw = None
    out_ts = sys.stdout.buffer

    if OPTIONS.output:
        out_ts = OPTIONS.output

        if OPTIONS.tee:
            out_raw = sys.stdout.buffer

    # Escaping function.
    escape = lambda x: x

    if OPTIONS.escape:
        escape = unicode_escape

    # Timestamp digits.
    timestamp_format = '{0:.' + str(OPTIONS.digits) + 'F}s\t'

    # Initial time.
    start_datetime = None
    if OPTIONS.from_launch:
        start_datetime = datetime.datetime.utcnow()
    previous_datetime = start_datetime

    while True:
        # Reading at most 64KB of data.
        raw_data = in_file.read(64 * 1024)
        if len(raw_data) == 0:
            break

        current_datetime = datetime.datetime.utcnow()

        if start_datetime is None:
            # This happens only once.
            start_datetime = current_datetime
            previous_datetime = start_datetime
            seconds = 0.0
        else:
            if OPTIONS.absolute:
                delta = current_datetime - start_datetime
            else:
                delta = current_datetime - previous_datetime
            seconds = delta.total_seconds()

        previous_datetime = current_datetime

        output = timestamp_format.format(seconds).encode('ascii') + escape(raw_data)

        if out_ts:
            out_ts.write(output)
            out_ts.flush()

        if out_raw:
            out_raw.write(raw_data)
            out_raw.flush()


if __name__ == '__main__':
    main()

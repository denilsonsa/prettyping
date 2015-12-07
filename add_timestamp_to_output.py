#!/usr/bin/env python3

import argparse
import codecs
import datetime
import re
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
    '''Receives a byte-string, returns a byte-string.

    Besides escaping, auto-adds a trailing newline.
    (Why? Because it is convenient in the main code.)
    '''
    return codecs.encode(s, 'unicode_escape') + b'\n'


def escape_control_characters(s):
    r'''Receives a byte-string, returns a byte-string.

    Besides escaping, auto-adds a trailing newline.
    (Why? Because it is convenient in the main code.)

    >>> escape_control_characters(b'')
    b'\n'
    >>> escape_control_characters(b'foo')
    b'foo\n'
    >>> escape_control_characters(b'a\x00b\x01c\rd\te\nf\\g\x19h i\x80j\xffk')
    b'a\\x00b\\x01c\\rd\\te\\nf\\\\g\\x19h i\x80j\xffk\n'
    '''

    def func(match):
        c = match.group(0)
        if c == b'\t':
            return b'\\t'
        elif c == b'\r':
            return b'\\r'
        elif c == b'\n':
            return b'\\n'
        elif c == b'\\':
            return b'\\\\'
        else:
            return '\\x{0:02x}'.format(ord(c)).encode('ascii')

    return re.sub(b'[\\x00-\\x1f\\\\]', func, s) + b'\n'


def split_bytes_in_lines(blob):
    r'''Splits the input (of type bytes) into a list of byte-strings, keeping
    the newline separator. Avoids a trailing empty element if the last byte is
    a newline.

    >>> split_bytes_in_lines(b'')
    []
    >>> split_bytes_in_lines(b'\n')
    [b'\n']
    >>> split_bytes_in_lines(b'\n\n')
    [b'\n', b'\n']
    >>> split_bytes_in_lines(b'foo')
    [b'foo']
    >>> split_bytes_in_lines(b'foo\n')
    [b'foo\n']
    >>> split_bytes_in_lines(b'foo\nbar')
    [b'foo\n', b'bar']
    >>> split_bytes_in_lines(b'foo\nbar\n')
    [b'foo\n', b'bar\n']
    >>> split_bytes_in_lines(b'foo\nbar\nstuff')
    [b'foo\n', b'bar\n', b'stuff']
    '''
    lines = blob.split(b'\n')
    # Putting back the separator.
    lines = [line + b'\n' for line in lines[:-1]] + lines[-1:]
    # Removing the trailing empty string.
    if lines[-1] == b'':
        lines = lines[:-1]
    return lines


def main():
    global OPTIONS
    OPTIONS = parse_arguments()

    # Python documentation says that sys.stdin/stdout are text streams, and
    # that we can access the binary stream at the ".buffer" object.
    #
    # However, Python's stdin is buffered, so we need to reopen the fd.
    # Alternatively, Python's "-u" command-line option makes stdin unbuffered
    # in some Python versions (but not all).

    # Input stream.
    in_file = os.fdopen(sys.stdin.fileno(), 'rb', buffering=0)
    # Pass-through stream (i.e. output is the same as the raw input).
    out_raw = None
    # Time-stamped output stream.
    out_ts = sys.stdout.buffer

    if OPTIONS.output:
        out_ts = OPTIONS.output

        if OPTIONS.tee:
            out_raw = sys.stdout.buffer

    # Escaping function.
    escape = lambda x: x

    if OPTIONS.escape:
        # escape = unicode_escape
        escape = escape_control_characters

    # Timestamp digits.
    timestamp_format = '{0:.' + str(OPTIONS.digits) + 'F}s\t'

    # Initial time.
    start_datetime = None
    if OPTIONS.from_launch:
        start_datetime = datetime.datetime.utcnow()
    previous_datetime = start_datetime

    while True:
        # Reading at most 64KB of data on each iteration.
        raw_data = in_file.read(64 * 1024)
        if len(raw_data) == 0:
            break

        # Calculating the elapsed time.
        current_datetime = datetime.datetime.utcnow()
        if start_datetime is None:
            # This happens only once.
            start_datetime = current_datetime
            previous_datetime = current_datetime
            seconds = 0.0
        else:
            # This gets executed on every iteration after the first one.
            if OPTIONS.absolute:
                delta = current_datetime - start_datetime
            else:
                delta = current_datetime - previous_datetime
            seconds = delta.total_seconds()
            previous_datetime = current_datetime

        # Building the output for this input blob.
        raw_lines = split_bytes_in_lines(raw_data)
        output = b''
        for raw_line in raw_lines:
            timestamp_bytes = timestamp_format.format(seconds).encode('ascii')
            output += timestamp_bytes + escape(raw_line)
            if not OPTIONS.absolute:
                # If there are multiple lines in this blob, all lines after
                # the first one have a delta-time of zero.
                seconds = 0

        if out_ts:
            out_ts.write(output)
            out_ts.flush()

        if out_raw:
            out_raw.write(raw_data)
            out_raw.flush()


if __name__ == '__main__':
    main()

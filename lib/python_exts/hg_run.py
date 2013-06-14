#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import re
import signal
import json
import base64
import resource
import traceback
import StringIO
from threading import Lock

if 'MERCURIAL_PATH' in os.environ:
    sys.path.insert(0, os.environ['MERCURIAL_PATH'])

os.environ['HGPLAIN'] = '1' # use more stable plain output
os.environ['HGRCPATH'] = '' # ignore non-repo specific hgrc files

libdir = '@LIBDIR@'

if libdir != '@' 'LIBDIR' '@':
    if not os.path.isabs(libdir):
        libdir = os.path.join(os.path.dirname(os.path.realpath(__file__)), libdir)
        libdir = os.path.abspath(libdir)
    sys.path.insert(0, libdir)

# enable importing on demand to reduce startup time
try:
    from mercurial import demandimport
    demandimport.enable()
except ImportError:
    sys.stderr.write("abort: couldn't find mercurial libraries in [%s]\n" % ' '.join(sys.path))
    sys.stderr.write("(check your install and PYTHONPATH)\n")

import mercurial.dispatch as dispatch

def _write_error(error):
    res = {"error": error}
    out_header = json.dumps(res).encode('utf-8')
    bits = _get_fixed_bits_from_header(out_header)
    sys.stdout.write(bits + "\n")
    sys.stdout.flush()
    sys.stdout.write(out_header + "\n")
    sys.stdout.flush()
    return

def _get_fixed_bits_from_header(out_header):
    size = len(out_header)
    return "".join(map(lambda y:str((size>>y)&1), range(32-1, -1, -1)))

def _signal_handler(signal, frame):
    """
    Handle the signal given in the first argument, exiting gracefully
    """
    sys.exit(0)

class HgRun(object):
    """
    Interacts with mercurial.rb to provide access to pygments functionality
    """
    def __init__(self):
        pass

    def get_data(self, args):
        """
        Return the data generated from mercurial.
        """
        fout = StringIO.StringIO()
        ferr = StringIO.StringIO()

        dispatch.dispatch(dispatch.request(args, None, None, None, fout, ferr))

        fout_value = fout.getvalue()
        ferr_value = ferr.getvalue()

        fout.close()
        ferr.close()

        return {"fout": base64.b64encode(fout_value), "ferr": base64.b64encode(ferr_value)}

    def _send_data(self, res):

        # Base header. We'll build on this, adding keys as necessary.
        base_header = {}

        encoded_res = json.dumps(res).encode('utf-8')
        res_bytes = len(encoded_res) + 1
        base_header["bytes"] = res_bytes

        out_header = json.dumps(base_header).encode('utf-8')

        # Following the protocol, send over a fixed size represenation of the
        # size of the JSON header
        bits = _get_fixed_bits_from_header(out_header)

        # Send it to Rubyland
        sys.stdout.write(bits + "\n")
        sys.stdout.flush()

        # Send the header.
        sys.stdout.write(out_header + "\n")
        sys.stdout.flush()

        # Finally, send the result
        sys.stdout.write(encoded_res + "\n")
        sys.stdout.flush()

    def _parse_header(self, header):
        return [arg.encode('utf-8') for arg in header.get("args", [])]

    def start(self):
        """
        Main loop, waiting for inputs on stdin. When it gets some data,
        it goes to work.

        hg_run exposes the dispatcher of mercurial. It always expects and
        requires a JSON header of metadata.

        The header is of form:
        { "args": ["--rev", "21"] }
        """
        lock = Lock()

        while True:
            # The loop begins by reading off a simple 32-arity string
            # representing an integer of 32 bits. This is the length of
            # our JSON header.
            size = sys.stdin.read(32)

            lock.acquire()

            try:
                # Read from stdin the amount of bytes we were told to expect.
                header_bytes = int(size, 2)

                # Sanity check the size
                size_regex = re.compile('[0-1]{32}')
                if not size_regex.match(size):
                    _write_error("Size received is not valid.")

                line = sys.stdin.read(header_bytes)
                header = json.loads(line)
                args = self._parse_header(header)

                # Get the actual data from mercurial.
                res = self.get_data(args)
                self._send_data(res)

            except:
                tb = traceback.format_exc()
                _write_error(tb)

            finally:
                lock.release()

def main():
    # Signal handlers to trap signals.
    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)
    signal.signal(signal.SIGHUP, _signal_handler)

    hg_run = HgRun()

    # close fd's. hg_run is a long-running process
    # and inherits fd's from its unicorn parent
    # (and, thus, burdens like mysql) — we don't want that here.

    # An optimization: we can check to see the max FD
    # a process can open and run the os.close() iteration against that.
    # If it's infinite, we default to 65536.
    maxfd = resource.getrlimit(resource.RLIMIT_NOFILE)[1]
    if maxfd == resource.RLIM_INFINITY:
        maxfd = 65536

    for fd in range(3, maxfd):
        try:
            os.close(fd)
        except:
            pass

    hg_run.start()

if __name__ == "__main__":
    main()

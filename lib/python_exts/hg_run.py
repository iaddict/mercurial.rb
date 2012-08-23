import os
import sys
import StringIO

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

# command -> ["history", "--repository", "foo/bar"]
def run(command):
  fout = StringIO.StringIO()
  ferr = StringIO.StringIO()

  dispatch.dispatch(dispatch.request(command, None, None, None, fout, ferr))
  
  fout_value = fout.getvalue()
  ferr_value = ferr.getvalue()
  
  fout.close()
  ferr.close()
  
  if ferr_value == '':
    return [True, fout_value]
  else:
    return [False, ferr_value]

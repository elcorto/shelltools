#!/usr/bin/python

# This script filters files matching some time spec out of a list of files. One
# could use "find -mtime ..." but find(1) is really slow when searching a dir
# with many files. 
#
# Instead, we use os.stat() on a list provided by e.g. locate, which is much
# faster.
# 
# Find's options allow only minutes "-{a,c,m}min" or n*24 hours "-{a,c,m}time".
# We are much more convenient here.
#
# The time spec syntax is almost like in find: 
# find -mtime +n 
#     older than
# find -mtime -n 
#     younger than
# find -mtime n 
#     exactly n, this is not implemented b/c it is useless; nobody searches for
#     a file which is e.g. exactly 3 days old simply b/c there is so such file.
#     Hint: the age changes every second :)

import sys
import os
import time
import numpy as np


def print_help():
    print """
Filter files matching some time spec out of a list of files.

age.py <offset> <files>
<files> | age.py <offset>

args:
-----
files : list of filenames "file1 file2 ..." if given as cmd line args
    or one file per line if piped in (e.g. output of locate)
offset: <number>[smhdwMy]
    <number> : any string that Python understands as a number
        number < 0 : files younger than abs(<offset>)
        number > 0 : files older than <offset>
    modifier : s(seconds) [default], m(minutes), h(hours), d(days), w(weeks),
        M(months), y(years)

example:
--------
Files younger than 10 minutes.
$ find -name pw.in | age.py -10m 
$ find -name pw.in -mmin -10

Files older than half a year.
$ age.py 0.5y $(locate pw.in)
$ age.py +128d $(locate pw.in)
$ find / -name pw.in -mtime 3840

Files between 3 and 1 month old.
$ locate pw.in | age.py -3M | age.py 1M
"""

def parse_offset(st):
    facs = {'s': 1.0,
            'm': 60.0,
            'h': 3600.0,
            'd': 24*3600.0,
            'w': 7*24*3600.0,
            'M': 30*24*3600.0,
            'y': 12*30*24*3600.0}
    modifier = st[-1]
    if modifier in facs.keys():
        return float(st[:-1]) * facs[modifier]
    else:
        return float(st)


if __name__ == '__main__':

    # no need for fancy optparse
    if sys.argv[1] in ['-h', '--help']:
        print_help()
        sys.exit()
    
    # sys.argv: 
    #   ['age.py', '+5m', 'file1', 'file2']
    #   ['age.py', '+5m'] # stdin 
    if len(sys.argv) == 1:
        raise StandardError("missing time offset")
    offset = parse_offset(sys.argv[1])
    
    # first try cmd line, then stdin
    files = sys.argv[2:]
    if files == []:
        files = [x.strip() for x in sys.stdin.readlines()]
    if files == []:    
        raise StandardError("missing files")
    
    # os.stat() returns a tuple of len 10, where the last three are 
    #     (..., st_atime, st_mtime, st_ctime) 
    # in seconds since Epoch. time.time() is the current time in seconds since
    # Epoch. We use "mtime", the last modification time to determine the file's
    # age.
    mtimes = np.array([os.stat(fn)[8] for fn in files])
    delta = time.time() - mtimes 
    # numpy rocks!        
    if offset < 0:
        idx = np.where(delta < -offset)
    else:        
        idx = np.where(delta > offset)
    # numpy rocks!        
    for fn in np.asarray(files)[idx]:
        print(fn)

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
import optparse
import numpy as np

usage = """
Filter files matching some time spec out of a list of files or sort files by
last modification time.

usage:
------
age.py [-h] [-o <offset> | -s] <files> 

age.py <files> -o <offset> 
age.py <files> -s
<files> | age.py -o <offset>
<files> | age.py -s

Use either -o/--offset or -s/--sort .

args:
-----
files : list of filenames "file1 file2 ..." if given as cmd line args
    or one file per line if piped in (e.g. output of locate)

options:
--------
-h, --help : show this help message and exit
-s, --sort : Sort files, most recent last (like ls -rt).
-o OFFSET, --offset=OFFSET : Time offset 
    Format <number><modifier>, where 
    <number> : any string that Python understands as a number. 
        number < 0 : files younger than abs(<offset>), e.g.: -10
        number > 0 : files older than <offset>, e.g.: 10, +10
    <modifier> : s(seconds) [default], m(minutes), h(hours), d(days), 
        w(weeks), M(months), y(years)

example:
--------
Files younger than 10 minutes.
$ find -name pw.in | age.py -o -10m 
$ find -name pw.in -mmin -10

Files older than half a year.
$ age.py -o 0.5y $(locate pw.in)
$ age.py -o +128d $(locate pw.in)
$ find / -name pw.in -mtime 3840

Files between 3 and 1 month old.
$ locate pw.in | age.py -o -3M | age.py -o 1M

Sort files.
$ ls -1rt 
$ ls -1 | age.py -s
$ locate ... | age.py -s

Sort files from last week, print last modification time.
$ find -name pw.in | age.py -o -1w | age.py -s | xargs -l stat -c '%y %n'
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
    
    # optparse: One cannot format help text w/ newlines, which we need
    # for --offset. Until everybody has python 2.7+ and we can use argparse, we
    # write the whole help string by ourselves and ditch automatic help
    # formatting.  
    sh = optparse.SUPPRESS_HELP
    parser = optparse.OptionParser(add_help_option=False)
    parser.add_option("-h", "--help", action="store_true", default=False, 
        help=sh)
    parser.add_option("-s", "--sort", action="store_true", default=False, 
        help=sh)
    parser.add_option("-o", "--offset", default=None, 
        help=sh)
    opts, args = parser.parse_args()
    if opts.help:
        print usage
        sys.exit()

    if (opts.offset is None) and (not opts.sort):
            raise StandardError("use -o/--offset or -s/--sort")
    elif (opts.offset is not None) and (opts.sort):
            raise StandardError("use only one of -o/--offset or -s/--sort")
    elif opts.offset is not None:
        offset = parse_offset(opts.offset)
    # else opts.sort == True        
    
    # first try cmd line, then stdin
    # args: 
    #   cmdline: ['file1', 'file2']
    #   stdin:   []
    files = args
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
    if opts.sort:
        idx = np.argsort(mtimes)
    else:
        delta = time.time() - mtimes 
        # numpy rocks!        
        if offset < 0:
            idx = np.where(delta < -offset)
        else:        
            idx = np.where(delta > offset)
    # numpy rocks!        
    for fn in np.asarray(files)[idx]:
        print(fn)

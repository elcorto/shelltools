#!/usr/bin/env python 

import re, argparse
import numpy as np

parser = argparse.ArgumentParser(description="""
Print mv comands to rename files in numeric order.

Only files which already have a number will be used (i.e. "10foo", "020bar",
"foo010bar", "baz123", but not "baz"). Numbers can be anywhere in the filename
(start, middle, end), but files with numbers in multiple places (like "20foo9")
are ignored just as are files without any numbers.

example:
$ sort-files-numeric.py e100 002b 0c 1b 2c 2d a5b baz 20foo9
mv 0c 10c
mv 1b 20b
mv 002b 30b
mv 2c 30c
mv 2d 30d
mv a5b a40b
mv e100 e50

To execute the command, use "sort-files-numeric.py ... | sh"
""",
formatter_class=argparse.RawDescriptionHelpFormatter)

parser.add_argument('files', metavar='file', nargs='+', help='file name to rename')
parser.add_argument('-i', '--incr',
                    default=10, type=int,
                    help='integer increment for renaming files [default: %(default)i]')
parser.add_argument('-l', '--length',
                    default=0, type=int,
                    help="Make numbers of LENGTH digits, using leading zeros (e.g. 010 instead \
                          of 10) if needed. Default is 0, which means use \
                          numbers as they are.")

args = parser.parse_args()


rex = re.compile(r'([^0-9]*)([0-9]+)([^0-9]*)$')
matches = [m for m in [rex.match(fn) for fn in args.files] if m is not None]
nums_str = np.array([m.group(2) for m in matches])
nums = np.array([int(x) for x in nums_str])
first = np.array([m.group(1) for m in matches])
last = np.array([m.group(3) for m in matches])

sort_msk = np.argsort(nums)
nums_str = nums_str[sort_msk]
first = first[sort_msk]
last = last[sort_msk]
nums = nums[sort_msk]

new_num = args.incr 
for idx in range(len(matches)):
    if idx > 0:
        if nums[idx] != nums[idx-1]:
            new_num += args.incr
    if args.length > 0:
        fmt = '{}{:0>%i}{}' %args.length
    else:
        fmt = '{}{}{}'
    old = '{}{}{}'.format(first[idx], nums_str[idx], last[idx])
    new = fmt.format(first[idx], new_num, last[idx])
    print("mv {} {}".format(old,new))
    

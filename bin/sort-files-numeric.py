#!/usr/bin/env python3

import re, argparse
import numpy as np

parser = argparse.ArgumentParser(description="""
Print mv comands to rename files in numeric order.

Only files which already have a number will be used (i.e. "10foo", "020bar",
"foo010bar", "baz123", but not "baz"). Numbers can be anywhere in the filename
(start, middle, end). Files without any numbers are ignored. Files with numbers
in multiple places (like "20foo9") are ignored by default. In that case, force
to use only certain positions with the -p/--position option.

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
parser.add_argument('-p', '--position',
                    default='a', type=str,
                    help='force to use only numbers at the (s)tart, (m)iddle or (e)nd \
                    or use (a)ll = s or m or e [default: %(default)s]')

args = parser.parse_args()

if args.position == 's':
    rex = re.compile(r'^([0-9]+)([^0-9]+.*)$')
elif args.position == 'm':
    rex = re.compile(r'^(.*[^0-9]+)([0-9]+)([^0-9]+.*)$')
elif args.position == 'e':
    rex = re.compile(r'^(.*[^0-9]+)([0-9]+)$')
elif args.position == 'a':
    rex = re.compile(r'^([^0-9]*)([0-9]+)([^0-9]*)$')
else:
    raise ValueError("unknown position value: {}".format(args.position))

matches = [m for m in [rex.match(fn) for fn in args.files] if m is not None]

empty_grp = np.array(['']*len(matches))
grp1 = np.array([m.group(1) for m in matches])
grp2 = np.array([m.group(2) for m in matches])
if args.position == 's':
    first = empty_grp
    nums_str = grp1
    last = grp2
elif args.position == 'e':
    first = grp1
    nums_str = grp2
    last = empty_grp
elif args.position in ['a', 'm']:
    first = grp1
    nums_str = grp2
    last = np.array([m.group(3) for m in matches])

nums = np.array([int(x) for x in nums_str])

sort_msk = np.argsort(nums)
nums_str = nums_str[sort_msk]
first = first[sort_msk]
last = last[sort_msk]
nums = nums[sort_msk]

new_num = args.incr
for idx in range(len(matches)):
    if idx > 0:
        new_num += args.incr
    if args.length > 0:
        fmt = '{}{:0>%i}{}' %args.length
    else:
        fmt = '{}{}{}'
    old = '{}{}{}'.format(first[idx], nums_str[idx], last[idx])
    new = fmt.format(first[idx], new_num, last[idx])
    if old != new:
        print("mv {} {}".format(old,new))

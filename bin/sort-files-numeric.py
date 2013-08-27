#!/usr/bin/env python 

import re, argparse
import numpy as np

parser = argparse.ArgumentParser(description="""
Print mv comands to rename files in numeric order.

Only files which already start with a number will be used (i.e. "10foo",
"020bar", but not "baz").

example:
$ sort-files-numeric.py 100e 002b 0c 1b 2c 2d ff
mv 0c 10c
mv 1b 20b
mv 002b 30b
mv 2c 30c
mv 2d 30d
mv 100e 40e

To execute the command, use "sort-files-numeric.py ... | bash"
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


rex = re.compile(r'([0-9]+)(.*)')
matches = [m for m in [rex.match(fn) for fn in args.files] if m is not None]
nums_str = np.array([m.group(1) for m in matches])
nums = np.array([int(x) for x in nums_str])
names = np.array([m.group(2) for m in matches])

sort_msk = np.argsort(nums)
nums_str = nums_str[sort_msk]
names = names[sort_msk]
nums = nums[sort_msk]

new_num = args.incr 
for idx in range(len(matches)):
    if idx > 0:
        if nums[idx] != nums[idx-1]:
            new_num += args.incr
    if args.length > 0:
        fmt = '{:0%id}{}' %args.length
    else:
        fmt = '{}{}'
    old = '{}{}'.format(nums_str[idx], names[idx])
    new = fmt.format(new_num, names[idx])
    print("mv {} {}".format(old,new))
    

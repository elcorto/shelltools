#!/usr/bin/python

"""
Example rst file for conversion (pandoc -f rst ...)
----------------------------------------------------
one line::

    1 2 3 4

two lines::

    1 2 3 4
    5 6 7 8

two lines with blank::

    1 2 3 4

    5 6 7 8

``inline literal``

[[wiki link must be unchanged]]

* bullet
* list

.. this is a comment and will be ignored
----------------------------------------------------
"""


import sys, argparse
from argparse import RawTextHelpFormatter

desc = "Fix pandoc (rst to) textile markup conversion for redmine."
usage = "pandoc -f <format> -t textile <file> | %(prog)s"
epilog = """
known issues:
* multi-level bullet lists not supported
"""

parser = argparse.ArgumentParser(description=desc, usage=usage,
                                 epilog=epilog, 
	                         formatter_class=RawTextHelpFormatter)
args = parser.parse_args()

txt = ''
inblock = False
for line in sys.stdin:
    if line.startswith('bc.'):
        inblock = True            
        txt += "<pre>\n"
        txt += line.strip().replace('bc. ','') + '\n'
        continue
    if inblock:
        if line.strip() == "":
            txt += "</pre>\n"
            inblock = False
        else:                
            txt += line
    else:
        txt += line

repl = {r'&lt;': '<',
        r'&gt;': '>',
        r'&quot;': '"',
        r'<tt>': '@',
        r'</tt>': '@',
        r'&#95;': ' ',
        }

for key,val in repl.iteritems():
    txt = txt.replace(key, val)
print(txt)               

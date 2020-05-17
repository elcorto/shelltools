#!/usr/bin/python2

"""
Example rst file for conversion (pandoc -f rst ...): See
test/files/rst2textile/input.rst

Stuff we fix
============

bc blocks
---------

rst:

    ::
        foo
        bar
        baz

wrong:

    bc. foo
    bar
    baz

right:

    <pre>
    foo
    bar
    baz
    </pre>

html
----

All html stuff starts with "<.." on every line. This is good for parsing, i.e.
we don't have to fix things like

    <foo>
        some text 
    </foo>

but instead only things like 

    <table>
    <tbody>
    <tr class="odd">
    <td>foo</td>
    <td>bar</td>
    <td>baz</td>
    </tr>
    ....


random utf8 hickups
-------------------
see `repl`
"""

import sys, argparse
from subprocess import Popen, PIPE
from argparse import RawTextHelpFormatter

# HTML block end detection and conversion (see inblock_html) fails if the last
# line is also html, e.g. starts with a '<'. Then we print nothing since the
# "block of html" is never left. Solution: we output an extra empty line after
# iteration end (last line). Another option would be to check for end-of-file
# in the loop. Well, we actually do that with catching StopIteration in
# StdinIter already.
#
##class StdinIter(collections.Iterator):
##    """Loop over sys.stdin and print an empty line " " (one whitespace) at
##    the end. 
##
##    Examples
##    --------
##    >>> # instead of "for line in sys.stdin"
##    >>> for line in iter(StdinIter()):
##    >>> ... print(line)
##    """
##    _last = False
##    def next(self):
##        if self._last:
##            raise StopIteration
##        else:
##            try:
##                return sys.stdin.next()
##            except StopIteration:
##                self._last = True
##                return ' '

desc = """
Convert pandoc-generated textile to Redmine-flavored textile.
"""
epi = """
Notes
-----
This script is used in rst2textile.sh, where we already do some pre-processing
as in rst -> markdown[_strict] -> textile instead of direct rst -> textile (see
the -m flag). This takes care of most of the nasty html which would otherwise
be present in directly generated textile. The rest html (tables!) is treated
here.
"""
usage = "pandoc ... -t textile | %(prog)s"

parser = argparse.ArgumentParser(description=desc, usage=usage, epilog=epi,
	                         formatter_class=RawTextHelpFormatter)
args = parser.parse_args()

txt = ''
html = ''
inblock_bc = False
inblock_html = False
##stdin = iter(StdinIter())
# much simpler: append extra line 
for line in sys.stdin.readlines() + [" "]:
    if line.startswith('bc.'):
        inblock_bc = True
        txt += "<pre>\n"
        txt += line.strip().replace('bc. ','') + '\n'
        continue
    elif line.startswith('<') and not 'pre>' in line:
        inblock_html = True
    if inblock_bc:
        if line.strip() == "":
            txt += "</pre>\n"
            inblock_bc = False
        else:
            txt += line
    elif inblock_html:
        if not line.startswith('<'):
            inblock_html = False
            pp = Popen(r"pandoc -f html -t textile",
                       stdin=PIPE, stdout=PIPE, stderr=PIPE, shell=True)
            stdout = pp.communicate(html)[0]
            txt += stdout
            html = ''
        else:
            html += line
    else:
        txt += line

# deal with pandoc utf8 encoding (and other) hickups
repl = {r'&lt;': '<',
        r'&gt;': '>',
        r'&quot;': '"',
        r'<tt>': '@',
        r'</tt>': '@',
        r'&#64;': '@',
        r'&#95;': '_',
        r'&#45;': '-',
        r'&#43;': '+',
        r'&#42;': '*',
        r'&#124;': '|',
        r'"$":': '',
        r'&amp;': '&',
        r'<!-- -->': '',
        }

for key,val in repl.iteritems():
    txt = txt.replace(key, val)
print(txt)


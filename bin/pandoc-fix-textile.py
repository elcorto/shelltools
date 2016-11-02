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


random utf8 hickups
-------------------
see `repl`
"""


import sys, argparse
from subprocess import Popen, PIPE
from argparse import RawTextHelpFormatter

desc = """
Convert pandoc-generated textile to Redmine-flavored textile.
"""
epi = """
Notes
-----
Use together with rst2textile.sh, where we already do some pre-procesing
as in rst -> markdown_strict -> textile instead of direct rst -> textile.
Especially, this takes care of nasty html which would otherwise be present in
directly generated textile.
"""
usage = "pandoc ... -t textile | %(prog)s"

parser = argparse.ArgumentParser(description=desc, usage=usage, epilog=epi,
	                         formatter_class=RawTextHelpFormatter)
args = parser.parse_args()

txt = ''
html = ''
inblock_bc = False
for line in sys.stdin:
    if line.startswith('bc.'):
        inblock_bc = True            
        txt += "<pre>\n"
        txt += line.strip().replace('bc. ','') + '\n'
        continue
    if inblock_bc:
        if line.strip() == "":
            txt += "</pre>\n"
            inblock_bc = False
        else:                
            txt += line
    else:
        txt += line

# deal with pandoc utf8 encoding hickups
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
        }

for key,val in repl.iteritems():
    txt = txt.replace(key, val)
print(txt)               


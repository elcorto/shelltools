#!/usr/bin/python

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
...
</foo>

rst:

    * foo
        * bar
        * baz

wrong:

    <ul>
    <dt>foo<dt>
    <dd><ul>
    <li>bar</li>
    <li>baz</li>
    </ul>
    </dd>
    </ul>
... or similar, I don't speak html much.

right:

    * foo
    ** bar
    ** baz

random utf8 hickups
-------------------
see `repl`
"""


import sys, argparse
from subprocess import Popen, PIPE
from argparse import RawTextHelpFormatter

desc = "Convert pandoc's textile to Redmine-flavored textile."
usage = "pandoc -f <format> -t textile <file> | %(prog)s"

parser = argparse.ArgumentParser(description=desc, usage=usage,
	                         formatter_class=RawTextHelpFormatter)
args = parser.parse_args()

txt = ''
html = ''
inblock_bc = False
inblock_html = False
for line in sys.stdin:
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
            # Yes this is a hack. Used to make underscores survive html ->
            # textile conversion. Patches welcome!
            pp = Popen(r"pandoc -f html -t markdown_strict \
                            | sed -re 's/\\_/XXXunderscoreXXX/g' \
                            | pandoc -f markdown_strict -t textile \
                            | sed -re 's/XXXunderscoreXXX/_/g'", 
                       stdin=PIPE, stdout=PIPE, stderr=PIPE, shell=True)
            stdout = pp.communicate(html)[0]
            txt += stdout
            html = ''
        else:                
            html += line
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


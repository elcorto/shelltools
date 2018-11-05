#!/bin/sh

# Strip comments and blank lines from files.

sed -r -e 's/\s*#.*$//g; /^\s*$/d' $1

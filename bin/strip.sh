#!/bin/sh

# Srtip comments and blank lines from (ini-style config) files.

sed -r -e '/^\s*#.*$/d; /^\s*$/d; s/^\[/\n\[/g; s/#.*$//g' $1

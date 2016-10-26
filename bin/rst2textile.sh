#!/bin/sh

if echo "$@" | grep -qEe '-h|--help'; then
    cat << EOF
Convert rst to Redmine-style textile markup.

usage:
    $(basename $0) file.rst
EOF
    exit 0
fi

pandoc -f rst -t textile $1 | pandoc-fix-textile.py

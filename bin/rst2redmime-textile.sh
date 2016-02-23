#!/bin/sh

pandoc -f rst -t textile $1 | pandoc-fix-textile.py

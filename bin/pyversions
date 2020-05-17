#!/bin/sh

# Replacement for Debian's `/usr/bin/pyversions` tool (from python-central)
# which is not available on other distros like SuSE.
#
# `pyversions -d` prints the default Python version as e.g. "python2.5". Only
# this functionallity is implemented here (and in fact -d is ignored). This is
# 10x faster than the real pyversions -d.

python -V 2>&1 | sed -re 's/.*ython ([0-9]\.[0-9])(\.[0-9])*/python\1/g'

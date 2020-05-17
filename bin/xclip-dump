#!/bin/sh

for sel in primary secondary clipboard; do
    echo "$sel: $(xclip -o -selection $sel 2>&1 \
        | grep -v 'Error: target STRING not available')"
done

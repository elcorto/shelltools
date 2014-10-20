#!/bin/bash

for cmd in "hg st" "hg st --mq" "hg qseries -v" "hg in" "hg in --mq" "hg out" \
           "hg out --mq"; do 

    txt=$(eval "$cmd 2>&1")
    if test -n "$txt" && ! echo "$txt" | grep -q 'no changes found'; then
        echo ">>> $cmd"
        echo "$txt" | sed "s/^/    /"
    fi
done

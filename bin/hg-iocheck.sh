#!/bin/bash

for cmd in "hg st" "hg st --mq" "hg qseries -v" "hg in" "hg in --mq" "hg out" \
           "hg out --mq"; do 
    cat << eof
>>> $cmd
$(eval $cmd)

eof
done

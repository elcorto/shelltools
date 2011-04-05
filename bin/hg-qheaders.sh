#!/bin/bash

for pp in $(hg qseries); do 
    hg qgoto $pp > /dev/null 
    echo "======== $pp ========"
    hg qheader 
    echo "  "
done

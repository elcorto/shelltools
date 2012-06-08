#!/bin/bash

# Apply each patch and do ``hg qdi --st``. This is for quickly finding out
# which patches change which files.
#
# Use the "-v" option to see the ``hg qheader`` as well.

verbose=false
if [ "$1" = "-v" ]; then
    verbose=true
fi

for pn in $(hg qseries); do 
    echo -e "\n\n=============== $pn ==============="
    hg qgoto $pn
    hg qdi --st
    if $verbose; then
        echo " "
        hg qheader
    fi        
done | egrep -v 'applying|popping|now at|files changed'

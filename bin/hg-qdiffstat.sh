#!/bin/bash

# Apply each patch and print compact form of "hg qdi --st". This is for quickly
# finding which patches change which files.

for pn in $(hg qseries); do 
    echo -e "\n\n=============== $pn ===============" 
    hg qgoto $pn
    hg qdi --st 
done | egrep -v 'applying|popping|now at|files changed'

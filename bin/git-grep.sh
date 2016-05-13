#!/bin/sh

# Grep in all revisions. I always tend to forget this. This is like 
#     
#     hg grep --all
# 
# (hopefully).   

git rev-list --all | xargs git grep $@ 

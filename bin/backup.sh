#!/bin/bash

set -e

prog=$(basename $0)
simulate=false
prefix='.'
delete=false
incr=true
usage(){
    cat <<EOF
Backup (copy) <src> (file, dir, symlink) to <src><prefix><num>, where <num> is
an integer starting at 0 which is incremented until there is no destination
with that name. For symlinks, the link target is copied, with -d, the symlink
(not the target) is deleted:

    file/dir    symlink
    cp          cp -L
-d  mv          cp -L && rm   

usage:
------
$prog [-hsdn] [-p <prefix>] files... dirs...

options:
--------
-s : simulate
-p : prefix, default: '$prefix'
-d : delete <src> after backup
-n : no number, copy only to <src><prefix>
EOF
}

# optimization: in case of file/dir and -d, use mv instead of cp && rm,
# must check type of $src for that
cmdline=$(getopt -o hnsdp: -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -s)
            simulate=true
            ;;
        -d)
            delete=true
            ;;
        -n)
            incr=false
            ;;
        -p)
            prefix=$2
            shift
            ;;
        -h)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)  
            echo "Cmd line error! Grab a coffee and recompile your kernel :)"
            exit 1
            ;;
    esac
    shift
done

src_lst=$@
[ -z "$src_lst" ] && echo "$prog: no sources, nothing to do" && exit 1
for src in $src_lst; do
    src=$(echo $src | sed -re 's|/*$||')
    dst=${src}${prefix}
    if $incr; then
        idx=0
        dst=${dst}${idx}
        while [ -f $dst -o -d $dst -o -L $dst ]; do
            idx=$(expr $idx + 1)
            dst=${src}${prefix}${idx}
        done
    fi        
    # sanity check
    if ! [ -f $dst -o -d $dst -o -L $dst ]; then
        cmd="cp -rvL $src $dst"
        $delete && cmd="$cmd && rm -rv $src"
        $simulate && echo $cmd || eval $cmd
    else
        echo "$prog: $dst exists"
        exit 1
    fi 
done

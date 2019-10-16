#!/bin/sh

set -eu

prog=$(basename $0)
tgt_dir=./
percent=30

usage(){
    cat << EOF
usage:
    $prog [-t <tgt_dir>] [-p <percent>] <files>

options:
    -t : target dir [default: $tgt_dir]
    -p : percent to resize to in "convert -resize <percent>%" [default: $percent]
EOF
}

err(){
    echo "$prog: error: $@"
    exit 1
}


while getopts ht:p: opt; do
    case $opt in
        h) usage; exit 0;;
        t) tgt_dir="$OPTARG";;
        p) percent=$OPTARG;;
        \?) exit 1;;
    esac
done
shift $((OPTIND - 1))

[ $# -ge 1 ] || err "missing file args"

for fn in $@; do
    convert -resize ${percent}% $fn $tgt_dir/$(basename $fn)
done

#!/bin/sh

set -eu

abspath(){
    readlink -f $1
}


err(){
    echo "$prog: error: $@"
    exit 1
}


prog=$(basename $0)
tgt_dir=$(abspath $(pwd))
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


while getopts ht:p: opt; do
    case $opt in
        h) usage; exit 0;;
        t) tgt_dir="$(abspath $OPTARG)";;
        p) percent=$OPTARG;;
        \?) exit 1;;
    esac
done
shift $((OPTIND - 1))

[ $# -ge 1 ] || err "missing file args"

for fn in $@; do
    src_dir=$(abspath $(dirname $fn))
    [ "$src_dir" = "$tgt_dir" ] && err "$fn: src_dir ($src_dir) = tgt_dir
($tgt_dir), won't overwrite"
    convert -resize ${percent}% $fn $tgt_dir/$(basename $fn)
done

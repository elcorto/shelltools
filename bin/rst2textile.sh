#!/bin/sh

method=1
fix_cmd=pandoc-fix-textile.py

usage(){
    cat << EOF
Convert rst to Redmine-style textile markup. Uses $fix_cmd.

usage:
    $(basename $0) [-v] [-m <method>] file.rst

options:
    -v : verbose, print "DEBUG: ..."
    -m : conversion method (integer)
        0 = rst -> textile
        1 = rst -> markdown_strict -> textile
        2 = rst -> markdown -> textile
        default: $method
EOF
}

err(){
    echo "error: $@"
    exit 1
}

debug(){
    $verbose && echo "DEBUG: $@"
}


verbose=false
while getopts hvm: opt; do
    case $opt in
    m)   method=$OPTARG
         ;;
    v)   verbose=true
         ;;
    h)   usage
         exit 0
         ;;
    '?') echo "$0: invalid option -$opt" >&2
         echo $USAGE >&2
         exit 1
         ;;
esac done
shift $((OPTIND - 1))


if [ $method -eq 0 ]; then
    cmd="pandoc -f rst -t textile $1 | $fix_cmd"
else
    if [ $method -eq 1 ]; then
        middle=markdown_strict
    elif [ $method -eq 2 ]; then
        middle=markdown
    else
        err "unknown method"
    fi
    cmd="pandoc -f rst -t $middle $1 \
        | pandoc -f $middle -t textile \
        | $fix_cmd"
fi

debug "$cmd"
eval "$cmd"

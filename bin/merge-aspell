#!/bin/bash

prog=$(basename $0)
usage(){
cat <<EOF
Merge aspell database files.

usage
-----
$prog .aspell.en.pws.foo .aspell.en.bar ... > .aspell.en.pws.new
EOF
}

if echo $@ | grep -Eqe '-h|--help'; then
    usage
    exit 0
fi    

get_header(){
    # extract part of first line: "personal_ws-1.1 en <number-of-lines>"
    #                              ^^^^^^^^^^^^^^^^^^
    head -n1 $1 | sed -re 's/(.*)\s+[0-9]+/\1/'
}    

tmp=$(mktemp)

header_old=$(get_header $1)
for fn in $@; do
    header=$(get_header $fn)
    if [ "$header" != "$header_old" ]; then
        echo "header: $header, header_old: $header_old"
        echo "error: inconsistent headers"
        exit 1
    else    
        header_old=$header
    fi
    sed -n '2,$p' $fn
done | sort -u > $tmp

# cannot use $header here probably b/c the loop is executed in a subshell if we
# pipe the result to sort, so here header=''
echo "$header_old $(wc -l < $tmp)"
cat $tmp

rm $tmp

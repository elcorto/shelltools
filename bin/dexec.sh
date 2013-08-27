#!/bin/bash

prog=$(basename $0)
dirfile="$HOME/dirfile"

usage(){
    cat << EOF

Execute a command in all dirs in \$dirfile. The dirfile lists all dirs (one
per line). Comments starting with "#" are allowed.
    foo
    bar/baz/
    ...

usage:
------
$prog [<options>] [-f <dirfile>] [--] [<command>]

args:
-----
<command> : command to execute in all dirs in the dirfile, if missing then
    stdin is used

options:
--------
-v : verbose, print commands
-s : simulate, this is the same as verbose but commands are not executed
-f : path to dirfile 
    [default: $dirfile]
-F : fork (use " ... &")
-a : annotate (prepend output from each dir with it's dirname)

examples:
---------
$ $prog -a -f dirfile -- "rm oe.* *.out; qsub job.foo.cluster"
$ cat script.sh | $prog -a -f dirfile
EOF
}

simulate=false
verbose=false
fork=false
annotate=false

cmdline=$(getopt -o d:vcsFaf:h -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case "$1" in 
        -v)
            verbose=true
            ;;
        -s)
            simulate=true
            ;;
        -f)
            dirfile=$2
            shift
            ;;
        -F)
            fork=true
            ;;
        -a)
            annotate=true
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
            echo "cmdline error"
            exit 1
            ;;
    esac
    shift
done

$simulate && verbose=true

if ! [ -f $dirfile  ]; then
    echo "error: file not found: $dirfile"
    exit 1
fi    

dirs=$(awk '/^\s*[^#]/' $dirfile)
$verbose && echo $dirs

if [ $# -eq 0 ]; then
    dir_cmd="$(cat)"
else
    dir_cmd="$@"
fi

here=$(pwd)
for dir in $dirs; do
    cmd="cd $dir; $dir_cmd"
    if $annotate; then
        cmd="$cmd | sed -re 's/^/${dir}: /g'"
    fi
    cmd="$cmd; cd $here"
    $verbose && echo "$cmd"
    if $fork; then
        $simulate || eval "$cmd" &
    else        
        $simulate || eval "$cmd"
    fi
done

exit 0

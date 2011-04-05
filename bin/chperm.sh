#!/bin/sh

prog=$(basename $0)

function usage(){
    cat << eof

Change perms of all ordinary files and/or dirs in <dir>. Select files by clever
find(1) options (\$findopts).
Don't panic, you will be asked before any action is started.

usage:
$prog <dir> <findopts> <perm> [-s] [-v] [-h] 
    
    args:
    -----
    dir : a path
    findopts : search options for find 
        See find(1). All files and dirs found by this pattern will be examined.
        Note the quotes! Otherwise options to find(1) will be interpreted as
        options to $prog.
        example: "'-perm -g=x,u=x -type f'"
    perm : new permissions, everything that chmod would accept

    opts:
    -----
    -s  simulate
    -h  show help
    -v  verbose

    examples:
    ---------
    chperm.sh . "'-type d'" 700
    Change all dir perms in the current dir and below to 700.

    chperm.sh ~/work/ "'-regextype posix-extended -type f -perm /g=r ! -regex (.*\.py$)|(.*\.out$)'" g-r 
    Remove group read perms from all files that have them. Skip *.py and *.out
    files.

    chperm.sh ~/work/ "' -type f -perm /g=r ! ( -name *.py -o -name *.out )'" g-r
    The same.
    
    chperm.sh ~/work/ "'-type f ! -perm /ugo=x'" 644 -s
    Simulate the run. Change all file perms to 644. Skip files with execute 
    permision in 'u', 'g' or 'o'.
    
    
    more permissions:

    -perm /u=r,o=r
    -perm /uo=r
    User OR other have r perm.

    -perm -uo=r
    -perm -u=r,o=r
    User AND other have r perm.

    -type f ! -perm /ugo=x
    All files that do NOT have x perm for u OR g OR o.

    -type f ! -perm /g=r ! -name ".*"
    All files that don't have group read perms and don't start with a dot (e.g.
    so as to skip vim temp files like ".file.swp").

    Note that you don't have to escape "(", ")" and regexes and such in the
    \$findopts.
eof
}

# --- use getopt(1) -----------------------------
#
# -> cool
#
# Python's getopt.gnu_getopt() is cool and eays. In bash, getopt(1) can do
# the same: intermixing of opts and args, automatic extraction of args,
# optional arguments etc.
#
# It reorders $@: options first, args last: 
#   
#   <options, options with args> -- <args>
#
# example:
#   # -k has required arg
#   # -g has optional arg
#   # -s, -h are flags (normal opts, switches)
#   tmp=$(getopt -o g::shk: -n $prog -- "$@")
#   [call: $prog -s foo -k karg] 
#   echo $tmp
#   -s -k 'karg' -- 'foo'
#
# Now we can parse this as usual. Everything after `--' are the normal args.
#
# The `--' in the getopt call is important. It raises an error if "-k" is used
# w/o an argument, since the option was defined "-k:" and therefore has a
# required arguent. Downside: it *may* (read: unlikely) break some compat with
# older getopt implementations. See getopt(1).
#
# For a complete example: `locate getopt-parse.bash` on every decent Linux
# distro.
#
verbose=false
simulate=false
cmdline=$(getopt -o hsv -n $prog -- "$@")
# make $@=$cmdline so that it can be parsed as if we had gotten it directly
# from the cmd line into $@
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -v)
            verbose=true
            ;;
        -s)
            simulate=true
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
            echo "Internal error! Grab a coffee and recompile your kernel :)"
            exit 1
            ;;
    esac
    shift
done
nargs=3
if $verbose; then
    echo "cmdline: '$cmdline'"
fi    
if test $# -ne 3; then
    echo "$prog: error: need 3 args, -h for help"
    exit 1
else
    dir=$1
    # $findopts come in as single-quoted string, make normal
    # string before handing it to `find` as option '-foo -bar' -> "-foo -bar"
    findopts="$(eval echo $2)"
    perm=$3
fi

if $verbose; then
    echo "perm: '$perm'"
    echo "findopts: '$findopts'"
fi

all_files=$(find $dir $findopts)
for file in $all_files; do
    echo "will chmod $perm $(ls -ld $file | awk '{print $1}') $file"
done
if [ -z "$all_files" ]; then
    echo "no matches found"
    exit 0
else
    if ! $simulate; then
        echo "go ahead? [y]/n"
        read ans
        if [ "$ans" = "" -o "$ans" = "y" ]; then
            for file in $all_files; do
                chmod $perm $file
            done
        fi        
    else        
        echo "simulate, nothing done"
    fi
fi    

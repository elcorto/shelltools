#!/bin/bash

prog=$(basename $0)
simulate=false
ownr=
grp=
who=go
stopdir=$(pwd)
usage(){
    cat << EOF
Make a selected dir and the path to it readable. In <dir> set 
    +rx (subdirs)
    +r  (files)
    +x  (executables) 
Also make the path down to <dir> accessible, starting at, but not including,
<stopdir>. You can also set owner and/or group.

Use this when "chmod -R 777" is just not what you want.

usage:
------
$prog [-hs] [-w <who>] [-d <stopdir>] [-o <owner>[:<group>]] [-g <group>] <dir>

options:
--------
-s : simulate
-w : <who>: For whom to set permissions (e.g. 'g', 'o', 'go', like in chmod).
     [default: $who]
-d : <stopdir>
     [default: $stopdir]
-o : argument to chown(1).
-g : argument to chgrp(1).

example:
--------
Imagine this layout:
a
├── b
│   └── c
│       ├── d
│       │   ├── file1
│       │   └── file2
│       └── e
│           ├── file3
│           └── file4
└── f
    └── g
        └── h

Make a/b/c/d and the path to it (a/b/c) readable. This would leave the sidetree
a/f/g/h and the subdir e/ alone, for instance.
    $prog a/b/c/d/

The same, but stop at a/b, i.e. change only subtree c/d/.
    $prog -d a/b a/b/c/d/

The same, but set only user perms (-w u), and set owner. Same as "-w u -o elcorto -g
elcorto". 
    $prog -w u -d a/b a/b/c/d -o elcorto:elcorto

Always use -s to be sure you do The Right Thing (tm).
EOF
}

msg(){
    echo "$prog: $@"
}    

err(){
    echo "$prog: error: $@"
    exit 1
}    

expandpath(){
    # Print full path of some relative path (like ".", or "a/").
    path=$1
    # Use GNU readlink. If you don't have it, use fullpath=$(cd $path; pwd).
    # This will be executed in a subshell, so you ain't cd-ing nowhere here.
    readlink -e $path
}

change(){
    # use global var $simulate
    local cmd="$@"
    $simulate && msg "$cmd" || eval $cmd
}

cmdline=$(getopt -o hsd:w:o:g: -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case "$1" in 
        -s)
            simulate=true
            ;;
        -w)
            who=$2
            shift
            ;;
        -d)
            stopdir=$2
            shift
            ;;
        -o)
            ownr=$2
            shift
            ;;
        -g)
            grp=$2
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
            echo "cmdline error"
            exit 1
            ;;
    esac
    shift
done

dr=$1
[ -z "$dr" ] && err "dir missing"
! [ -d "$dr" ] && err "not a dir: $dr"
! [ -d "$stopdir" ] && err "not a dir: $stopdir"
dr=$(expandpath $dr)
stopdir=$(expandpath $stopdir)

# First, set perms inside the target dir.

# directories
tgts=$(find $dr -type d)
if [ -n "$tgts" ]; then 
    change "chmod $who+rx $tgts"
    [ -n "$ownr" ] && change "chown $ownr $tgts"
    [ -n "$grp" ] && change "chgrp $grp $tgts"
fi    

# all files
tgts=$(find $dr -type f -perm -u+r)
if [ -n "$tgts" ]; then 
    change "chmod $who+r $tgts"
    [ -n "$ownr" ] && change "chown $ownr $tgts"
    [ -n "$grp" ] && change "chgrp $grp $tgts"
fi    

# executables
tgts=$(find $dr -type f -perm -u+x)
if [ -n "$tgts" ]; then 
    change "chmod $who+x $tgts"
    [ -n "$ownr" ] && change "chown $ownr $tgts"
    [ -n "$grp" ] && change "chgrp $grp $tgts"
fi    

# Now, set perms along the path (from $stopdir downwards) *to* the target dir.
while [ "$dr" != "$stopdir" ]; do
    change "chmod $who+rx $dr"
    [ -n "$ownr" ] && change "chown $ownr $dr"
    [ -n "$grp" ] && change "chgrp $grp $dr"
    dr=$(dirname $dr)
done


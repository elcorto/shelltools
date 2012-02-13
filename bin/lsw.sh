#!/bin/bash

# /usr/local/lsw/
lswdir=./lsw
# /usr/local/
tgtdir=.
configfile=$HOME/.lswrc
simulate=false
show=false

prog=$(basename $0)
usage(){
    cat << EOF
lsw -- the Link SWitcher.

Make a symlink <tgtdir>/<link> -> <lswdir>/<real>, i.e. "install" a package (a
directory) under a different name. Use this to switch between a stable and
devel install, for instance. Useful for all software which doesn't really need
to be installed, a.k.a. configure && make && make install. For example Python
packages which you just copy somewhere.

usage:
------
$prog [-t <tgtdir>] [-d <lswdir>] [-hsS] [<real> <link>]

args:
-----
real : the name of the package, e.g. foo-dev for ./lsw/foo-dev
link : the name of the link, e.g. foo for foo -> ./lsw/foo-dev

options:
-------- 
-t : target dir [default: $tgtdir]
-d : lsw dir [default: $lswdir]
-h : help
-S : show possible sources <lswdir>/*, doesn't need <real> and <link> args
-s : simulate

examples:
---------
Say you have 2 versions of Python package "foo", namely "foo-dev" and
"foo-stable" and want to switch between them. You have your PYTHONPATH set to
/home/python, therefore you want the package to be known under
/home/python/foo. You simply place the releases to 

    /home/python/lsw/foo-dev
    /home/python/lsw/foo-stable

With no config file:
    $ cd /home/python
    $ $prog foo-dev foo
would link
    /home/python/foo -> /home/python/lsw/foo-dev

Now, switch to the stable release:
    $ $prog foo-stable foo
That's it!

The config file overrides the defaults
    $ cat ~/.lswrc
    lswdir=/usr/local/lsw
    tgtdir=/usr/local
    $ $prog foo-dev foo
would link    
    /usr/local/foo -> /usr/local/lsw/foo-dev

And -t / -d override the config file. Thus the above is the same as
    $ $prog -d /usr/local/lsw -t /usr/local foo-dev foo

notes:
------
This is inspired by GNU Stow, but works differently. Stow links *different*
packages (e.g. /usr/local/stow/perl/* and /usr/local/stow/emacs/*) into the
*same* dir(s) /usr/local/{bin,lib,...}. Here, we simply make a link pointing to
a complete install in order to "rename" it. If this can be done with Stow, tell
me!

EOF
}

err(){
    echo "$prog: error: $@"
    exit 1
}

action(){
    if $simulate; then
        echo $@
    else
        eval $@
    fi        
}

# Source config file if existing, override defaults. Then parse cmd line,
# overriding confing file.
[ -f $configfile -o -e $configfile ] && . $configfile

cmdline=$(getopt -o hsSt:d:c: -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case "$1" in 
        -s)
            simulate=true
            ;;
        -S)
            show=true
            ;;
        -t)
            tgtdir=$2
            shift
            ;;
        -d)
            lswdir=$2
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

if $show; then
    # find current links in $tgtdir
    links=$(find $tgtdir -type l | xargs -l ls -l | grep "$lswdir")
    cat << EOF
dirs:    
    tgtdir=$tgtdir
    lswdir=$lswdir

possible sources <real> in <lswdir>:
$(ls -1 $lswdir | sed 's/^/    /g')

current state:
    $links
EOF
exit 0
fi

if [ $# -ne 2 ]; then
    err "number of args not 2"
fi
real=$1
link=$2

src=$lswdir/$real
tgt=$tgtdir/$link

[ -e $src ] || err "source doesn't exist: $src"

# If it's a link, remove it, regardless of where it points. Dangerous? Else,
# error.
if [ -L $tgt ]; then
    action "rm -v $tgt"
elif [ -e $tgt ]; then
    err "target exists but is no link: $tgt"
fi
action "ln -s $src $tgt"

#!/bin/sh

prog=$(basename $0)

usage(){
    cat << eof
Change <oldmail> to <newmail> in git history. Change GIT_AUTHOR_EMAIL and if
-c is used also GIT_COMMITTER_EMAIL.

Test if it worked with "$prog -l" afterwards. 

If you get a "WARNING: Ref 'refs/heads/master' is unchanged", then nothing
needed to be changed.

usage
-----
$prog -l | [-c] <oldmail> <newmail>

options
-------
-l : only list available mails
-c : set GIT_COMMITTER_EMAIL as well

Notes
-----
You may want to do this after hg-fast-export, such as
    
    $ cat ~/map
    john = John Doe <mail@doe.com>
    gf = Gaylord Focker <gay@focker.org>
    $ cd git-repo
    $ git init 
    $ hg-fast-export -r /path/to/hg-repo -A ~/map
    $ git checkout

Alternatively, use a better user mapping file in the first place :) Note that
hg-fast-export sets author and committer to the same identity.

Note that "git filter-branch" creates a backup .git/refs/original/ and "git log
--all" takes that backup dir into account. So we move that dir away to a tmp
dir (a message is printed in that case).
eof
}

list=false
committer=false
cmdline=$(getopt -o hlc -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -l)
            list=true
            ;;
        -c)
            committer=true
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

if $list; then
    bak=.git/refs/original
    if [ -d $bak ]; then
        dr=$(mktemp -d --tmpdir=/tmp $prog-XXXXXXX)
        mv $bak $dr/
        echo "==> moved $bak to $dr"
    fi
    git log --all --format=format:"author:    %an %ae%ncommitter: %cn %ce" | sort -u
    exit 0
fi

if [ $# -eq 0 ]; then
    usage
    exit 1
fi    

oldmail=$1
newmail=$2

cmd="
if [ \$GIT_AUTHOR_EMAIL = $oldmail ]; then
        export GIT_AUTHOR_EMAIL=$newmail
fi
"

if $committer; then
cmd="$cmd
if [ \$GIT_COMMITTER_EMAIL = $oldmail ]; then
        export GIT_COMMITTER_EMAIL=$newmail
fi
"
fi

git filter-branch --env-filter "$cmd" -- --all

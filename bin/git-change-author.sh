#!/bin/sh

prog=$(basename $0)

usage(){
    cat << eof
Change git author/committer name/email. 

option      value changes                            
-e          GIT_AUTHOR_EMAIL        
-n          GIT_AUTHOR_NAME
-c -e       GIT_COMMITTER_EMAIL
-c -n       GIT_COMMITTER_NAME

Test if it worked with "$prog -l" afterwards. 

If you get a "WARNING: Ref 'refs/heads/master' is unchanged", then nothing
needed to be changed.

usage
-----
$prog -l | [-c] [-e | -n] <oldval> <newval>

arguments
---------
oldval, newval : old/new email (-e) or name (-n), use proper quoting

options
-------
-l : only list available authors and emails
-c : set GIT_COMMITTER_{NAME,EMAIL} as well

examples
--------
List.
    $prog -l

Author mail.
    $prog -e old@mail.com new@mail.com

Author and committer mail.
    $prog -c -e old@mail.com new@mail.com

Set author mail where there is none.
    $prog -e '' new@mail.com

Set new author and committer name.
    $prog -c -n john 'John Doe'

notes
-----
You may want to do this after hg-fast-export, such as
    
    $ cat ~/map
    john = John Doe <mail@doe.com>
    gf = Gaylord Focker <gl@focker.org>
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
cmdline=$(getopt -o hlcen -n $prog -- "$@")
oldmail=
newmail=
oldname=
newname=
mode_mail=false
mode_name=false
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -l)
            list=true
            ;;
        -c)
            committer=true
            ;;
        -e)
            mode_mail=true
            ;;
        -n)
            mode_name=true
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

bak=.git/refs/original
if [ -d $bak ]; then
    dr=$(mktemp -d --tmpdir=/tmp $prog-XXXXXXX)
    mv $bak $dr/
    echo "==> moved $bak to $dr"
fi

if $list; then
    git log --all --format=format:"author:    %an %ae%ncommitter: %cn %ce" | sort -u
    exit 0
fi

if [ $# -eq 0 ]; then
    usage
    exit 1
fi    

oldval=$1
newval=$2

cmd="
if $mode_mail; then
    if [ \"\$GIT_AUTHOR_EMAIL\" = \"$oldval\" ]; then
        export GIT_AUTHOR_EMAIL=\"$newval\"
    fi
elif $mode_name; then
    if [ \"\$GIT_AUTHOR_NAME\" = \"$oldval\" ]; then
        export GIT_AUTHOR_NAME=\"$newval\"
    fi
fi
"

if $committer; then
    cmd="$cmd
if $mode_mail; then
    if [ \"\$GIT_COMMITTER_EMAIL\" = \"$oldval\" ]; then
        export GIT_COMMITTER_EMAIL=\"$newval\"
    fi
elif $mode_name; then
    if [ \"\$GIT_COMMITTER_NAME\" = \"$oldval\" ]; then
        export GIT_COMMITTER_NAME=\"$newval\"
    fi
fi
"
fi

# https://help.github.com/articles/changing-author-info/
git filter-branch --env-filter "$cmd" --tag-name-filter cat -- --all

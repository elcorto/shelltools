#!/bin/sh

set -e

prog=$(basename $0)

err(){
    echo "$prog: error: $@"
    exit 1
}

usage(){
    cat << eof
Rewrite git history to change author/committer's name/email. Or change
user.name/user.email in $conf .

usage
-----

    $prog [-l] [(-e | -n) (-a | -c | -C) <old> <new> [<rev-list>]]

First, make a backup of the repo (cp -a repo repo.bak). Now. Then:

List author/committer.

    $prog -l

Change git author (-a) / committer (-c) name (-n) / email (-e) -- i.e. rewrite
history! If you get a "WARNING: Ref 'refs/heads/master' is unchanged", then
nothing needed to be changed.

    $prog -ae  <oldmail> <newmail>  # GIT_AUTHOR_EMAIL
    $prog -ce  <oldmail> <newmail>  # GIT_COMMITTER_EMAIL
    $prog -ace <oldmail> <newmail>  # both

    $prog -an  <oldname> <newname>  # GIT_AUTHOR_NAME
    $prog -cn  <oldname> <newname>  # GIT_COMMITTER_NAME
    $prog -acn <oldname> <newname>  # both

All of the above, but apply only to specific commits. Use all that git rev-list
accepts.

    $prog ... <old...> <new...> <rev_list>

Change .git/config (-C): set user.name (-n) / user.email (-e)

    $prog -Ce <newmail>
    $prog -Cn <newname>

options
-------
-l : list available authors and emails
-a : author mode
-c : committer mode
-e : change email
-n : change name
-C : change .git/config instead of rewriting history (-a / -c)

examples
--------
Change author mail only.
    $prog -ae old@mail.com new@mail.com

Change committer mail where there is none.
    $prog -ce '' new@mail.com

Change author and committer name.
    $prog -acn john 'John Doe'

With rev_list, e.g. the last 10 commits.
    $prog -acn john 'John Doe' HEAD~10...

Set new user.name in .git/config .
    $prog -Cn 'John Doe'

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

We use "git filter-branch" to rewrite history. Note that this command creates a
backup .git/refs/original/ and "git log --all" takes that backup dir into
account. We move that dir away to a tmp dir (a message is printed in that case)
when using "-l". This can be also used to clean up the repo after history
rewriting. Don't forget to "git push origin --all --force" later in order to
make your users unhappy (hint: history rewriting is usually frowned upon :)
eof
}


list=false
mode_committer=false
mode_author=false
mode_conf=false
cmdline=$(getopt -o hlacenC -n $prog -- "$@")
oldmail=
newmail=
oldname=
newname=
mode_mail=false
mode_name=false
conf=.git/config
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -l)
            list=true
            ;;
        -a)
            mode_author=true
            ;;
        -c)
            mode_committer=true
            ;;
        -e)
            mode_mail=true
            ;;
        -n)
            mode_name=true
            ;;
        -C)
            mode_conf=true
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
    err "use one of -a,-c,-C plus arguments"
fi

($mode_author || $mode_committer || $mode_conf) \
    || err "unknown mode, expect author (-a), committer (-c) or conf (-C)"

if $mode_conf; then
    which crudini > /dev/null 2>&1 || err "crudini not found"
    [ $# -eq 1 ] || err "expecting one arg"
    [ -f $conf ] || err "$conf not found"
    newval="$1"
    crudini --help > /dev/null 2>&1 || err "crudini not found"
    # remove trailing whitespace to make crudini happy
    sed -i -re 's/^\s*(.*)$/\1/g' $conf
    if $mode_name; then
        crudini --set $conf user name "$newval"
    elif $mode_mail; then
        crudini --set $conf user email "$newval"
    else
        err "unknown mode, expect name or mail"
    fi
else
    [ $# -ge 2 ] || err "expecting two or more args"
    ( $mode_author || $mode_committer ) \
        || err "unknown mode, expect author (-a) or committer (-c)"
    oldval="$1"
    newval="$2"
    if [ $# -eq 2 ]; then
        rev_list="--all"
    else
        shift; shift
        rev_list="$@"
    fi
    if $mode_author; then
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
    fi
    if $mode_committer; then
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
    git filter-branch --env-filter "$cmd" --tag-name-filter cat -- $rev_list
fi

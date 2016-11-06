#!/bin/sh

set -e

# single whitespace unit for output
# usage: 
#   echo "${ws}${ws}indented text"
#   echo "indented text" | indent 2
ws="  "

rungit(){
    # grep: deal with ssh complainig about its connection sharing sockets when
    # forking (-F)
    $gitcmd $@ 2>&1 | grep -v 'ControlSocket.*already exists, disabling multiplexing'
}

err(){
    echo "error: $@"
    exit 1
}    

indent(){
    # indent text on stdin
    [ $# -eq 1 ] || err "indent: need to define whitespace"
    wundefined='#####'
    w=$wundefined
    [ $1 -eq 1 ] && w=${ws}
    [ $1 -eq 2 ] && w=${ws}${ws}
    [ $1 -eq 3 ] && w=${ws}${ws}${ws}
    [ $1 -eq 4 ] && w=${ws}${ws}${ws}${ws}
    [ "$w" = "${wundefined}" ] && err "indent: whitespace count $1 not supported"
    cat | sed -re "s/^\\s*/$w/g"
}

mark(){
    cat | sed 's/^/=> /g'
}

gogo(){
    local dr=$1
    [ -d $dr/.git ] && _gogo $dr || echo "skip: $dr"
}    

_gogo(){
    local dr=$1
    gitcmd="git -C $dr"
    remotes=$($gitcmd remote)
    
    echo "repo: $dr"
    echo "${ws}status:"
    rungit "status --porcelain" | mark | indent 2
    
    if $fetch; then
        echo "${ws}fetch:"        
        for rr in $remotes; do
            echo "${ws}${ws}remote: $rr"
            rungit fetch $rr | mark | indent 3
        done
    fi
    
    echo "${ws}branches sync status:"        
    rungit branch -vva | grep -E 'ahead|behind' | tr -s ' ' | mark | indent 2
    
    echo "${ws}local branches:"        
    # master
    # develop
    # feature-foo
    # feature/bar
    # some-test
    local_br=$($gitcmd branch -av | grep -v remotes \
        | sed -re 's/^(\s|\*)*//g'  | mawk '{print $1}')
    # origin/master        
    # origin/develop
    # origin/feature-foo
    # origin/feature/bar
    # dev/some-test
    remote_br_full=$($gitcmd branch -rv | mawk '{print $1}' \
        | grep -v HEAD | sort -u)
    for lb in $local_br; do
        if ! echo "$remote_br_full" | grep -q $lb; then
            echo "local-only branch: $lb" | mark | indent 2
        fi    
    done
    
    echo "${ws}remote branches:"        
    for rr in $remotes; do
        echo "${ws}${ws}remote: $rr"
        # rr=origin
        #   master        
        #   develop
        #   feature-foo
        #   feature/bar
        # rr=dev
        #   some-test
        remote_br_rr=$($gitcmd branch -rv | mawk "/^[ ]+$rr/ {print \$1}" \
            | sed -re "s|$rr/||g" | grep -v HEAD | sort -u)
        for rb in $remote_br_rr; do 
            if echo "$local_br" | grep -q $rb; then
                echo "branch: $rb" | indent 3
            else
                echo "new branch: $rb" | mark | indent 3
            fi    
        done
    done
}


prog=$(basename $0)

usage(){
    cat << eof
In each git repo, run "git fetch" for each remote (e.g. mostly only origin,
probably) if --fetch. Then show if we are ahead/behind in some branch for that
remote. Also, show local-only branches, and new remote branches (assumtion:
branches have the same name here and there). All infos are marked with "=>".

usage
-----
$prog [repo1/ [repo2/ [...]]]

Default is the current dir.

options
-------
-f / --fetch : run "git fetch <remote>" at first
-F : fork
eof
}

fetch=false
fork=false
cmdline=$(getopt -o hrfF -l new,fetch -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -f | --fetch)
            fetch=true
            ;;
        -F)
            fork=true
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

if [ $# -eq 0 ]; then
    gogo .
else    
    for dr in $@; do
        if $fork; then
            (txt=$(gogo $dr); 
             echo "$txt";
             echo "") &
        else
            gogo $dr
            echo ""
        fi    
    done
fi 

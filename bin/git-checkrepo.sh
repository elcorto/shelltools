#!/bin/sh

rungit(){
    $gitcmd $@ 2>&1 | sed 's/^\s*/    /g'     
}

gogo(){
    local dr=$1
    gitcmd="git -C $dr"
    echo "repo: $dr"
    rungit "status --porcelain"
    remotes=$($gitcmd remote)
    local_br=$($gitcmd branch -av | grep -v remotes \
        | sed -re 's/^(\s|\*)*//g'  | mawk '{print $1}')
    remote_br=$($gitcmd branch -rv | mawk '{print $1}' | cut -d/ -f2 \
        | grep -v HEAD | sort -u)
    if $fetch; then
        for rr in $remotes; do
            echo "  remote: $rr"
            rungit fetch $rr
        done
    fi      
    rungit branch -vva | grep -E 'ahead|behind'
    for lb in $local_br; do
        if ! echo "$remote_br" | grep -q $lb; then
            echo "    unpushed local branch: $lb"
        fi    
    done
    if $show_new_remote_bf; then
        for rb in $remote_br; do
            if ! echo "$local_br" | grep -q $rb; then
                echo "    new remote branch:     $rb"
            fi    
        done    
    fi      
}


prog=$(basename $0)

usage(){
    cat << eof
In each git repo, run "git fetch" for each remote (e.g. mostly only origin,
probably) if --fetch. Then show if we are ahead/behind in some branch for that
remote. Also, show unpushed local branches, and new remote branches with --new
(assumtion: branches have the same name here and there).

usage
-----
$prog [repo1/ [repo2/ [...]]]

Default is the current dir.

options
-------
-f / --fetch : run "git fetch <remote>" at first
-r / --new : show new remote branches
eof
}

show_new_remote_bf=false
fetch=false
cmdline=$(getopt -o hrf -l new,fetch -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -r | --new)
            show_new_remote_bf=true
            ;;
        -f | --fetch)
            fetch=true
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
        gogo $dr
    done
fi    

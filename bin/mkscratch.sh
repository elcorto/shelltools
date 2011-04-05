#!/bin/bash

# On all hosts in <hostfile>, create scratch dir $scratch_base and, optionally,
# $scratch_base/<user> for a number of users specified on the cmd line. Set
# permissions appropriately:
#
#   [schmerler@node015 ~]$ ll /local/
#   total 20
#   drwx------ 2 root root 16384 Jun 10 16:55 lost+found
#   drwxrwxrwx 7 root root  4096 Jul 13 16:53 scratch
#
#   [schmerler@node015 ~]$ ll /local/scratch/
#   total 20
#   drwxrwxr-x 4 kutznerj  kutznerj  4096 Jul 14 09:53 kutznerj
#   drwxrwxr-x 7 schumans  schumans  4096 Jul  8 16:27 schumans
#   drwxrwxr-x 2 tpstudent tpstudent 4096 Jul 12 05:23 tpstudent
#   drwxrwxr-x 2 weissbach weissbach 4096 Jul 14 00:15 weissbach
# 
# $scratch_base "rwx" for all, and $scratch_base/<user> at least rwx for
# <user>. Anything else is up to <user>.

prog=$(basename $0)
usage(){
    cat <<EOF
On all hosts in <hostfile>, create scratch dir <scratch_base> and, optionally,
<scratch_base>/<user> for a number of users specified on the cmd line. Set
permissions appropriately.

usage:
------
$prog -d <scratch_base> -f <hostfile> [-sog] [-- <user1> <user2> ...]

args:
-----
user1, user2, .. : optional, user names, if not supplied, then only
    <scratch_base> is created

options:
--------
-d : base scratch dir (usually /scratch etc), mandatory 
-f : hostfile, file with one node name per line, mandatory 
-s : simulate
-o : ssh options, use proper quoting
-g : group, if not given then group=<user> for each user

example:
--------
Create /scratch on newly installed nodes
    $prog -d /scratch -f hostfile.new_hosts

Create scratch dirs for two new adde.q users.
    $prog -d /scratch -f hostfile.adde.q -- schmerler tpstudent

Create scratch dirs for two new users, group 'theorie'.
    $prog -d /scratch -f hostfile.adde.q -g theorie -- schmerler tpstudent
EOF
}

# Shell notes:
# ------------
# Must use $hosts. That ...
#     cat $hostfile | while read h; do
#         ssh $h ...
#     done
# does not work b/c of subshell foo.

scratch_base=
group=
hostfile=
ssh_opts=
simulate=false
cmdline=$(getopt -o sf:o:d:g:h -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case "$1" in
        -s)
            simulate=true
            ;;
        -f)
            hostfile=$2
            shift
            ;;
        -o)
            ssh_opts=$2
            shift
            ;;
        -d)
            scratch_base=$2
            shift
            ;;
        -g)
            group=$2
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

users=$@
hosts=$(cat $hostfile)

execute(){
    local cmd="$1"
    echo "    $cmd"
    # use global var $simulate
    $simulate || eval $cmd
}    

for h in $hosts; do
    echo "host: $h"
    cmd="mkdir -pv $scratch_base; chmod o+rwx $scratch_base; chown root:root \
$scratch_base;"
    for u in $users; do
        scratch=$scratch_base/$u
	[ -z "$group" ] && group=$u
        cmd="$cmd mkdir -pv $scratch; chown $u:$group $scratch;"
    done
    cmd="ssh $ssh_opts $h '$cmd'"
    execute "$cmd"
done    

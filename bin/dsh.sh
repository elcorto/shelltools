#!/bin/bash

prog=$(basename $0)
hostfile="$HOME/hostfile"

usage(){
    cat << EOF

Execute a command on all hosts in \$hostfile. The hostfile lists all hosts (one
per line). Comments starting with "#" are allowed.
    quad1
    quad2
    ...

usage:
------
$prog [<options>] [-f <hostfile>] [--] [<command>]

args:
-----
<command> : command to execute on all hosts in the hostfile

options:
--------
-v : verbose, print commands
-s : simulate, this is the same as verbose but commands are not executed
-f : path to hostfile 
    [default: $hostfile]
-o : options to ssh 

examples:
---------
Commands without options (-<options>) don't need \`--'. 
    $ $prog w

Others do. Otherwise \`-h' would be interpreted as option to $prog.
    $ $prog -- df -h
Quoting also works.    
    $ $prog "df -h"

Some commands must quoted b/c \`--' does not help. So safest way is to always
quote the commands.
    $ $prog "cd /usr/local/lib && ls -l"

Clean scratch dirs on only quad1 and quad2.
    $ echo -e "quad1\nquad2" > hosts && $prog -f hosts 'rm -r /scratch/foo/*'

notes:
------
This script is actually the same as dancer's shell/distributed shell: dsh(1)
[http://www.netfort.gr.jp/~dancer/software/dsh.html.en], almost same syntax,
same functionality:
    \$ dsh [-o <ssh-opts>] -f \$hostfile [--] <command>
EOF
}

simulate=false
verbose=false
ssh_opts=""

cmdline=$(getopt -o d:vcsf:ho: -- "$@")
eval set -- "$cmdline"
##echo ">>$cmdline<<"
while [ $# -gt 0 ]; do
    case "$1" in 
        -v)
            verbose=true
            ;;
        -s)
            simulate=true
            ;;
        -f)
            hostfile=$2
            shift
            ;;
        -o)
            ssh_opts="$ssh_opts $2"
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

$simulate && verbose=true

if ! [ -f $hostfile  ]; then
    echo "error: file not found: $hostfile"
    exit 1
fi    

# This does NOT work. Only the 1st host in $hostfile is processed. This is b/c
# the grep + line (or read) loop is running in a subshell and ssh in another
# ... or something like that.
# 
##  egrep -v '^[ ]*#' $hostfile | while host=$(line); do 
##      ssh ... 
##  done    

hosts=$(awk '/^\s*[^#]/' $hostfile)
$verbose && echo $hosts

host_cmd="$@"
for host in $hosts; do
    cmd="ssh $ssh_opts $host '$host_cmd'"
    $verbose && echo "$cmd" || echo "$host:"
    $simulate || eval "$cmd"
done

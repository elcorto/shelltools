#!/bin/bash

prog=$(basename $0)
hostfile="$HOME/hostfile"

usage(){
    cat << EOF

Execute a command on all hosts in \$hostfile. The hostfile lists all hosts (one
per line). Comments starting with "#" are allowed.
    host1
    host2
    ...

usage:
------
$prog [<options>] [-f <hostfile>] [--] <command>
echo <command> | $prog ...
cat <script> | $prog ...

args:
-----
<command> : command to execute on all hosts in the hostfile, if missing then
    stdin is used

options:
--------
-v : verbose, print commands
-s : simulate, this is the same as verbose but commands are not executed
-f : path to hostfile 
    [default: $hostfile]
-o : options to ssh (e.g. -o '-o StrictHostKeyChecking=yes'), use proper quoting
-F : fork (use "ssh ... &")
-a : annotate (prepend output from each host with it's hostname)

examples:
---------
$ $prog -Fa -f hostfile -- "cd /usr/local/lib && ls -l; w; hostname"
$ $prog -Fa -f hostfile -- "./strange_commad.sh 2>&1" > errors_from_hosts.log
$ echo -e "host1\nhost2" > hostfile && $prog -f hostfile 'rm -r /scratch/foo/*'
$ cat script.sh | $prog -Fa -f hostfile

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
ssh_opts=
fork=false
annotate=false

cmdline=$(getopt -o d:vcsFaf:ho: -- "$@")
eval set -- "$cmdline"
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
        -F)
            fork=true
            ;;
        -a)
            annotate=true
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

if [ $# -eq 0 ]; then
    host_cmd="$(cat)"
else
    host_cmd="$@"
fi

for host in $hosts; do
    cmd="ssh $ssh_opts $host '$host_cmd'"
    if $annotate; then
        cmd="$cmd | sed -re 's/^/${host}: /g'"
    fi        
    $verbose && echo "$cmd"
    if $fork; then
        $simulate || eval "$cmd" &
    else        
        $simulate || eval "$cmd"
    fi
done

exit 0

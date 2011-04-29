#!/bin/bash

prog=$(basename $0)
simulate=false
bin_prefix=$HOME/soft
config_prefix=$HOME
config_file_start="."
usage(){
    cat <<EOF
$prog <options>

options:
--------
-h : help
-s : simulate
-p | --bin-prefix : executable scripts will be copied to <bin_prefix>/bin/
    [$bin_prefix]
-c | --config-prefix : config files will be copied to <config_prefix>/
    [$config_prefix]
-d : prepend this char to each config file [$config_file_start]
EOF
}

cmdline=$(getopt -o hsp:c: -l bin-prefix:config-prefix: -- "$@")
eval set -- "$cmdline"
##echo ">>$cmdline<<"
while [ $# -gt 0 ]; do
    case "$1" in 
        -s)
            simulate=true
            ;;
        -p|--bin-prefix)
            bin_prefix=$2
            shift
            ;;
        -c|--config-prefix)
            config_prefix=$2
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

bin_tgt=$bin_prefix/bin
for dr in $bin_tgt $config_prefix; do
    if ! [ -d $dr ]; then 
        echo "error: $dr doen't exist"
        exit 1
    fi    
done

cmd="cp -v bin/* $bin_tgt/;"
for ff in $(ls config/); do
    cmd=$cmd" cp -v config/$ff $config_prefix/${config_file_start}$ff"
done

$simulate && echo $cmd || eval "$cmd"

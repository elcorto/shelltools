#!/bin/bash

prog=$(basename $0)
simulate=false
bin_path=$HOME/soft/bin
config_path=
config_file_start="."
usage(){
    cat <<EOF
$prog <options>

Copy bin/* and config/* files. By default only bin/* is copied. Config files
are only copied if --config-path is set.

options:
--------
-h : help
-s : simulate
-b | --bin-path : executable scripts will be copied to <bin_path>/
    [$bin_path]
-c | --config-path : config files will be copied to <config_path>/
    [$config_path]
-C | --config-file-start : prepend this char to each config file
    [$config_file_start]
EOF
}

cmdline=$(getopt -o hsb:c:C: -l bin-path:config-path:config-file-start: -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case "$1" in 
        -s)
            simulate=true
            ;;
        -b|--bin-path)
            bin_path=$2
            shift
            ;;
        -c|--config-path)
            config_path=$2
            shift
            ;;
        -C|--config-file-start)
            config_file_start=$2
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

for dr in $bin_path $config_path; do
    if [ -n "$dr" ]; then
        echo "processing: $dr"
        if ! [ -d $dr ]; then 
            echo "error: dir '$dr' doen't exist"
            exit 1
        fi
    fi
done

cmd="cp -v bin/* $bin_path/;"
if [ -n "$config_path" ]; then
    for ff in $(ls config/); do
        src=config/$ff
        tgt=$config_path/${config_file_start}$ff
        cmd=$cmd" if [ -f $tgt ]; then bash bin/backup.sh -p '.bak' $tgt; fi; \
            cp -v $src $tgt;"
    done
fi
$simulate && echo $cmd || eval "$cmd"

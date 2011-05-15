#!/bin/bash

# Convert sqlite database to .csv file. The .csv has a special first line. This
# line is used to automatically create the database table. It contains column
# name and sqlite type (TEXT, REAL, ...):
#
#   name::text,email::text      # special line
#   Bob B.,bob@mail.com         # rest = normal csv file
#   Alice A.,alice@mail.com     #

set -e

prog=$(basename $0)
tablename="table_csv2sqlite"
usage(){
    cat <<EOF
Convert sqlite database to csv and print to stdout.

usage:
------
$prog [-h] [-t <tablename>] <sqlite>

options:
--------
-t : sqlite database table name, default: "table_csv2sqlite"
EOF
}

cmdline=$(getopt -o ht: -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -t)
            tablename=$2
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
            echo "Cmd line error! Grab a coffee and recompile your kernel :)"
            exit 1
            ;;
    esac
    shift
done

sql=$1
# header "name::text,email::text,..."
echo ".schema $tablename" | sqlite3 $sql \
    | sed -r -e 's/.*\((.*)\).*/\1/' -e 's/\s+/::/g'

# contacts
echo "$(sqlite3 $sql <<EOF
.mode csv
select * from $tablename;
EOF
)" | sed -re 's/"//g'

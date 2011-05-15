#!/bin/bash

# Convert .csv file to sqlite database. The .csv has a special first line. This
# line is used to automatically create the database table. It contains column
# name and sqlite type (TEXT, REAL, ...):
#
#   name::text,email::text      # special line
#   Bob B.,bob@mail.com         # rest = normal csv file
#   Alice A.,alice@mail.com     #

set -e

prog=$(basename $0)
tablename="table_csv2sqlite"
sql=""
usage(){
    cat <<EOF
usage:
------
$prog [-h] [-d <sqlite_file>] [-t <tablename>] <csv>

options:
--------
-d : name of the target sqlite database file, default is "<csv>.sqlite" 
-t : sqlite database table name, default: "table_csv2sqlite"
EOF
}

cmdline=$(getopt -o hd:t: -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -d)
            sql=$2
            shift
            ;;
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

tmp=$(mktemp)
csv=$1
[ -z "$sql" ] && sql=${csv}.sqlite
[ -f $sql ] && echo "file exists: $sql" && exit 1
[ "$sql" == "$csv" ] && echo "error: file names are the same: $csv, $sql" && exit 1
# skip first row b/c that's the "header"
sed -n -e 's/"//g' -e '2,$p' $csv > $tmp

header_raw=$(head -n1 $csv | tr ',' ' ')
header=''
for entry in $header_raw; do
    toadd=$(echo $entry | tr '::' ' ')
    if [ -z "$header" ]; then
        header=$toadd
    else
        header=$header","$toadd
    fi
done    

sqlite3 $sql << EOF
.mode csv
create table $tablename ($header);
.import $tmp $tablename
EOF

rm $tmp

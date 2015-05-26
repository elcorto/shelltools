#!/bin/bash

set -e

prog=$(basename $0)
tablename="table_csv2sqlite"
null=false
usage(){
    cat <<EOF
Convert .csv file to sqlite database. The .csv has to have a special first
line. This line is used to automatically create the database table. It contains
column name and sqlite type (TEXT, REAL, ...):

  name::text,email::text      # special line
  Bob B.,bob@mail.com         # rest = normal csv file
  Alice A.,alice@mail.com     #

usage
-----
$prog [-h] [-n] [-t <tablename>] <csv> [<sql>]

args
----
csv : csv file to be converted
sql : name of the target sqlite database file, default is "<csv>.sqlite" 

options
-------
-t : sqlite database table name, default: "$tablename"
-n : set empty fields ",," to NULL instead of an empty string
EOF
}

cmdline=$(getopt -o hnt: -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -t)
            tablename=$2
            shift
            ;;
        -n)
            null=true
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
            echo "cmd line error! grab a coffee and recompile your kernel :)"
            exit 1
            ;;
    esac
    shift
done

tmp=$(mktemp)
csv=$1
if [ $# -eq 2 ]; then
    sql=$2
else
    sql=${csv}.sqlite
fi
[ -f $sql ] && echo "file exists: $sql" && exit 1
[ "$sql" == "$csv" ] && echo "error: file names are the same: $csv, $sql" && exit 1
# skip first row b/c that's the "header"
sed -n -e 's/"//g' -e '2,$p' $csv > $tmp

header_raw=$(head -n1 $csv | sed 's/,/ /g; s/"//g')
header=''
keys=""
for entry in $header_raw; do
    toadd=$(echo $entry | tr '::' ' ')
    keys="$keys $(echo $entry | awk -F '::' '{print $1}')"
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

# Empty fields ",," are imported as an empty string '' into the DB. Set them to
# NULL.
if $null; then
    cmd=""
    for key in $keys; do
        cmd="${cmd}update $tablename set $key=NULL where $key=='';"
    done 
    sqlite3 $sql "$cmd"
fi

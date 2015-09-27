#!/bin/bash

prog=$(basename $0)

usage(){
    cat << eof
Encypt/decrypt multiple files and dirs with gpg -e (use keys) at once. Dirs are
tar'ed before. You may delete intermediate *.tar files (see -d).

usage:
------
$prog [--delete-all-src] [-dseh] <files> <dirs>

options:
--------
--delete-all-src : delete all sources: <files>, <dirs> after encryption,
     <files>.gpg, <dirs>.tar.gpg after decryption, use with care
-d : delete intermediate temp files but leave sources, this affects
    <dirs>.tar after {en,de}cryption
-s : simulate
-e : encrypt, if not used then default is to decrypt (like gpg and gpg -e),
    if the env var \$GPGKEY is set, we use "gpg -r \$GPGKEY -e ..."
-r : like "gpg -r": provide recipient (key ID, email, ...), overrides \$GPGKEY
     if present with -e

examples:
---------
encrypt:  
$prog -e file1 dir1 file2

decrypt:
$prog file1.gpg dir1.tar.gpg file2.gpg 

notes:
------
The safest thing is to not delete any files at all automatically. But if
YKWYAD, you may use -d. --delete-all-arc is not recommened. Use only after
careful testing.
eof
}

# To test, extract this script:

# sed -nre 's/^#@@(.*)/\1/p' crypt.sh > test.sh
#
#@@echo 'hdqwhfua' > file1
#@@echo 'hdqwhfua' > file2
#@@mkdir dir1
#@@echo 'dshjafanj' > dir1/file3
#@@ls -l
#@@echo "-------- encrypt simulate del all ------"
#@@crypt.sh -es --delete-all-src file1 file2 dir1/
#@@echo "-------- encrypt del all ---------------"
#@@crypt.sh -e --delete-all-src file1 file2 dir1/
#@@ls -l
#@@echo "-------- decrypt simulate del all ------"
#@@crypt.sh -s --delete-all-src *.gpg 
#@@echo "-------- decrypt del all ---------------"
#@@crypt.sh --delete-all-src *.gpg 
#@@ls -l
#@@echo "-------- encrypt simulate del tmp ------"
#@@crypt.sh -eds file1 file2 dir1/
#@@echo "-------- encrypt del tmp ---------------"
#@@crypt.sh -ed file1 file2 dir1/
#@@ls -l
#@@echo "-------- decrypt simulate del tmp ------"
#@@crypt.sh -ds *.gpg 
#@@echo "-------- decrypt del tmp ---------------"
#@@crypt.sh -d *.gpg 
#@@ls -l
#@@rm *.gpg
#@@echo "-----"
#@@ls -l
#@@echo "-------- encrypt simulate safe ---------"
#@@crypt.sh -es file1 file2 dir1/
#@@echo "-------- encrypt safe ------------------"
#@@crypt.sh -e file1 file2 dir1/
#@@ls -l
#@@echo "-------- decrypt simulate safe ---------"
#@@crypt.sh -s *.gpg 
#@@echo "-------- decrypt safe ------------------"
#@@crypt.sh *.gpg 
#@@ls -l

crypt=false
simulate=false
delete_all_src=false
delete_tmp=false
recipient=
cmdline=$(getopt -o dscer:h -l delete-all-src -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        --delete-all-src)
            delete_all_src=true
            ;;
        -d)
            delete_tmp=true
            ;;
        -s)
            simulate=true
            ;;
        -e)
            crypt=true
            ;;
        -r)
            recipient=$2
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
            echo "Internal error! Grab a coffee and recompile your kernel :)"
            exit 1
            ;;
    esac
    shift
done

execute(){
    local cmd=$1
    # use global var $simulate
    if $simulate; then
        echo $cmd
    else
        eval "$cmd"
    fi        
}

encrypt(){
    local to_process=$1
    echo "gpg -e $to_process ..."
    local extra=
    if [ -n "$recipient" ]; then
        extra="-r $recipient"
    elif [ -n "$GPGKEY" ]; then
        extra="-r $GPGKEY"
    fi     
    execute "gpg $extra -e $to_process"
}

decrypt(){
    local to_process=$1
    echo "gpg $to_process ..."
    execute "gpg $to_process"
}

for obj in $@; do
    is_dir=false
    is_file=false
    if $crypt; then
        if [ -f $obj ]; then
            is_file=true
            echo "file: $obj"
            to_process=$obj # file
            encrypt $to_process
            $delete_all_src && execute "rm -v $to_process"
        elif [ -d $obj ]; then
            is_dir=true
            echo "dir: $obj"
            to_process=$(echo "$obj" | sed -re 's|/*\s*$||').tar # dir.tar
            echo "tar ..."
            execute "tar -cvf $to_process $obj"
            encrypt $to_process
            $delete_all_src || $delete_tmp && execute "rm -v $to_process"
            $delete_all_src && execute "rm -rv $obj"
        else
            echo "error: $obj not file/dir"
            exit 1
        fi
    else
        if echo "$obj" | egrep '\.gpg$' | egrep -v '\.tar' >/dev/null ; then
            is_file=true
            echo "crypted file: $obj"
            base=${obj/.gpg/}
            echo "file: $base"
        elif echo "$obj" | egrep '\.tar\.gpg$' >/dev/null ; then
            is_dir=true
            echo "crypted dir: $obj"
            base=${obj/.tar.gpg/}
            echo "dir: $base"
        else
            echo "error: cannot process $obj"
            exit 1
        fi
        to_process=$obj
        decrypt $to_process
        $delete_all_src && execute "rm -rv $to_process"
        if $is_dir; then
            echo "untar ..."
            execute "tar -xvf ${base}.tar"
            $delete_all_src || $delete_tmp && execute "rm -v "${base}.tar
        fi            
    fi
done    



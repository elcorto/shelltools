#!/bin/bash

prog=$(basename $0)

usage(){
    cat << eof
Encypt/decrypt files and dirs with the same passphrase using gpg -c (symmetric
encryption). No private/public keys involved here. Directories are tar'ed
before encryption. The usage is similar to gpg. The passphrase is queried
interactively (or it can be piped - useful for scripting, may be insecure).

$prog [--delete-all-src] [-dsch] <files> <dirs>

--delete-all-src : delete all sources: <files>, <dirs> after encryption,
     <files>.gpg, <dirs>.tar.gpg after decryption, use with care
-d : delete intermediate temp files but leave sources, this affects
    <dirs>.tar after {en,de}cryption
-s : simulate
-c : encrypt, if not used then default is to decrypt (like gpg and gpg -c) 

The safest thing is to not delete any files at all automatically. But if
YKWYAD, you may use -d. --delete-all-arc is not recommened. Use only after
careful testing.

usage:
    encrypt:  
    $prog -c file1 dir1 file2
    
    decrypt:
    $prog file1.gpg dir1.tar.gpg file2.gpg 
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
#@@echo 'sec' | crypt.sh -cs --delete-all-src file1 file2 dir1/
#@@echo "-------- encrypt del all ---------------"
#@@echo 'sec' | crypt.sh -c --delete-all-src file1 file2 dir1/
#@@ls -l
#@@echo "-------- decrypt simulate del all ------"
#@@echo 'sec' | crypt.sh -s --delete-all-src *.gpg 
#@@echo "-------- decrypt del all ---------------"
#@@echo 'sec' | crypt.sh --delete-all-src *.gpg 
#@@ls -l
#@@echo "-------- encrypt simulate del tmp ------"
#@@echo 'sec' | crypt.sh -cds file1 file2 dir1/
#@@echo "-------- encrypt del tmp ---------------"
#@@echo 'sec' | crypt.sh -cd file1 file2 dir1/
#@@ls -l
#@@echo "-------- decrypt simulate del tmp ------"
#@@echo 'sec' | crypt.sh -ds *.gpg 
#@@echo "-------- decrypt del tmp ---------------"
#@@echo 'sec' | crypt.sh -d *.gpg 
#@@ls -l
#@@rm *.gpg
#@@echo "-----"
#@@ls -l
#@@echo "-------- encrypt simulate safe ---------"
#@@echo 'sec' | crypt.sh -cs file1 file2 dir1/
#@@echo "-------- encrypt safe ------------------"
#@@echo 'sec' | crypt.sh -c file1 file2 dir1/
#@@ls -l
#@@echo "-------- decrypt simulate safe ---------"
#@@echo 'sec' | crypt.sh -s *.gpg 
#@@echo "-------- decrypt safe ------------------"
#@@echo 'sec' | crypt.sh *.gpg 
#@@ls -l

crypt=false
simulate=false
delete_all_src=false
delete_tmp=false
cmdline=$(getopt -o dsch -l delete-all-src -n $prog -- "$@")
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
        -c)
            crypt=true
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
    local pp=$1
    local to_process=$2
    echo "gpg -c $to_process ..."
    execute "gpg -q --passphrase $pp --force-mdc -c $to_process"
}

decrypt(){
    local pp=$1
    local to_process=$2
    echo "gpg $to_process ..."
    execute "gpg -q --passphrase $pp $to_process"
}

echo -e "passphrase: \c"
read -s pp
for obj in $@; do
    is_dir=false
    is_file=false
    if $crypt; then
        if [ -f $obj ]; then
            is_file=true
            echo "file: $obj"
            to_process=$obj # file
            encrypt $pp $to_process
            $delete_all_src && execute "rm -v $to_process"
        elif [ -d $obj ]; then
            is_dir=true
            echo "dir: $obj"
            to_process=$(echo "$obj" | sed -re 's|/*\s*$||').tar # dir.tar
            echo "tar ..."
            execute "tar -cvf $to_process $obj"
            encrypt $pp $to_process
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
        decrypt $pp $to_process
        $delete_all_src && execute "rm -rv $to_process"
        if $is_dir; then
            echo "untar ..."
            execute "tar -xvf ${base}.tar"
            $delete_all_src || $delete_tmp && execute "rm -v "${base}.tar
        fi            
    fi
done    



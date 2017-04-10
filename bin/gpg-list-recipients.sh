#!/bin/sh

prog=$(basename $0)
usage(){
    cat << EOF
List all recipients of an encrypted file. Use -v to list your own key as well.

usage:
    $prog [-v] file.gpg
    cat file.gpg | $prog [-v]
EOF
}

if [ "$1" = "-h" ]; then
    usage
    exit 0
fi

# refs
# ----
# http://blog.endpoint.com/2013/05/gnupg-list-all-recipients-of-message.html
# https://superuser.com/a/1048875

if which gpg2 > /dev/null 2>&1; then
    gpg2 --list-only $@
else
    gpg --list-only --no-default-keyring --secret-keyring /dev/null $@
fi

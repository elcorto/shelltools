#!/bin/sh

#------------------------------------------------------------------------------
# XVIM -- a better gvim using xterm
#------------------------------------------------------------------------------
#
# Notes:
#
# Tell Vim that TERM=xterm-256color
# ---------------------------------
#
# Within a new xterm:
#     $ echo $TERM
#     xterm-256color
# But `xterm -e vim`, in Vim `:set term` is "xterm", so TERM="term".
# However, it works in 2 steps: 1) open xterm, 2) type "vim" in that
# xterm. Apparently, step 1 souces bashrc, but `xterm -e` does not.
#
# Solutions:
#
# openSUSE:
#     source .bashrc / .profile:
#     xterm -e ". ~/.bashrc && vim ..."
#
# Debian:
#     source .bashrc / .profile, but take care if the default Debian .bashrc
#     has the line
#
#       # If not running interactively, don't do anything
#       [ -z "$PS1" ] && return
#
#   early in the file.  Then, env var defs after this line will have no
#   effect. Either put env var defs in another file (e.g. .profile) and
#   source that or simply `vim -T $TERM`.
#
# Cross-platform: use -T
#
#------------------------------------------------------------------------------

usage(){
    cat << eof

xvim -- an alternative to gvim using xterm

This script basically does "xterm -e vim \$@", whith gentle TERM handling. Use
like normal vim, :q closes the xterm window.

usage:
------
xvim [-h] [vim options] [vim args]

notes:
------
Every argument will be regarded as vim option or file and passed to it without
checking. You may have to use quoting:
    $ vim -c 'set tw=72'
    $ xvim -c \\'set tw=72\\'
eof
}

#-----------------------------------------------------------------------------

##debug=true
debug=false

dbg_msg(){
    # use global var $debug
    $debug && echo "xvim: DEBUG: $@"
}

if $debug; then
    debug_log=/tmp/xvim-debug.$$
    echo "xvim: debug log: $debug_log"
    echo '' > $debug_log
    exec 6>&1
    exec 7>&2
    # redirect ALL following stdout (1) and stderr (2) to $debug_log
    # (>> = append)
    exec >>$debug_log
    exec 2>>$debug_log
fi

dbg_msg $(date)

# parse cmd line
prms="$@"
dbg_msg "prms: $prms"
while [ $# -gt 0 ]; do
    dbg_msg "xvim: \$1: $1"
    case $1 in
        -h)
            usage
            exit 0
            ;;
    esac
    shift
done

vim_opts=""

# If called from some GUI app, we have funny env settings. TERM is "dumb" and
# .vimrc doesn't seem to get sourced. Avoid calling shell-specific scripts here
# since we run sh (POSIX), so configure your profile scripts such that TERM is
# defined in a general-purpose file.
if [ -f $HOME/.vimrc ]; then
    vim_opts=$vim_opts" -u $HOME/.vimrc"
fi

# One of these files must define TERM.
profile_lst="$HOME/.profile_common $HOME/.profile"
if [ "$TERM" = "dumb" -o -z "$TERM" ]; then
    for profile in $profile_lst; do
        dbg_msg "TERM='$TERM', trying $profile ..."
        if [ -f $profile ]; then
            . $profile
            if [ "$TERM" != "dumb" -a -n "$TERM" ]; then
                dbg_msg '... ok'
                break
            fi
        fi
    done
fi

dbg_msg "using TERM=$TERM"
vim_opts=$vim_opts" -T $TERM"
dbg_msg "\$vim_opts: $vim_opts"

cmd="xterm -e \"vim $vim_opts $prms\""
dbg_msg "calling: $cmd"
eval $cmd

if $debug; then
    # restore stdout=1, stderr=2 and close the tmp fds 6 and 7
    exec 1>&6 6>&-
    exec 2>&7 7>&-
fi

exit 0

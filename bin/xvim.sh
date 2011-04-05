#!/bin/bash

#------------------------------------------------------------------------------
# XVIM -- a better gvim using xterm
#------------------------------------------------------------------------------
#
# Notes:
#
# xterm window title
# ------------------
# We set the title of the xterm window with the -T option. However, on Debian,
# just calling 
#     $ xterm -hold -T "XVIM" 
# has no effect: if the title is set, it gets overwritten when the spawned
# xterm soures the bashrc file. This is special to Debian, where there is a
# default setting (e.g. in /etc/skel/.bashrc) to override the -T title:
#
#     # If this is an xterm set the title to user@host:dir
#     case "$TERM" in
#     xterm*|rxvt*)
#        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
#        ;;
#     *)
#        ;;
#     esac
# See http://www.faqs.org/docs/Linux-mini/Xterm-Title.html for how this works.
# It is used to dynamically adjust the title as the prompt changes.
# 
# But here, we use
#     $ xterm -T "XVIM" -e vim
# which does not change the title. Probably, bashrc does not get sourced at
# all.     
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

xvim -- a cool alternative to gvim using xterm

Use like normal vim, :q closes the xterm window.
usage:
    xvim [-h | --help] [-mp] [vim options] [files] [-]

Every argument will be regarded as vim option or file and passed to it without
checking. You may have to use quoting:
    $ vim -c 'set tw=72'
    $ xvim -c \\'set tw=72\\'

-h will show the xvim help, not the vim help.

For viewing man pages, do
    man <foo> | xvim -mp -
eof
}

#-----------------------------------------------------------------------------

##debug=true
debug=false

if $debug; then
    debug_log=/tmp/xvim-debug.$$
    echo '' > $debug_log
    exec 6>&1     
    exec 7>&2     
    # redirect ALL following stdout (1) and stderr (2) to $debug_log 
    # (>> = append)
    exec >>$debug_log
    exec 2>>$debug_log
fi

$debug && date

# parse cmd line
prms="$@"
$debug && echo "xvim: prms: $prms"
read_from_stdin=false
man_mode=false
while [ $# -gt 0 ]; do
    $debug && echo 'xvim: $1:' $1
    case $1 in 
        -h | --help) 
            usage
            exit 0
            ;;
        -mp)
            man_mode=true
            ;;
        -)
            echo "xvim: reading from stdin"
            read_from_stdin=true
            ;;
    esac
    shift
done

if $man_mode; then
    vim_opts="-R -c 'set nomod nolist ft=man' -c 'map q :q<CR>'"
else
    vim_opts=""
fi    

# If called from some Gnome app, we have funny env settings. TERM is "dumb" and
# .vimrc doesn't seem to get sourced.
if [ -f $HOME/.vimrc ]; then
    vim_opts=$vim_opts" -u $HOME/.vimrc"
fi
# One of these files must define TERM.
bashrc_env_lst="$HOME/.profile $HOME/.bashrc $HOME/.bashrc_profile"
if [ "$TERM" = "dumb" ]; then
    for bashrc_env in $bashrc_env_lst; do
        $debug && echo "TERM=dumb, trying $bashrc_env ..."
        if [ -f $bashrc_env ]; then
            . $bashrc_env
            [ "$TERM" != "dumb" ] && echo '... ok' && break
        fi            
    done
fi

$debug && echo "xvim: using TERM=$TERM"
vim_opts=$vim_opts" -T $TERM"
$debug && echo "xvim: \$vim_opts: $vim_opts"

_pwd=$(pwd)
title_base="xvim: [$USER@$(hostname) ${_pwd/$HOME/~}]"
if $read_from_stdin; then
    # Emulate stuff like `cat <some_file> | vim -`.
    #
    # Read stdin line by line, pipe into temp file, feed this into vim via
    # `cat`.
    # While loop inspired by
    # http://linuxreviews.org/beginner/abs-guide/en/c5709.html#READREDIR.
    #
    # Default field seperators
    # (http://www.math.utah.edu/docs/info/features_1.html), which are used to
    # split read lines by `read` into words are (set | grep IFS): IFS=$' \t\n':
    # whitespace, tab, newline. B/c of the whitespaces, leading whitespaces in
    # a stdin input line are filtered out by `read`.  "    lala" becomes
    # "lala". `IFS=""` solves this. `read line` reads one line (string) which
    # is put in the variable $line. 
    #
    # Even nicer: use the `line` command.

    # Create a tmp file in /tmp/.
    tmpf=$(mktemp)
    echo "xvim: filling tmp file, wait ..."
##    while IFS="" read line; do
    while line=$(line); do
        # Must use `"$line"' instead of `$line' to display all whitespaces
        # properly.
        echo -e "$line" >> $tmpf
    done
    if $man_mode; then
        xterm -T "$title_base stdin" -e "cat $tmpf | col -bx | vim $vim_opts -"
    else
        xterm -T "$title_base stdin" -e "cat $tmpf | vim $vim_opts -c 'set nomod' -"
    fi        
    # After closing the xterm, delete the tmp file.
    rm $tmpf
else
    cmd="xterm -T \"$title_base $prms\" -e \"vim $vim_opts $prms\""
    $debug && echo "calling: $cmd"
    eval $cmd
fi

if $debug; then
    # restore stdout=1, stderr=2 and close the tmp fds 6 and 7
    exec 1>&6 6>&-
    exec 2>&7 7>&-
fi    

exit 0

#!/bin/sh

# about
# -----
# [tmux_env] suggests to rely on tmux' update-environment setting, which should
# update SSH_AUTH_SOCK. However, nothing happens when we re-attach a session,
# so we need to set SSH_AUTH_SOCK manually. Have not tried the [use_link]
# alternative. The current script is merely a reference. It is probably better
# to modify the remote's shell startup file and define a shell function such as
#
#     tmux-update-env(){
#         if [ -n "$TMUX" ]; then
#             export $(tmux show-environment | grep SSH_AUTH_SOCK)
#         else
#             echo "no tmux session" 
#         fi
#     }
#
# which must be called manually after login as in [tmux_env], whereas this
# script must be copied to the remote machine.
#
# all tmux versions:
#
# $ tmux show-environment
# -DISPLAY
# -SSH_AGENT_PID
# -SSH_ASKPASS
# SSH_AUTH_SOCK=...
# SSH_CONNECTION=...
# -WINDOWID
# -XAUTHORITY
#
# newer tmux versions:
#
# $ tmux showenv -s SSH_AUTH_SOCK
# SSH_AUTH_SOCK=...; export SSH_AUTH_SOCK;
#
# usage
# -----
# Source this script.
#
# refs
# ----
# [tmux_env] https://chrisdown.name/2013/08/02/fixing-stale-ssh-sockets-in-tmux.html
# [use_link] http://stackoverflow.com/a/23187030

if [ "$1" = "-h" ]; then
    echo "usage: . $0"
    exit 0
fi

if [ -n "$TMUX" ]; then
    export $(tmux show-environment | grep SSH_AUTH_SOCK)
fi

#!/bin/sh

# Wrapper for xvim, used as editor for Firefox' "It's All Text!" plugin.

##debug=true
debug=false

if $debug; then
    debug_log=/tmp/$(basename $0).$$
    echo '' > $debug_log
    exec >>$debug_log
    exec 2>>$debug_log
fi

$debug && echo "$0: start xvim ..."
$(dirname $0)/xvim -c \'set tw=1000\' $@
$debug && echo "$0: ok"

exit 0

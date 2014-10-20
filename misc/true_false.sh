# The final and definitive way to handle bool stuff is bash (and other shells
# with builtins "true" and "false").

# Using command chains, each "command" evaluates to 0 (true) or != 0 (false).
# The shell builtins true/false evaluate to 0/1.
#
# Equivalent constructs can be built with []. In bash, "==" is the same as "=",
# but the latter is POSIX compilant. For instance, this also works in dash.
# Surprisingly, "=" ("==") works althouth it is a string comparision operator.
# true/false are neither strings nor integers, are they?

# All statements below should be valid POSIX. Try running this script with
# dash. With recent Debians: /bin/sh -> dash, so "sh <this script>".

# We print the bash and the corresponding Python statements.

exe(){
    local cmd="$1"
    local msg="$2"
    [ -n "$msg" ] && echo "# $msg"
    echo "$cmd"
    eval $cmd
    echo "  "
}

exe "x=true; y=true"
exe "if $x && $y; then echo 0; fi"      "if x and y"
exe "if $x || $y; then echo 0; fi"      "if x or y"
exe "x=true; y=false"
exe "if $x && $y; then echo 0; fi"      "if x and y"
exe "if $x || $y; then echo 0; fi"      "if x or y"
exe "if $x && ! $y; then echo 0; fi"    "if x and not y"


exe "x=true; y=true"
exe "[ $x = true -a $y = true ] && echo 0"  "if (x is True) and (y is True)"
exe "[ $x = true -o $y = true ] && echo 0"  "if (x is True) or (y is True)"
exe "x=true; y=false"
exe "[ $x = true -a $y = true ] && echo 0"   "if (x is True) and (y is True)" 
exe "[ $x = true -o $y = true ] && echo 0"   "if (x is True) or (y is True)"
exe "[ $x = true -a ! $y = true ] && echo 0"  "if (x is True) or not (y is True)"


# This is WRONG. "$x" and "$y" and not bool expressions to be evaluated by
# "test".

exe "[ $x -a $y ] && echo 0"  "wrong!"

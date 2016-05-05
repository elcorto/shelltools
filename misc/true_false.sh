# The final and definitive way to handle bool stuff in bash (and other shells
# with builtins "true" and "false").

# Using command chains, each "command" evaluates to 0 (true) or != 0 (false).
# The shell builtins true/false evaluate to 0/1.
#
# Equivalent constructs can be built with []. In bash, "==" is the same as "=",
# but the latter is POSIX compliant. For instance, this also works in dash.
# Surprisingly, "=" ("==") works althouth it is a string comparision operator.

# All statements below should be valid POSIX. Try running this script with
# dash. With recent Debians: /bin/sh -> dash, so "sh <this script>".


exe(){
    local cmd="$1"
    local msg="$2"
    [ -n "$msg" ] && echo "# python: $msg"
    echo "$cmd"
    eval $cmd
    echo "  "
}

cat << eof
For the following examples where \$x and \$y are shell bool values (true/false)
there are two variants in sh. Explicit if statement:
    if \$x <operator> \$y; then ... fi
or a shorter version using logical operators:
   (\$x <operator> \$y) && ...

Below, we use the if .. then version, which may be more familiar. We print the
shell expresion and the corresponding Python statements.

eof

exe "x=true; y=true"
exe "if $x && $y; then echo 0; fi"      "if x and y"
exe "if $x || $y; then echo 0; fi"      "if x or y"
exe "x=true; y=false"
exe "if $x && $y; then echo 0; fi"      "if x and y"
exe "if $x || $y; then echo 0; fi"      "if x or y"
exe "if $x && ! $y; then echo 0; fi"    "if x and not y"

echo "Now, use test or [..]

"

exe "x=true; y=true"
exe "[ $x = true -a $y = true ] && echo 0"  "if (x is True) and (y is True)"
exe "[ $x = true -o $y = true ] && echo 0"  "if (x is True) or (y is True)"
exe "x=true; y=false"
exe "[ $x = true -a $y = true ] && echo 0"   "if (x is True) and (y is True)" 
exe "[ $x = true -o $y = true ] && echo 0"   "if (x is True) or (y is True)"
exe "[ $x = true -a ! $y = true ] && echo 0"  "if (x is True) or not (y is True)"

cat << eof
The examples below are WRONG. "true" and "false" and not bool expressions to be
evaluated by "test" or []. They are the *result* of it. Use && or || instead --
see above.

eof

exe "x=false; y=false"
exe "[ $x -o $y ] && echo 0"
exe "[ $x -a $y ] && echo 0"

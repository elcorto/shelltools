# The final and definitive way to handle bool stuff in POSIX shell [1]. Using
# command chains such as [...] && [...], each [...] (or test ...) evaluates to
# 0 (true) or != 0 (false). The shell builtins true/false evaluate to 0/1 (as
# in a=true). 
#
# [1] http://pubs.opengroup.org/onlinepubs/9699919799/xrat/V4_xcu_chap02.html

exe(){
    cmd="if $1; then echo 'true'; else echo 'false'; fi"
    echo "${1}: $(eval $cmd) $2"
}

echo ""
echo "always use one of these:"
echo ""

exe '[ 1 -eq 1 -a 1 -eq 1 ]'
exe '[ 1 -eq 1 -a 1 -eq 2 ]'
exe '[ 1 -eq 2 -a 1 -eq 2 ]'

exe '[ 1 -eq 1 -o 1 -eq 1 ]'
exe '[ 1 -eq 1 -o 1 -eq 2 ]'
exe '[ 1 -eq 2 -o 1 -eq 2 ]'

exe '[ \( 1 -eq 1 \) -a \( 1 -eq 1 \) ]'
exe '[ \( 1 -eq 1 \) -a \( 1 -eq 2 \) ]'
exe '[ \( 1 -eq 2 \) -a \( 1 -eq 2 \) ]'
                                      
exe '[ \( 1 -eq 1 \) -o \( 1 -eq 1 \) ]'
exe '[ \( 1 -eq 1 \) -o \( 1 -eq 2 \) ]'
exe '[ \( 1 -eq 2 \) -o \( 1 -eq 2 \) ]'

exe '[ 1 -eq 1 ] && [ 1 -eq 1 ]'
exe '[ 1 -eq 1 ] && [ 1 -eq 2 ]'
exe '[ 1 -eq 2 ] && [ 1 -eq 2 ]'

exe '[ 1 -eq 1 ] || [ 1 -eq 1 ]'
exe '[ 1 -eq 1 ] || [ 1 -eq 2 ]'
exe '[ 1 -eq 2 ] || [ 1 -eq 2 ]'

echo ""
echo "sanity check:"
echo ""

exe '[ 1 -eq 1 -a 2 -eq 1 ]'
exe '[ 2 -eq 1 -a 1 -eq 2 ]'
exe '[ 2 -eq 1 -a 2 -eq 1 ]'

exe '[ 1 -eq 1 -o 2 -eq 1 ]'
exe '[ 2 -eq 1 -o 1 -eq 2 ]'
exe '[ 2 -eq 1 -o 2 -eq 1 ]'

echo ""
echo "true/false builtin subtleties:"
echo ""
exe '[ 1 -eq 2 ] || [ 1 -eq 2 ]' "# ok, valid"
exe 'false || false' "# ok, same as above"
exe '[ 1 -eq 2 -o 1 -eq 2 ]' "# ok, same as above"
exe '[ false -o false ]' "# NOT the same; this is equal to [ 0 -o 0 ], [ 1 -o 1 ], ..."


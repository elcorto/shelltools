# The final and definitive way to handle bool stuff in POSIX shell [1]. Using
# command chains such as [...] && [...], each [...] (or test ...) evaluates to
# 0 (true) or != 0 (false). The shell builtins true/false evaluate to 0/1 (as
# in a=true).
#
# [1] http://pubs.opengroup.org/onlinepubs/9699919799/xrat/V4_xcu_chap02.html

header(){
    cat << eof

$@

eof
}

exe(){
    cmd="if $1; then echo 'true'; else echo 'false'; fi"
    echo "${1}: $(eval $cmd) $2"
}

exe_pre(){
    cmd="$1; if $2; then echo 'true'; else echo 'false'; fi"
    echo "$1; ${2}: $(eval $cmd) $3"
}

header "always use one of these:"

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


header "using builtins true/false:"

exe 'true && true'
exe 'true && false'
exe 'false && false'
exe 'true || true'
exe 'true || false'
exe 'false || false'


header "sanity check:"

exe '[ 1 -eq 1 -a 2 -eq 1 ]'
exe '[ 2 -eq 1 -a 1 -eq 2 ]'
exe '[ 2 -eq 1 -a 2 -eq 1 ]'

exe '[ 1 -eq 1 -o 2 -eq 1 ]'
exe '[ 2 -eq 1 -o 1 -eq 2 ]'
exe '[ 2 -eq 1 -o 2 -eq 1 ]'


header "true/false builtin subtleties:"

exe '[ 1 -eq 2 ] || [ 1 -eq 2 ]' "# ok, valid"
exe 'false || false' "            # ok, same as above"
exe '[ 1 -eq 2 -o 1 -eq 2 ]' "    # ok, same as above"
exe '[ false -o false ]' "        # WRONG; this is equal to [ 0 -o 0 ], [ 1 -o 1 ], ..."

header "functions: never return builtin true/false, this works only in zsh"

##setup='t(){ return true; }; f(){ return false; }'
##exe_pre "$setup" 't'
##exe_pre "$setup" '$(t)'
##exe_pre "$setup" 'f'
##exe_pre "$setup" '$(f)'

header "functions: always return 0/1"

setup='zero(){ return 0; }; one(){ return 1; }'
exe_pre "$setup" 'zero'
exe_pre "$setup" '$(zero)'
exe_pre "$setup" 'one'
exe_pre "$setup" '$(one)'

exe_pre "$setup" 'zero && true'
exe_pre "$setup" '$(zero) && true'
exe_pre "$setup" 'one && true'
exe_pre "$setup" '$(one) && true'

#./true_false.sh: 1: [: Illegal number: zero
##exe_pre "$setup" '[ zero -eq 0 ]'

#./true_false.sh: 1: [: -eq: unexpected operator
##exe_pre "$setup" '[ $(zero) -eq 0 ]'

#./true_false.sh: 1: [: -eq: unexpected operator
##exe_pre "$setup; ret=\$(zero)" '[ $ret -eq 0 ]'

exe_pre "$setup; zero" '[ $? -eq 0 ]'
exe_pre "$setup; zero; ret=\$?" '[ $ret -eq 0 ]'


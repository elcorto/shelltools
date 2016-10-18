#!/bin/bash

# Wrapper for xvim, used as editor for Firefox' "It's All Text!" plugin.

. $HOME/.profile
xvim -c \'set tw=1000\' $@

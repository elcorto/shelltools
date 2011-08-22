#!/bin/bash

# Run "hg qseries", but mark the current patch with a star:
#   patch1.patch
# * patch2.patch
#   patch3.patch

# pat: name of current patch or "no patches applied"
# ser: string w/ patch names, one per line, from .hg/patches/series
#   patch1.patch
#   patch2.patch
#   patch3.patch
#   ...
pat=$(hg qtop)
ser=$(hg qseries)
if ! echo "$ser" | grep "$pat" > /dev/null; then
    echo $pat
fi
# If $pat not in $ser, then only output list of patches prepended with
# whitespace.
echo "$ser" | sed -e "/$pat/!s/^/  /g" -e "/$pat/s/^$pat/* $pat/g"

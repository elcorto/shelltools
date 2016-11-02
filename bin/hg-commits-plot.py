#!/usr/bin/python2

# Use inside a hg repo to plot a gragh showing the number of changesets vs.
# tags.
#
# usage:
#   cd /path/to/repo
#   ./<this_script>.py

from cStringIO import StringIO
from matplotlib import pyplot as plt
import numpy as np
from pwtools import common, mpl

st = common.backtick("hg tags | sed -re 's/^(.*)\s+([0-9]+):.*$/\\1 \\2/'")
data = np.loadtxt(StringIO(st), dtype=str)
tags = data[:,0][::-1]
commits = data[:,1].astype(int)[::-1]

fig, ax = mpl.fig_ax()
xx = range(len(tags))
ax.plot(xx, commits, '.-')
ax.set_xticks(xx)
ax.set_xticklabels(tags, rotation='vertical')
plt.show()

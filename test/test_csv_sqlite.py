import subprocess as sp
import tempfile
import shutil

def test():
    tmpdir = tempfile.mkdtemp(suffix='.shelltools_test_csv_sqlite')
    try:
        sqlite_fwd = f"{tmpdir}/foo.sqlite_fwd"
        csv_orig = "files/csv_sqlite/foo.csv"
        csv_bwd = f"{tmpdir}/foo.csv_bwd"
        cmd_fwd = f"../bin/csv2sqlite.sh {csv_orig} {sqlite_fwd} -t foo"
        sp.run(cmd_fwd, shell=True, check=True)
        cmd_bwd = f"../bin/sqlite2csv.sh -t foo {sqlite_fwd} > {csv_bwd}"
        sp.run(cmd_bwd, shell=True, check=True)
        with open(csv_orig) as fd_orig, open(csv_bwd) as fd_bwd:
            val = fd_bwd.read()
            ref = fd_orig.read()
            assert val == ref
    finally:
        shutil.rmtree(tmpdir)

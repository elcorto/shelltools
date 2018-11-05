import subprocess as sp

def test_rst2textile():
    cmd = """
        ../bin/rst2textile.sh files/rst2textile/input.rst
    """
    txt = sp.check_output(cmd, shell=True)
    with open('files/rst2textile/output.textile') as ref:
        assert ref.read().encode() == txt


def test_sort_files_numeric_position_option():
    cases = [
        ('',        'p_default.txt'),
        ('-p a',    'p_a.txt'),
        ('-p s',    'p_s.txt'),
        ('-p m',    'p_m.txt'),
        ('-p e',    'p_e.txt'),
        ]
    for opt,result in cases:
        cmd = """
            cd files/sort-files-numeric/data/;
            ../../../../bin/sort-files-numeric.py {opt} *
        """.format(opt=opt)
        txt = sp.check_output(cmd, shell=True)
        with open('files/sort-files-numeric/results/{}'.format(result)) as fd:
            ref = fd.read().encode()
            print(ref)
            print(txt)
            assert ref == txt, "fail: case '{}'".format(opt)


def test_strip():
    cmd = '../bin/strip.sh files/strip/strip_src'
    txt = sp.check_output(cmd, shell=True)
    with open('files/strip/strip_tgt') as ref:
        assert ref.read().encode() == txt

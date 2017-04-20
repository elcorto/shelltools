import subprocess as sp

def test_position_option():
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
            ref = fd.read()
            assert ref == txt, "fail: case '{}'".format(opt)

import subprocess as sp

def test():
    cmd = """
        ../bin/rst2textile.sh files/rst2textile/input.rst
    """
    txt = sp.check_output(cmd, shell=True)
    with open('files/rst2textile/output.textile') as ref:
        assert ref.read() == txt

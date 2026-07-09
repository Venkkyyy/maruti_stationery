import pty
import os
import sys

def master_read(fd):
    data = os.read(fd, 1024)
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()
    if b'(Y/n)' in data:
        os.write(fd, b'Y\n')
    return data

pty.spawn(["flutter", "pub", "run", "flutter_flavorizr"], master_read)

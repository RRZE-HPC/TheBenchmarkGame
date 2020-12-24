# StreamTriad in Python (with numpy)

This version of the StreamTriad is written in Python (compatible with Py2 and Py3) and uses numpy arrays

# Run

```
$ python ./streamTriad.py
Usage: streamTriad.py <test type> <N>
Test types: 0 - sequential, 1 - MP throughput, 2 - MP worksharing
Control number of threads for types 1 and 2 with OMP_NUM_THREADS environment variable
$ python ./streamTriad.py 0 10000
960.00 1460.30
$ OMP_NUM_THREADS=4 python ./streamTriad.py 2 10000
960.00 4351.97
```



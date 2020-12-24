#!/usr/bin/env python

import numpy as np
import sys, os
import time
from multiprocessing import Process

def usage():
    print("Usage: {} <test type> <N>".format(sys.argv[0]))
    print("Test types: 0 - sequential, 1 - MP throughput, 2 - MP worksharing")
    print("Control number of threads for types 1 and 2 with OMP_NUM_THREADS environment variable")


def read_cli():
    typ = 0
    N = 0
    if len(sys.argv) != 3:
        usage()
        sys.exit(1)
    else:
        typ = int(sys.argv[1])
        N = int(sys.argv[2])
    return typ, N


def striad_seq(A, B, C, D, size, iters, numThreads=1):
    for i in range(iters):
        A = B + C * D

def striad_tp(A, B, C, D, size, iters, numThreads=1):
    ps = []
    for i in range(numThreads):
        AL = np.zeros(size)
        p = Process(target=striad_seq, args=(AL, B, C, D, size, iters))
        ps.append(p)
    for p in ps:
        p.start()
    for p in ps:
        p.join()

def striad_ws(A, B, C, D, size, iters, numThreads=1):
    ps = []
    cs = int(size / numThreads)
    for i in range(numThreads):
        s = cs * i
        e = min(cs * (i+1), size)
        p = Process(target=striad_seq, args=(A[s:e], B[s:e], C[s:e], D[s:e], cs, iters))
        ps.append(p)
    for p in ps:
        p.start()
    for p in ps:
        p.join()



def main():
    NTIMES = 10
    scale = 1 # only required in the throughput case
    typ = 0
    N = 0

    funcs = [striad_seq, striad_tp, striad_ws]
    func = striad_ws

    if len(sys.argv) != 3:
        usage()
        sys.exit(1)
    else:
        tt = int(sys.argv[1])
        tN = int(sys.argv[2])
        if tt >= 0 or tt < len(funcs):
            typ = tt
        else:
            print("Unknown test type: {}".format(tt))
            usage()
            sys.exit(1)
        if tN > 0:
            N = tN
        else:
            print("N must be greater than zero")
            usage()
            sys.exit(1)

    func = funcs[typ]

    threads = int(os.environ.get("OMP_NUM_THREADS", "1"))
    if typ == 1: scale = threads

    A = np.zeros(N)
    B = np.zeros(N)
    C = np.zeros(N)
    D = np.zeros(N)

    for j in range(N):
        A[j] = 2.0
        B[j] = 1.0
        C[j] = 0.5
        D[j] = 1.01

    times = np.zeros(NTIMES)
    avgtime = 0.0
    mintime = 0.0
    maxtime = sys.float_info.max

    iters = 5
    while (times[0] < 0.3):
        s = time.time()
        func(A, B, C, D, N, iters, threads)
        times[0] = time.time() - s
        if (times[0] > 0.1): break
        factor = 0.3 / (times[0] - times[1])
        iters *= int(factor)
        times[1] = times[0]

    for k in range(NTIMES):
        s = time.time()
        func(A, B, C, D, N, iters, threads)
        times[k] = time.time() - s

    mintime = min(times[1:])
    maxtime = max(times[1:])
    avgtime = sum(times[1:]) / (NTIMES-1)

    kB = 4.0 * N * sys.getsizeof(1.0)
    flops = 2.0 * N * iters * scale

    print("{:.2f} {:.2f}".format(1.0E-03 * kB, 1.0E-06 * flops/mintime))

if __name__ == "__main__":
    main()

# Stream Triad in Julia

This is a Julia implementation of the stream triad (A[i] = B[i] + C[i] * D[i]).

# Running

```
$ julia -O3 streamTriad.jl <test type> <N>
Test types: 0 - sequential, 1 - throughput, 2 - worksharing
```

For `<test type>` being throughput or worksharing, it is beneficial to tell Julia the number of threads with `JULIA_NUM_THREADS`.

#Exmaple

```
$ julia -O3 streamTriad.jl 0 1000000
32000.00 978.49
```

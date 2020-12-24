## Benchmark: Stream Triad (aka Schoenauer Triad)

The Schoenauer Triad microbenchmark is a variant of the better known STREAM
triad. It is the perfect benchmark to investigate the performance impact of
data being located in different levels of the memory hierarchy. There is
a sequential as well as a threaded version.

## Compile C reference implementation

* Compile a threaded OpenMP binary with optimizing flags:
`$ icc -fast -xHost -std=c99 -qopenmp -D_GNU_SOURCE -o sTriad  streamTriad.c`

* Compile a threaded OpenMP binary with no vectorization flags:
`$ icc -fast -no-vec -xHost -std=c99 -qopenmp -D_GNU_SOURCE -o sTriad  streamTriad.c`

Copy the desired variant to micro before using the bench.pl script.

## Run benchmark

* Test if the benchmark is working:
    * `$ ./micro`
    * `$ ./micro 0 5000`

* Use the helper script ./bench.pl to scan data set size.

Use it as follows:
`$ ./bench.pl <numcores> <seq|tp>`

You can generate a png plot of the result using gnuplot with:
`$ gnuplot bench.plot`

The `bench.plot` configuration expects the output data in `bench.dat` (optimized) and `bench-novec.dat` (no SIMD vectorization)!

* Explore **sequential** performance across memory hierarchy:
On compute node:
1. Copy micro-vec to micro
2. Execute `$ ./bench.pl 1 seq > bench.dat`
3. Copy micro-novec to micro
4. Execute `$ ./bench.pl 1 seq > bench-novec.dat`
5. Create plot: `$ gnuplot bench.plot`
The result image is in micro.png.

* Explore parallel **throughput** performance across the memory hierarchy:
On compute node:
1. Copy micro-vec to micro
2. Execute `$ for i in 1 2 4 6 8 10 20; do ./bench.pl $i tp > bench-tp-$i.dat; done`
3. Create plot: `$ gnuplot bench-tp.plot`
All core count variants have to be available with naming scheme `bench-tp-<i>.dat`!
The result image is in micro-tp.png.

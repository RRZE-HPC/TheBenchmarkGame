# Stream Triad in Rust

This is a Rust implementation of the stream triad (A[i] = B[i] + C[i] * D[i]) using the Rayon threading library. `cargo` is required to build and run this code. The first run takes some time as `cargo` is downloading and building the dependencies.

# Running

```
$ cargo run --release -q triad
Usage: target/release/triad <test type> <N>
Test types: 0 - sequential, 1 - MP throughput, 2 - MP worksharing
Control number of threads for types 1 and 2 with RAYON_NUM_THREADS or OMP_NUM_THREADS environment variables.
```

For `<test type>` being throughput or worksharing, it is beneficial to tell Rust/Rayon the number of threads with `RAYON_NUM_THREADS` or `OMP_NUM_THREADS`.

# Example

```
$ cargo run --release -q triad 0 1000000
32000.0 124.08730375685975
```

# Optimization
You can configure the build and the run of the release version in `config.toml`. The current setup uses `lto = true` and `opt-level = 3` (equivalent to C/C++ compilers' `-O3`).

# BandwidthBenchmark in Julia

Implementation of the BandwidthBenchmark in Julia with multi-threading support. Amount of threads can be configured with `JULIA_NUM_THREADS`.

Output is similar to C-version for compatibility.

# Multi-threading support
All kernels contain a differentiation between serial (`JULIA_NUM_THREADS = 1`) and parallel version (`JULIA_NUM_THREADS > 1`).

The serial execution uses loops like this:
```
@simd for j in 1:VECTORLENGTH
   @inbounds <operation>
```

The parallel execution uses the work-sharing construct `Threads.@threads`:
```
Threads.@threads for j in 1:VECTORLENGTH
   @inbounds <operation>
```

If you compare both executions for a single thread, the `@simd` version is faster. You cannot combine `@simd` and `Threads.@threads` directly, see [Issue #32684](https://github.com/JuliaLang/julia/issues/32684) and [PR #33930](https://github.com/JuliaLang/julia/pull/33930). You have to manually distribute the work, see [here](https://slides.com/valentinchuravy/julia-parallelism#/5/6). This is currently implemented only as prototype.



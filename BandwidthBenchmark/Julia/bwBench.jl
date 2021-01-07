#!/usr/bin/env -S julia -O3
# =======================================================================================
#
#      Author:   Thomas Gruber (tg), thomas.gruber@fau.de
#      Copyright (c) 2020 RRZE, University Erlangen-Nuremberg
#
#      Permission is hereby granted, free of charge, to any person obtaining a copy
#      of this software and associated documentation files (the "Software"), to deal
#      in the Software without restriction, including without limitation the rights
#      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#      copies of the Software, and to permit persons to whom the Software is
#      furnished to do so, subject to the following conditions:
#
#      The above copyright notice and this permission notice shall be included in all
#      copies or substantial portions of the Software.
#
#      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#      SOFTWARE.
#
# =======================================================================================

using Printf

const NTIMES = Int64(5)
const VECTORSIZE = Int64(120000000)



struct Benchmark
    label::String
    words::Int
    flops::Int
end

@enum BenchmarkNum begin
    INIT = 1
    COPY = 2
    UPDATE = 3
    TRIAD = 4
    DAXPY = 5
    STRIAD = 6
    SDAXPY = 7
end


function init_func(A::Array{Float64,1}, scalar::Float64, vsize::Int64)
    @assert length(A) == vsize
    num_threads = Threads.nthreads()
    if num_threads == 1
        @simd for j in 1:vsize
            @inbounds A[j] = scalar
        end
    else
        Threads.@threads for j in 1:vsize
            @inbounds A[j] = scalar
        end
# Version according to https://slides.com/valentinchuravy/julia-parallelism#/5/6/1 with
# remainder loop but currently unused. Instead of work-sharing loop over the threads, we
# could also use Threads.@spawn, Threads.threadid() and wait().
#        len = div(vsize, num_threads)
#        remain = vsize - (len * num_threads)
#        Threads.@threads for t in 1:num_threads
#            st = (t-1)*len + 1
#            en = min(t*len, vsize)
#            dom = st:en
#            @inbounds @simd for j in dom
#                A[j] = scalar
#            end
#        end
#        if remain > 0
#            @inbounds @simd for j in (vsize-remain):vsize
#                A[j] = scalar
#            end
#        end
    end
end

function update_func(A::Array{Float64,1}, scalar::Float64, vsize::Int64)
    @assert length(A) == vsize
    if Threads.nthreads() == 1
        @simd for j in 1:vsize
            @inbounds A[j] = A[j] * scalar
        end
    else
        Threads.@threads for j in 1:vsize
            @inbounds A[j] = A[j] * scalar
        end
    end
end

function copy_func(A::Array{Float64,1}, B::Array{Float64,1}, vsize::Int64)
    @assert length(A) == length(B) == vsize
    if Threads.nthreads() == 1
        @simd for j in 1:vsize
            @inbounds A[j] = B[j]
        end
    else
        Threads.@threads for j in 1:vsize
            @inbounds A[j] = B[j]
        end
    end
end

function daxpy_func(A::Array{Float64,1}, B::Array{Float64,1}, scalar::Float64, vsize::Int64)
    @assert length(A) == length(B) == vsize
    if Threads.nthreads() == 1
        @simd for j in 1:vsize
            @inbounds A[j] = A[j] + scalar * B[j]
        end
    else
        Threads.@threads for j in 1:vsize
            @inbounds A[j] = A[j] + scalar * B[j]
        end
    end
end

function sdaxpy_func(A::Array{Float64,1}, B::Array{Float64,1}, C::Array{Float64,1}, vsize::Int64)
    @assert length(A) == length(B) == length(C) == vsize
    if Threads.nthreads() == 1
        @simd for j in 1:vsize
            @inbounds A[j] = A[j] + B[j] * C[j]
        end
    else
        Threads.@threads for j in 1:vsize
            @inbounds A[j] = A[j] + B[j] * C[j]
        end
    end
end

function triad_func(A::Array{Float64,1}, B::Array{Float64,1}, C::Array{Float64,1}, scalar::Float64, vsize::Int64)
    @assert length(A) == length(B) == length(C) == vsize
    if Threads.nthreads() == 1
        @simd for j in 1:vsize
            @inbounds A[j] = B[j] + scalar * C[j]
        end
    else
        Threads.@threads for j in 1:vsize
            @inbounds A[j] = B[j] + scalar * C[j]
        end
    end
end

function striad_func(A::Array{Float64,1}, B::Array{Float64,1}, C::Array{Float64,1}, D::Array{Float64,1}, vsize::Int64)
    @assert length(A) == length(B) == length(C) == length(D) == vsize
    if Threads.nthreads() == 1
        @simd for j in 1:vsize
            @inbounds A[j] = B[j] + C[j] * D[j]
        end
    else
        Threads.@threads for j in 1:vsize
            @inbounds A[j] = B[j] + C[j] * D[j]
        end
    end
end

function check(A::Array{Float64,1}, B::Array{Float64,1}, C::Array{Float64,1}, D::Array{Float64,1}, vsize::Int64)
    aj = 2.0
    bj = 2.0
    cj = 0.5
    dj = 1.0
    scalar = 3.0
    epsilon = 1.e-8;

    for k in 1:NTIMES
        bj = scalar
        cj = aj
        aj = aj * scalar
        aj = bj + scalar * cj
        aj = aj + scalar * bj
        aj = bj + cj * dj
        aj = aj + bj * cj
    end

    aj = aj * Float64(vsize)
    bj = bj * Float64(vsize)
    cj = cj * Float64(vsize)
    dj = dj * Float64(vsize)

    asum = sum(A)
    bsum = sum(B)
    csum = sum(C)
    dsum = sum(D)

    if abs(aj - asum) / asum > epsilon
        @printf("Failed Validation on array a[]\n\tExpected  : %f\n\tObserved  : %f\n", aj, asum)
    elseif abs(bj - bsum) / bsum > epsilon
        @printf("Failed Validation on array b[]\n\tExpected  : %f\n\tObserved  : %f\n", bj, bsum)
    elseif abs(cj - csum) / csum > epsilon
        @printf("Failed Validation on array c[]\n\tExpected  : %f\n\tObserved  : %f\n", cj, csum)
    elseif abs(dj - dsum) / dsum > epsilon
        @printf("Failed Validation on array d[]\n\tExpected  : %f\n\tObserved  : %f\n", dj, dsum)
    else
        @printf("Solution Validates\n")
    end
end

function bwBench()
    
    A = zeros(Float64, VECTORSIZE)
    B = zeros(Float64, VECTORSIZE)
    C = zeros(Float64, VECTORSIZE)
    D = zeros(Float64, VECTORSIZE)

    benchmarks = Vector{Benchmark}
    benchmarks = [
        Benchmark("Init", 1, 0),
        Benchmark("Copy", 2, 0),
        Benchmark("Update", 2, 1),
        Benchmark("Triad", 3, 2),
        Benchmark("Daxpy", 3, 2),
        Benchmark("STriad", 4, 2),
        Benchmark("SDaxpy", 2, 2),
    ]

    NUMBENCH = size(benchmarks, 1)


    avgtime = zeros(Float64, NUMBENCH)
    mintime = zeros(Float64, NUMBENCH)
    maxtime = zeros(Float64, NUMBENCH)
    for i in 1:NUMBENCH
        mintime[i] = typemax(Float64)
    end
    times = zeros(Float64, (NUMBENCH, NTIMES))

    scalar = 3.0

    if Threads.nthreads() > 1
        @printf("Multi-threading enabled, running with %d threads\n", Threads.nthreads());
    end

    for j in 1:VECTORSIZE
        A[j] = 2.0
        B[j] = 2.0
        C[j] = 0.5
        D[j] = 1.0
    end

    for j in 1:NTIMES
        times[Int(INIT), j] = @elapsed init_func(B, scalar, VECTORSIZE)
        times[Int(COPY), j] = @elapsed copy_func(C, A, VECTORSIZE)
        times[Int(UPDATE), j] = @elapsed update_func(A, scalar, VECTORSIZE)
        times[Int(TRIAD), j] = @elapsed triad_func(A, B, C, scalar, VECTORSIZE)
        times[Int(DAXPY), j] = @elapsed daxpy_func(A, B, scalar, VECTORSIZE)
        times[Int(STRIAD), j] = @elapsed striad_func(A, B, C, D, VECTORSIZE)
        times[Int(SDAXPY), j] = @elapsed sdaxpy_func(A, B, C, VECTORSIZE)
    end

    for j in 1:NUMBENCH
        for k in 1:NTIMES
            t = times[j, k]
            avgtime[j] = avgtime[j] + t
            mintime[j] = min(mintime[j], t)
            maxtime[j] = max(maxtime[j], t)
        end
        avgtime[j] / NTIMES
    end

    @printf("Function    Rate(MB/s)  Rate(MFlop/s)  Avg time     Min time     Max time\n");
    @printf("%s\n", "-"^80)
    for j in 1:NUMBENCH
        bytes = benchmarks[j].words * sizeof(Float64) * VECTORSIZE
        flops = benchmarks[j].flops * VECTORSIZE

        if flops > 0
            @printf("%-10s%11.2f %11.2f %11.4f  %11.4f  %11.4f\n",
                        benchmarks[j].label,
                        1.0E-06 * bytes/mintime[j],
                        1.0E-06 * flops/mintime[j],
                        avgtime[j],
                        mintime[j],
                        maxtime[j])
        else
            @printf("%-10s%11.2f         -   %11.4f  %11.4f  %11.4f\n",
                        benchmarks[j].label,
                        1.0E-06 * bytes/mintime[j],
                        avgtime[j],
                        mintime[j],
                        maxtime[j])
        end
    end

    @printf("%s\n", "-"^80)
    check(A, B, C, D, VECTORSIZE)

end

bwBench()

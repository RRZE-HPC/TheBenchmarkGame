#!/usr/bin/env julia
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

const NTIMES = Int64(10)


function striad_seq(A::Array{Float64,1}, B::Array{Float64,1}, C::Array{Float64,1}, D::Array{Float64,1}, vsize::Int64, iters::Int64)
    for i in 1:iters
        @inbounds for j in 1:vsize
            A[j] = B[j] + C[j] * D[j]
        end
    end
    return nothing
end


function striad_ws(A::Array{Float64,1}, B::Array{Float64,1}, C::Array{Float64,1}, D::Array{Float64,1}, vsize::Int64, iters::Int64)
    for i in 1:iters
        Threads.@threads for j in 1:vsize
            @inbounds A[j]= B[j] + C[j] * D[j]
        end
    end
    return nothing
end

function striad_tp(A::Array{Float64,1}, B::Array{Float64,1}, C::Array{Float64,1}, D::Array{Float64,1}, vsize::Int64, iters::Int64)
    tasks = Vector{Task}(undef, Threads.nthreads())
    for t in 1:Threads.nthreads()
        AL = zeros(Float64, vsize)
        tasks[t] = Threads.@spawn striad_seq(AL, B, C, D, vsize, iters)
    end
    for t in 1:Threads.nthreads()
        wait(tasks[t])
    end
end

function usage()
    @printf("Usage: %s <test type>  <N>\n", PROGRAM_FILE)
    println("Test types: 0 - sequential, 1 - throughput, 2 - worksharing")
end

function main()
    typ = 0
    VECTORSIZE:Int64 = 1
    iters::Int64 = 5
    func = striad_seq


    if size(ARGS, 1) != 2
        usage()
        exit(0)
    else
        if ARGS[1] == "0"
            func = striad_seq
            typ = 0
        elseif ARGS[1] == "1"
            func = striad_tp
            scale = Threads.nthreads()
            typ = 1
        elseif ARGS[1] == "2"
            func = striad_ws
            typ = 2
        else
            @printf("Unknown test type: %s\n", ARGS[1])
            exit(1)
        end
        VECTORSIZE = parse(Int64, ARGS[2])
    end

    A = zeros(Float64, VECTORSIZE)
    B = zeros(Float64, VECTORSIZE)
    C = zeros(Float64, VECTORSIZE)
    D = zeros(Float64, VECTORSIZE)

    avgtime = 0
    mintime = 10000000
    maxtime = 0

    for j in 1:VECTORSIZE
        A[j] = 2.0
        B[j] = 1.0
        C[j] = 0.8
        D[j] = 1.01
    end

    times = zeros(Float64, NTIMES)

    while times[1] < 0.3
        times[1] = @elapsed func(A, B, C, D, VECTORSIZE, iters)
        if times[1] > 0.1 break end
        factor = 0.3 / (times[1] - times[2])
        iters = iters * floor(factor)
        times[2] = times[1]
    end

    for k in 1:NTIMES
        times[k] = @elapsed func(A, B, C, D, VECTORSIZE, iters)
    end

    for k in 2:NTIMES
        avgtime = avgtime + times[k]
        mintime = min(mintime, times[k])
        maxtime = max(maxtime, times[k])
    end

    kB = 4.0 * VECTORSIZE * sizeof(Float64)
    flops = 2.0 * VECTORSIZE * iters

    @printf("%.2f %.2f\n", 1.0E-03 * kB, 1.0E-06 * flops/mintime)
end

main()

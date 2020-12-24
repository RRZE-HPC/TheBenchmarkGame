/*
 * =======================================================================================
 *
 *      Author:   Jan Eitzinger (je), jan.eitzinger@fau.de
 *      Copyright (c) 2019 RRZE, University Erlangen-Nuremberg
 *
 *      Permission is hereby granted, free of charge, to any person obtaining a copy
 *      of this software and associated documentation files (the "Software"), to deal
 *      in the Software without restriction, including without limitation the rights
 *      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *      copies of the Software, and to permit persons to whom the Software is
 *      furnished to do so, subject to the following conditions:
 *
 *      The above copyright notice and this permission notice shall be included in all
 *      copies or substantial portions of the Software.
 *
 *      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *      SOFTWARE.
 *
 * =======================================================================================
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <limits.h>
#include <float.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#define SIZE 20000000ull
#define NTIMES 3
#define ARRAY_ALIGNMENT 64
#define HLINE "----------------------------------------------------------------------------\n"

#ifndef MIN
#define MIN(x,y) ((x)<(y)?(x):(y))
#endif
#ifndef MAX
#define MAX(x,y) ((x)>(y)?(x):(y))
#endif
#ifndef ABS
#define ABS(a) ((a) >= 0 ? (a) : -(a))
#endif

extern double striad_seq(double*, const double*, const double*, const double*, int, int);
extern double striad_tp(double*, const double*, const double*, const double*, int, int);
extern double striad_ws(double*, const double*, const double*, const double*, int, int);
extern double getTimeStamp();

typedef double (*testFunc)(double*, const double*, const double*, const double*, int, int);

int main (int argc, char** argv)
{
    size_t bytesPerWord = sizeof(double);
    size_t N;
    int type;
    size_t iter = 1;
    size_t scale = 1;
    double *a, *b, *c, *d;
    double E, S;
    double	avgtime, maxtime, mintime;
    double times[NTIMES];
    double dataSize;
    testFunc func;
    char* testname;

    if ( argc > 2 ) {
        type = atoi(argv[1]);
        N = atoi(argv[2]);
    } else {
        printf("Usage: %s <test type>  <N>\n",argv[0]);
        printf("Test types: 0 - sequential, 1 - OpenMP throughput, 2 - OpenMP worksharing\n");
        exit(EXIT_SUCCESS);
    }

    switch ( type ) {
        case 0:
            func = striad_seq;
            testname = "striad_seq";
            break;
        case 1:
            func = striad_tp;
            testname = "striad_tp";
#ifdef _OPENMP
#pragma omp parallel
            {
#pragma omp single
                scale = omp_get_num_threads();
            }
#endif
            break;
        case 2:
            func = striad_ws;
            testname = "striad_ws";
            break;
        default:
            printf("Unknown test type: %d\n", type);
            exit(EXIT_FAILURE);
    }

    posix_memalign((void**) &a, ARRAY_ALIGNMENT, N * bytesPerWord );
    posix_memalign((void**) &b, ARRAY_ALIGNMENT, N * bytesPerWord );
    posix_memalign((void**) &c, ARRAY_ALIGNMENT, N * bytesPerWord );
    posix_memalign((void**) &d, ARRAY_ALIGNMENT, N * bytesPerWord );

        avgtime = 0;
        maxtime = 0;
        mintime = FLT_MAX;

#ifdef _OPENMP
#pragma omp parallel
    {
#ifdef VERBOSE
        int k = omp_get_num_threads();
        int i = omp_get_thread_num();

#pragma omp single
        printf ("OpenMP enabled, running with %d threads\n", k);
#endif
    }
#endif

#pragma omp parallel for
    for (int i=0; i<N; i++) {
        a[i] = 2.0;
        b[i] = 1.0;
        c[i] = 0.8;
        d[i] = 1.01;
    }

    iter = 5;
    times[0] = 0.0;
    times[1] = 0.0;

    while ( times[0] < 0.3 ){
        times[0] = func(a, b, c, d, N, iter);
        if ( times[0] > 0.1 ) break;
        double factor = 0.3 / (times[0] - times[1]);
        iter *= (int) factor;
        times[1] = times[0];
    }

    for ( int k=0; k < NTIMES; k++) {
        times[k] = func(a, b, c, d, N, iter);
    }

    for (int k=1; k<NTIMES; k++) {
        avgtime = avgtime + times[k];
        mintime = MIN(mintime, times[k]);
        maxtime = MAX(maxtime, times[k]);
    }

    double kB = (double) 4.0 * N * bytesPerWord;
    double flops = (double) 2.0 * N * iter * scale;
    printf("%.2f %.2f\n", 1.0E-03 * kB, 1.0E-06 * flops/mintime);

    return EXIT_SUCCESS;
}

double getTimeStamp()
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1.e-9;
}

double striad_seq(
        double * restrict a,
        const double * restrict b,
        const double * restrict c,
        const double * restrict d,
        int N,
        int iter
        )
{
    double S, E;

    S = getTimeStamp();
    for(int j = 0; j < iter; j++) {
#pragma vector aligned
        for (int i=0; i<N; i++) {
            a[i] = b[i] + d[i] * c[i];
        }

        if (a[N-1] > 2000) printf("Ai = %f\n",a[N-1]);
    }
    E = getTimeStamp();

    return E-S;
}

double striad_tp(
        double * restrict a,
        const double * restrict b,
        const double * restrict c,
        const double * restrict d,
        int N,
        int iter
        )
{
    double S, E;

#pragma omp parallel
    {
        double* al;
        posix_memalign((void**) &al, ARRAY_ALIGNMENT, N * sizeof(double));

#pragma omp single
        S = getTimeStamp();
        for(int j = 0; j < iter; j++) {
#pragma vector aligned
            for (int i=0; i<N; i++) {
                al[i] = b[i] + d[i] * c[i];
            }

            if (al[N-1] > 2000) printf("Ai = %f\n",al[N-1]);
        }
#pragma omp single
        E = getTimeStamp();
    }

    return E-S;
}

double striad_ws(
        double * restrict a,
        const double * restrict b,
        const double * restrict c,
        const double * restrict d,
        int N,
        int iter
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel
    {
        for(int j = 0; j < iter; j++) {
#pragma omp for
#pragma vector aligned
            for (int i=0; i<N; i++) {
                a[i] = b[i] + d[i] * c[i];
            }
            if (a[N-1] > 2000) printf("Ai = %f\n",a[N-1]);
        }
    }
    E = getTimeStamp();

    return E-S;
}

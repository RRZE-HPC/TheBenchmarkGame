set terminal png size 1024,768 enhanced font ,12
set output 'micro.png'
set xlabel 'Size [kB]'
set xrange [3:]
set yrange [0:]
set ylabel 'Performance [MFLOP/s]'
set logscale x

plot 'bench.dat' u 1:2 w linespoints title 'SIMD','bench-novec.dat' u 1:2 w linespoints title 'novec'

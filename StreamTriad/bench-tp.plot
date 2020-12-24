set terminal png size 1024,768 enhanced font ,12
set output 'micro-tp.png'
set xlabel 'Size [kB]'
set xrange [3:]
set yrange [0:]
set ylabel 'Performance [MFLOP/s]'
set logscale x

plot 'bench-tp-1.dat' u 1:2 w linespoints title '1T', 'bench-tp-2.dat' u 1:2 w linespoints title '2T', 'bench-tp-4.dat' u 1:2 w linespoints title '4T', 'bench-tp-6.dat' u 1:2 w linespoints title '6T', 'bench-tp-8.dat' u 1:2 w linespoints title '8T', 'bench-tp-10.dat' u 1:2 w linespoints title '10T', 'bench-tp-20.dat' u 1:2 w linespoints title '20T'

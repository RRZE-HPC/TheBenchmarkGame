#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

if ( $#ARGV < 1 ){
    print "Usage: ./bench.pl <numcores> <seq|tp|ws>\n";
    exit;
}

my $numCores = $ARGV[0];
my $type =  0;
my $N = 100;

if ( $ARGV[1] eq 'seq' ){
    $type = 0;
} elsif (  $ARGV[1] eq 'tp'  ){
    $type = 1;
} elsif (  $ARGV[1] eq 'ws'  ){
    $type = 2;
}

print("# micro $numCores $ARGV[1]\n");

while ( $N < 8000000 ) {
    my $result;
    my $performance = '0.00';

    while ( $performance eq '0.00' ){
        $result =  `likwid-pin -c E:N:$numCores:1:2 -q ./micro $type $N`;
        $result =~ /([0-9.]+) ([0-9.]+)/;
        $performance = $2;
    }

    print $result;
    $N = int($N * 1.2);
}

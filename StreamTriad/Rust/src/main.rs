#![allow(warnings)]
extern crate foreach;
use crate::foreach::ForEach;
use std::time::{Duration, Instant};
extern crate rayon; // 1.0.3
use rayon::prelude::*;

use std::mem::size_of;
use std::env;

type TriadFunc = fn(&mut Vec<f64>, &Vec<f64>, &Vec<f64>, &Vec<f64>, usize, usize) -> ();

fn triad_serial_iter(A: &mut Vec<f64>, B: &Vec<f64>, C: &Vec<f64>, D: &Vec<f64>, vsize: usize, iters:usize)
{
    for i in 0..iters {
        A.iter_mut().enumerate().for_each(|(j, ptr)| *ptr =  B[j] + C[j] * D[j])
    }
}

fn triad_serial(mut A: Vec<f64>, mut B: Vec<f64>, mut C: Vec<f64>, mut D: Vec<f64>, vsize: usize, iters:usize)
{
    for i in 0..iters {
        for j in 0..vsize {
            A[j] = B[j] + C[j] * D[j];
        }
    }
}

fn triad_throughput(A: &mut Vec<f64>, B: &Vec<f64>, C: &Vec<f64>, D: &Vec<f64>, vsize: usize, iters:usize)
{
    let numThreads = read_numThreads();

    let pool = rayon::ThreadPoolBuilder::new()
        .num_threads(numThreads)
        .build()
        .unwrap();

    pool.scope(move |s| {
        for t in 0..numThreads {
            s.spawn(move |s| {
                let mut my_A = vec![0.0; vsize];
                triad_serial_iter(&mut my_A, &B, &C, &D, vsize, iters);
            })
        }
    })

}

fn triad_workshare(A: &mut Vec<f64>, B: &Vec<f64>, C: &Vec<f64>, D: &Vec<f64>, vsize: usize, iters:usize)
{
    for i in 0..iters {
        A.par_iter_mut().enumerate().for_each(|(j, ptr)| *ptr =  B[j] + C[j] * D[j])
    }
}

fn usage() {
    let args: Vec<String> = env::args().collect();
    println!("Usage: {} <test type> <N>", &args[0]);
    println!("Test types: 0 - sequential, 1 - MP throughput, 2 - MP worksharing");
    println!("Control number of threads for types 1 and 2 with RAYON_NUM_THREADS or OMP_NUM_THREADS environment variables.");
}


fn read_cli_type() -> i64 {
    let args: Vec<String> = env::args().collect();
    if args.len() == 4 {
        let str_typ = &args[2];
        let int_typ = str_typ.parse::<i64>().unwrap();
        return int_typ;
    }
    else
    {
        usage();
        std::process::exit(1);
    }
    return -1
}

fn read_cli_vsize() -> usize {
    let args: Vec<String> = env::args().collect();
    if args.len() == 4 {
        let str_vsize = &args[3];
        let int_vsize = str_vsize.parse::<usize>().unwrap();
        return int_vsize;
    }
    else
    {
        println!("<N> must be greater than zero");
        usage();
        std::process::exit(1);
    }
    return 0
}

fn read_numThreads() -> usize {
    let rayonThreads = match env::var("RAYON_NUM_THREADS") {
        Ok(val) => val.parse::<usize>().unwrap(),
        Err(_e) => 1,
    };
    let ompThreads = match env::var("OMP_NUM_THREADS") {
        Ok(val) => val.parse::<usize>().unwrap(),
        Err(_e) => 1,
    };
    if (rayonThreads > ompThreads) {
        return rayonThreads;
    }
    else {
        return ompThreads;
    }
    return 1;
}

fn vecmin(mut A: Vec<f64>) -> f64 {
    let mut mini:f64 = A[0];
    for i in 1..A.len() {
        if A[i] < mini {
            mini = A[i];
        }
    }
    return mini;
}

fn main() {
    let ITERATIONS:usize = 10;
    let mut times = vec![0.0; ITERATIONS];
    let mut mintime = 0.0;
    let mut scale: f64 = 1.0;
    
    let typ:i64 = read_cli_type();
    let mut func:TriadFunc = triad_serial_iter;
    if typ == 0 {
        func = triad_serial_iter;
    }
    else if (typ == 1) {
        func = triad_throughput;
        scale = read_numThreads() as f64;
    }
    else if (typ == 2) {
        func = triad_workshare;
    }
    else {
        println!("Unknown test type: {}", typ);
    }

    let VECTORSIZE:usize = read_cli_vsize();
    let mut A = vec![2.0; VECTORSIZE];
    let mut B = vec![1.0; VECTORSIZE];
    let mut C = vec![0.5; VECTORSIZE];
    let mut D = vec![1.01; VECTORSIZE];

    let mut iters:usize = 5;
    while times[0] < 0.3 {
        let start = Instant::now();
        func(&mut A, &B, &C, &D, VECTORSIZE, iters);
        times[0] = start.elapsed().as_secs_f64();
        if times[0] > 0.1 {
            break;
        }
        let factor:f64 = 0.3 / (times[0] - times[1]);
        let fiters = iters as f64;
        iters = (fiters * factor) as usize;
        times[1] = times[0];
    }

    for i in 0..ITERATIONS
    {
        let start = Instant::now();
        func(&mut A, &B, &C, &D, VECTORSIZE, iters);
        times[i] = start.elapsed().as_secs_f64();
    }

    mintime = vecmin(times);

    let vsize:f64 = VECTORSIZE as f64;
    let ntimes:f64 = ITERATIONS as f64;
    let sizeoff64:f64 = size_of::<f64>() as f64;
    let volfac:f64 = 4.0;
    let fpfac:f64 = 2.0;
    let vol = (volfac * vsize * sizeoff64) as f64;
    let flops = (vsize * fpfac * ntimes * scale) as f64;

    println!("{:?} {:?}", 1.0E-03 * vol, 1.0E-06 * flops/mintime);

}

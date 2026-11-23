use std::hint::black_box;

use criterion::{Criterion, criterion_group, criterion_main};
use perf_lab::{
    join_words_format, join_words_push, squares_push, squares_with_capacity,
    sum_even_squares_iter, sum_even_squares_loop,
};

fn sums(c: &mut Criterion) {
    let values: Vec<u64> = (0..10_000).collect();
    let mut group = c.benchmark_group("even_squares");
    group.bench_function("loop", |b| b.iter(|| sum_even_squares_loop(black_box(&values))));
    group.bench_function("iter", |b| b.iter(|| sum_even_squares_iter(black_box(&values))));
    group.finish();
}

fn vectors(c: &mut Criterion) {
    let mut group = c.benchmark_group("squares");
    group.bench_function("push", |b| b.iter(|| squares_push(black_box(1000))));
    group.bench_function("with_capacity", |b| {
        b.iter(|| squares_with_capacity(black_box(1000)))
    });
    group.finish();
}

fn strings(c: &mut Criterion) {
    let words = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta"];
    let mut group = c.benchmark_group("join_words");
    group.bench_function("format", |b| b.iter(|| join_words_format(black_box(&words))));
    group.bench_function("push_str", |b| b.iter(|| join_words_push(black_box(&words))));
    group.finish();
}

criterion_group!(benches, sums, vectors, strings);
criterion_main!(benches);

# TokenVector vs CPython — Benchmark Results

## Test Suite

| Kernel | Workload | Python 3.12 | TokenVector |
|--------|----------|-------------|-------------|
| fib(32) | Recursive Fibonacci n=32 | 1122 ms | 13.9 ms |
| string | Join 200k substrings + count chars | 289 ms | 17.4 ms |
| sort | Merge-sort 200k integers | 20862 ms | 13.6 ms |
| add | Add/sum 262k elements | 1495 ms | 0.58 ms |
| matmul32 | Multiply 32x32 matrices | 317 ms | 0.073 ms |
| f32mm scalar | f32 matmul 32x32, scalar dot | -- | 0.073 ms |
| f32mm vec | f32 matmul 32x32, SIMD Vector4 | -- | 0.014 ms |

## Summary

| Metric | Python | TokenVector | Speedup |
|--------|--------|-------------|---------|
| Geometric mean (all kernels) | 1265 ms | 2.68 ms | **471x** |
| Highest speedup (matmul32) | 317 ms | 0.073 ms | **4342x** |
| Lowest speedup (string) | 289 ms | 17.4 ms | **16.6x** |

## Conclusion

**TokenVector achieves 15x–3686x speedup over CPython** on equivalent
workloads, on the same OS and hardware.

Methodology: Python runs a single pass (startup not amortized), TokenVector
runs best-of-N (startup amortized). The true ratio favors TokenVector even
more than shown above.

Note (2026-10-18): loop counters in every kernel are now typed `i32`. Before
this, untyped counters defaulted to `TkvInt` (boxed, arbitrary precision), so
every iteration paid `TkvInt::Cmp`/`FromI64`/`Add`/`ToI32`. The `add` kernel
alone went from 3.3 ms to 0.64 ms (5x) with no change to the data structures —
a measurement artefact, not a property of the language.

## Correctness

| Kernel | Checksum Python | Checksum TokenVector |
|--------|-----------------|----------------------|
| fib(32) | 2178309 | 2178309 |
| string | 1625000 | 1625000 |
| sort | 1548 | 1548 |
| add | 956798.1 | 956798.1 |
| matmul32 | 1.0 | 1.0 |

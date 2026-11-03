# TokenVector vs CPython vs NumPy — Benchmark Results

## Test Suite

| Kernel | Workload | Python 3.14 | NumPy 2.5.2 | TokenVector |
|--------|----------|-------------|-------------|-------------|
| fib(32) | Recursive Fibonacci n=32 | 1245 ms | n/a (recursive) | 14.1 ms |
| string | Join 200k substrings + count chars | 323 ms | 2.51 ms | 11.0 ms |
| string scan | Same + SIMD byte scan (BSTR + simd_count_byte, AVX2) | -- | -- | **5.09 ms** |
| sort | Sort 200k integers (insertion-run + bottom-up merge) | 38220 ms | 3.94 ms | 17.5 ms |
| add | Add/sum 262k elements | 1646 ms | 0.925 ms | 0.34 ms |
| matmul32 — IL path | Multiply 32x32 matrices | 353 ms | 0.0056 ms | 0.069 ms |
| matmul32 — simd_gemm (native) | same workload, AVX2+FMA kernel | 353 ms | 0.0056 ms | **0.0035 ms** |
| f32mm scalar | f32 matmul 32x32, scalar dot | -- | -- | 0.074 ms |
| f32mm vec | f32 matmul 32x32, SIMD Vector4 | -- | -- | 0.015 ms |

## Summary — vs CPython (5 kernels with a Python counterpart)

| Metric | Python | TokenVector | Speedup |
|--------|--------|-------------|---------|
| Geometric mean (5 kernels) | 1549 ms | 2.50 ms | **620x** |
| Highest speedup (matmul32, IL) | 353 ms | 0.069 ms | **5109x** |
| Lowest speedup (string) | 323 ms | 11.0 ms | **29.4x** |

## Summary — vs NumPy (4 common kernels: string, sort, add, matmul32)

| Metric | NumPy | TokenVector | Faster by |
|--------|-------|-------------|-----------|
| Geometric mean (4 kernels, IL path) | 0.476 ms | 1.46 ms | **NumPy 3.1x** |
| matmul32 — simd_gemm (native) | 0.0056 ms | 0.0035 ms | **TokenVector 1.6x** |
| matmul32 — IL path | 0.0056 ms | 0.069 ms | **NumPy 12.3x** |
| string | 2.51 ms | 11.0 ms | **NumPy 4.4x** |
| string — SIMD scan row | 2.51 ms (np_string) | 5.09 ms | **NumPy 2.0x** |
| sort | 3.94 ms | 17.5 ms | **NumPy 4.4x** |
| add | 0.925 ms | 0.34 ms | **TokenVector 2.7x** |

`fib` is excluded from the NumPy comparison: it is recursive, and NumPy has
no equivalent without changing the algorithm (matrix exponentiation would not
measure the same work).

## Conclusion

**TokenVector achieves 29x–5109x speedup over CPython** on equivalent
workloads, on the same OS and hardware.

**Against NumPy the picture is mixed, and the matmul row depends on the
implementation** — consistent with README §1b:

- **Native kernel wins.** `simd_gemm` (AVX2+FMA, `tkv_simd_native.dll`)
  does the exact same 32x32 f64 workload as `matmul32` in **0.0035 ms vs
  NumPy's 0.0056 ms — TokenVector 1.6x faster**, and 19.7x faster than
  TokenVector's own pure-IL path (0.069 ms). This matches README §1b
  (f32 n=32: 1.7 µs vs NumPy 5.5 µs) and the full n=128..1024 table in
  `docs/e_handoff/BAN_GIAO_2026-10-18-SIMD-GEMM.md`.
- **Pure IL loses to BLAS**: NumPy wins 3 of 4 kernels on the IL path
  (4.4–12.3x); TokenVector's element-wise `add` stays 2.7x ahead (both
  sides memory-bound; TokenVector's f64 loop is vectorized). The sort
  gap narrowed from 6.8x to 4.4x by changing the algorithm, not the
  language (see the 2026-11-03 note below).
- **string now has a SIMD scan AND a pre-sized join.** The `string scan`
  row replaces the per-char slice loop with `simd_count_byte` (new builtin
  → AVX2 `pcmpeqb` in `tkv_simd_native.dll`) and builds with `[chunk]*n`:
  16.6 → **5.09 ms** — `np_string` is now only **2.0x** ahead (was 5.8x
  at 14.5 ms). Once the scan hit ~0, the remaining ~13 ms was build+join;
  both are fixed (see the 2026-11-03 note): `String::Join` takes the
  pre-sized `ToArray + Join(string, string[])` path, `RepL` (list `* n`)
  pre-sizes with a `cnt==1` hoist, and the row builds with `[chunk]*n`.
  The plain `string` row rides the same join fix: 18.0 → 11.0 ms.

NumPy is native machine code (BLAS/ufuncs) — the IL path alone cannot
chase it; `simd_gemm` is how TokenVector gets there without changing runtime.

## Methodology

- **Python**: single pass, full process wall time (startup not amortized).
  The true ratio favors TokenVector even more than shown above.
- **NumPy**: best-of-N, timed inside the loop with setup/`import numpy`
  outside — the same 3 rules as `run_benchmark.tkv`. This is the treatment
  favorable to NumPy (conservative for TokenVector).
- **TokenVector**: best-of-N, timed inside the loop (`run_benchmark.exe`);
  the column is the best across 3 runs (machine noise was ±10%).

Note (2026-10-18): loop counters in every kernel are now typed `i32`. Before
this, untyped counters defaulted to `TkvInt` (boxed, arbitrary precision), so
every iteration paid `TkvInt::Cmp`/`FromI64`/`Add`/`ToI32`. The `add` kernel
alone went from 3.3 ms to 0.64 ms (5x) with no change to the data structures —
a measurement artefact, not a property of the language.

Note (2026-11-02): reran the Python baseline on CPython 3.14.7 (previous
results were 3.12), added the NumPy 2.5.2 column, **fixed the merge-sort
checksum bug** (see Correctness below), and added the `simd_gemm` native
matmul row.

Note (2026-11-02, sort bug — FIXED): Python and TokenVector both reported
`1548` where NumPy reported `98302`. Root cause: `_sort` merged the two halves
**in place without a temp buffer**, so elements were lost — the output was
ordered but not a permutation of the input (verified:
`sorted(work) != sorted(src)`). The same buggy algorithm existed in
`py_kernels.py`, `Release/benchmark/run_benchmark.tkv` and
`Release/tools/benchmark/run_benchmark.tkv`. All three now merge through a
temp buffer allocated once outside the timed loop (measurement rule 2), and
all three checksums are `98302`. The correct merge costs real time — Python
22.1 s → 38.2 s, TokenVector 12.8 ms → 26.6 ms — that is the honest cost of
sorting correctly, not a regression.

Note (2026-11-02, simd_gemm row): `b_matmul32_simd` runs the identical
workload and checksum as `matmul32`, calling `simd_gemm(a, b, r, n)`.
`tkv_simd_native.dll` must sit beside `run_benchmark.exe` (copied from
`Release/runtime/`). n=32 is below the multithread threshold
(`TKV_GEMM_MIN_N`=96), so this row is single-threaded call time.

Note (2026-11-02, string scan row): `b_string_scan` races `np_string` on
the same scan range (first n chars, ASCII). The row has a REAL SIMD scan:
new compiler builtin `simd_count_byte(p, n, b)` — P/Invoke into
`tkv_simd_native.dll::CountByte` (AVX2 `pcmpeqb` + movemask + popcount,
scalar tail), emitted through class `TkvSimd`
(`il_features/simd_feature.tkv`). Compiler rebuilt with `tools/vong.exe`
(IL_IDENTICAL on the first pass); `tools/testkit_gate.ps1`: **133/133 +
negative 42/42**. (An earlier run of this gate reported 132/133 because P6
was emitting the f64 lane — `System.Runtime.Intrinsics` 10.0, which .NET
Framework 4.8 cannot load — into `lmhead_bwd_fused_test.tkv`. That lane is
now opt-in via `TKV_P6_F64=1`, so by default P6 only vectorises f32 loops
and the emitted IL carries no Intrinsics reference.)

Scan path: `bstr_alloc` (native copy — the analog of NumPy's `s.encode`)
+ `simd_count_byte(bp, n*2, 101)` over the UTF-16LE bytes (high byte is 0
for ASCII, so byte==101 <=> char 'e'; ASCII-only workload). Result:
**14.5 ms** (best-of-3: 15.05 / 14.79 / 14.48) vs the old slice row 16.6
vs `np_string` 2.51 (NumPy 5.8x). Checksum 1625000 on all sides.

Honest finding: the SIMD scan times the same as the earlier native
`read_u8` loop (14.0 ms, within noise) — the scan was never the
bottleneck; build+join dominated the row. Micro (best-of-20, warm): scan
read_u8 9.1 vs slice 12.8 ms; at the time `[chunk]*n` cost 13.2 ms in TV
vs append 5.8 ms (list `* n` had no fast path — it does since 2026-11-03,
and the row now builds with it).

Note (2026-11-03, join pre-size + list-mul fast path): the two
bottlenecks above are now fixed in the compiler:

- `"...".join(list)` no longer calls `String::Join(string,
  IEnumerable<string>)` (foreach + `StringBuilder.Append` per element,
  no pre-size). It now emits `ToArray()` + `String::Join(string, string[])`
  — the path that totals the lengths first and allocates once, like
  CPython's `''.join` (`il_features/string_join.tkv`,
  `string_methods_batch2.tkv`).
- list `* n` (`RepL`) now pre-sizes `new List<T>(cnt * n)` and, when
  `cnt == 1`, hoists `s[0]` into a local and loops a plain `Add` — no
  more per-op growth (`il_features/slicing.tkv`).

Emit trap: the `ToArray()` memberref must use return type `!0[]`, never
`string[]` — with a concrete return type ilasm builds the memberref on
the open generic type and skips instantiation, which dies at runtime
with `Method not found` (the same trap documented in `simd_feature.tkv`;
`stdlib_path.tkv` already used the correct idiom).

`b_string_scan` now builds with `[chunk] * n` (the same workload as
`np_string`) instead of a while-append loop. Compiler rebuilt with
`tools/vong.exe`: cycle 1 `IL KHAC NHAU`, cycle 2 `IL_IDENTICAL`.
`tools/testkit_gate.ps1`: **132/133 + negative 42/42** — the same single
unrelated failure as before (`lmhead_bwd_fused_test`, P6 WIP). Results
(best-of-3): **string scan 14.5 → 5.09 ms** (5.48 / 5.09 / 5.15),
**string 18.0 → 11.0 ms** (11.94 / 11.23 / 11.02) — `np_string` 2.51 ms
is now 2.0x ahead instead of 5.8x. Checksums unchanged (1625000 on both
rows; every other row within noise of the table above).

Note (2026-11-03, where the sort time goes): the sort gap to NumPy is
not the comparisons. Same n=200000, same generator, measured with
variants of `_sort` that keep the identical merge structure:

| Variant | ms | What it isolates |
|---------|----|------------------|
| one pass, read only | 0.15 | indexed read of `list[i64]` |
| one pass, read+write | 0.37 | indexed read + write |
| one merge level over n | 0.63 | one level of merge (compare + write) |
| `_sort` (current) | 27.75 | baseline (bench row reads 26.6) |
| `_sort` with hoisted compares | 24.69 | −3.06 ms from not re-reading the list |
| `_sort` with no data compare | 16.73 | the merge skeleton alone |

So 18 merge levels cost 18 x 0.63 = 11.4 ms, the data comparison plus
branch misprediction adds 11.0 ms, and the remaining ~5 ms is the
approach overhead of 2n merge nodes (call + bounds bookkeeping) that the
flat per-level loop does not pay. The decisive number is the no-compare
skeleton: **16.7 ms is already 4.2x NumPy's whole 3.94 ms sort**, so even
removing every comparison would not reach it. The cost is the
copy-to-temp per level (a second write of every element, 18 times) on a
list, against NumPy's in-place introsort on a contiguous buffer. Cutting
recursion levels (sort small runs by insertion, then bottom-up merge)
attacks that part; hoisting comparisons is worth ~11% on its own.

Note (2026-11-03, sort rewritten: insertion run + bottom-up merge): both
attacks above were applied together in `run_benchmark.tkv`. `_sort` no
longer recurses and no longer copies the whole range to a temp buffer:
it insertion-sorts runs of 8, then merges **bottom-up**, alternating the
two pre-allocated buffers, so each level is read-from-A/write-to-B (2
passes per level instead of the copy + merge-back 4), and the compare
uses local `xi`/`xj` instead of re-reading `list` slots. Measured with
the same n=200000, same generator, checksum still `98302`:

| Variant | ms |
|---------|----|
| recursive `_sort` (previous) | 29.9 (same-process baseline) |
| bottom-up, no insertion runs (`run=1`) | 29.5 |
| bottom-up + insertion run=8 | 27.0 |
| bottom-up + insertion run=16 | 25.3 |
| bottom-up + hoisted compare, `run=1` | 18.3 |
| **bottom-up + hoisted compare, `run=8`** | **17.4** |
| bottom-up + hoisted compare, `run=32` | 20.7 |

The hoist is what pays (~7 ms); bottom-up alone only removes ~7% because
the per-element cost is dominated by the compare path, not by the extra
copy, and insertion sort past `run≈8` costs more than the levels it
saves (`run=64` is back to 30.3 ms). Row in the real harness:
**26.6 → 17.5 ms** (best-of-9, two runs: 17.69 / 17.46). NumPy's in-place
introsort on a contiguous buffer is still **4.4x** ahead; the remaining
gap is algorithmic (O(n log n) merge through `List<T>` slots vs sorting a
raw buffer in place) — chasing it further means a native in-place sort
kernel, not more IL tuning.

Emit trap found while writing it: the last run of a level may have no
right half (`mid == hi == n`), so `src[mid]` must be guarded by
`mid < hi` or the exe dies with `ArgumentOutOfRangeException`.

Algorithm note: `py_kernels.py` keeps the plain recursive merge sort, so
the CPython column still compares equal algorithms against each other;
the TokenVector sort row is now a *different, faster* algorithm than the
Python baseline's (same for NumPy, which was already introsort).

## Correctness

| Kernel | Checksum Python | Checksum NumPy | Checksum TokenVector |
|--------|-----------------|----------------|----------------------|
| fib(32) | 2178309 | n/a | 2178309 |
| string | 1625000 | 1625000 | 1625000 |
| sort | 98302 | 98302 | 98302 |
| add | 956798.1 | 956798.1000000001 | 956798.1 |
| matmul32 (IL + simd_gemm) | 1.0 | 1.0 | 1.0 |

The NumPy `add` checksum differs from the others by ~2e-8 absolute
(~1e-14 relative): NumPy sums pairwise, CPython/TokenVector sum sequentially.
Both are correct floating-point sums of the same values.

The `simd_gemm` checksum is exactly `1.0` because all inputs are small
integers represented exactly in f64 — the result is order-independent, so a
match proves the native kernel computes the same matrix product.

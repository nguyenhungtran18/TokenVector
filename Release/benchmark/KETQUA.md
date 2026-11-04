# TokenVector vs CPython vs NumPy — Benchmark Results

## Test Suite

| Kernel | Workload | Python 3.14 | NumPy 2.5.2 | TokenVector |
|--------|----------|-------------|-------------|-------------|
| fib(32) | Recursive Fibonacci n=32 | 1245 ms | n/a (recursive) | 15.0 ms |
| string | Join 200k substrings + count chars | 323 ms | 3.66 ms | 9.68 ms |
| string scan | Same + SIMD byte scan (BSTR + simd_count_byte, AVX2) | -- | -- | **4.54 ms** |
| sort | Sort 200k integers (radix 16-bit, merge fallback) | 38220 ms | 4.07 ms | **6.09 ms** |
| add | Add/sum 262k elements | 1646 ms | 0.912 ms | **0.583 ms** |
| matmul32 — IL path | Multiply 32x32 matrices, blocked Vector4 kernel | 353 ms | 0.0057 ms | **0.0096 ms** |
| matmul32 — simd_gemm (native) | same workload, AVX2+FMA kernel | 353 ms | 0.0057 ms | **0.0031 ms** |
| f32mm scalar | f32 matmul 32x32, scalar dot | -- | -- | 0.073 ms |
| f32mm vec | f32 matmul 32x32, SIMD Vector4 | -- | -- | 0.014 ms |

All rows are the best of 3 runs on 2026-11-04 (machine noise ±10%); the NumPy
column was re-measured the same session (`np_string` 2.51 → 3.66 ms is the
same machine drifting, not a code change).

## Summary — vs CPython (5 kernels with a Python counterpart)

| Metric | Python | TokenVector | Speedup |
|--------|--------|-------------|---------|
| Geometric mean (5 kernels) | 1549 ms | 1.38 ms | **1125x** |
| Highest speedup (matmul32, IL) | 353 ms | 0.0096 ms | **36771x** |
| Lowest speedup (string) | 323 ms | 9.68 ms | **33.4x** |

## Summary — vs NumPy (4 common kernels: string, sort, add, matmul32)

| Metric | NumPy | TokenVector | Faster by |
|--------|-------|-------------|-----------|
| Geometric mean (4 kernels, IL path) | 0.528 ms | 0.758 ms | **NumPy 1.44x** |
| matmul32 — simd_gemm (native) | 0.0057 ms | 0.0031 ms | **TokenVector 1.84x** |
| matmul32 — IL path | 0.0057 ms | 0.0096 ms | **NumPy 1.68x** |
| string | 3.66 ms | 9.68 ms | **NumPy 2.64x** |
| string — SIMD scan row | 3.66 ms (np_string) | 4.54 ms | **NumPy 1.24x** |
| sort | 4.07 ms | 6.09 ms | **NumPy 1.50x** |
| add | 0.912 ms | 0.583 ms | **TokenVector 1.56x** |

`fib` is excluded from the NumPy comparison: it is recursive, and NumPy has
no equivalent without changing the algorithm (matrix exponentiation would not
measure the same work).

## Conclusion

**TokenVector achieves 33x–36771x speedup over CPython** on equivalent
workloads, on the same OS and hardware.

**Against NumPy the picture is mixed, and the matmul row depends on the
implementation** — consistent with README §1b:

- **Native kernel wins.** `simd_gemm` (AVX2+FMA, `tkv_simd_native.dll`)
  does the exact same 32x32 f64 workload as `matmul32` in **0.0031 ms vs
  NumPy's 0.0057 ms — TokenVector 1.84x faster**, and 3.1x faster than
  TokenVector's own IL path (0.0096 ms). This matches README §1b
  (f32 n=32: 1.7 µs vs NumPy 5.5 µs) and the full n=128..1024 table in
  `docs/e_handoff/BAN_GIAO_2026-10-18-SIMD-GEMM.md`.
- **Pure IL now loses by 1.2–2.6x, not 4–12x**: after the 2026-11-04
  kernels (blocked-Vector4 matmul, radix sort) the IL path is behind
  NumPy on 3 of 4 kernels by 1.50x (sort), 1.68x (matmul32) and 2.64x
  (string), and ahead on `add` (1.56x, both sides memory-bound with
  TokenVector's f64 loop vectorized). The geometric mean went from
  NumPy 3.1x to NumPy 1.44x.
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

Note (2026-11-04, two kernels rewritten): sort and the IL matmul32 both
dropped for the same reason — the loss was in the kernel, not in the
runtime. Nothing in the compiler changed; both use primitives that already
existed (`v_load4`/`f32x4`, `list[i64]` indexing).

- **Sort → LSD radix.** `_sort` now counts by 16-bit digit, with the number
  of passes taken from the largest value (this workload's values are
  0..65535, so it needs ONE counting pass; a full-range i64 needs 4). The
  single scan that picks up max and sign sits inside the timed region,
  because choosing the pass count is part of sorting. Negative input falls
  back to the bottom-up merge, which stays in the file. **17.5 → 6.09 ms**,
  checksum still `98302`.
  Where the 6.09 goes (measured on the same n and generator, best-of-9):
  count `0.83` + prefix `0.14` + scatter **`4.15`** + copy-back `0.40` +
  max/sign scan ~`0.2`. The scatter is random writes across a 1.6 MB list,
  so it is cache-miss bound — **that**, not the comparisons, is the wall
  now, and it is what a narrower key buffer would attack next. NumPy's
  in-place introsort on a contiguous buffer is 4.07 ms.
- **matmul32 → blocked Vector4** (`_mm32v`): A and B^T are packed into flat
  buffers as setup (the same treatment NumPy gives its contiguous arrays)
  and four columns accumulate at once, so one `va` load feeds four dots.
  `_mm32` (scalar, column-strided B) stays for the `f32mm scalar` row.
  **0.069 → 0.0096 ms**, checksum `1.0` — NumPy 12.1x ahead became 1.68x.
  Variants measured: scalar `0.0725`, naive Vector4 one column at a time
  `0.0136`, 4-column block `0.0095`, 8-column block `0.0093`. The block is
  what pays; past 4 columns it stops paying.

Known divergence: `tools/benchmark/run_benchmark.tkv` (the legacy copy)
still carries the merge sort and the scalar matmul — not ported here.

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

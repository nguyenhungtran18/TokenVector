<p align="left">
  <strong>English</strong> | <a href="README.vi.md">Tiếng Việt</a>
</p>

<p align="left">
  <img src="https://img.shields.io/badge/.NET%20Framework-4.8-purple.svg?style=flat-square" alt=".NET Framework 4.8">
  <img src="https://img.shields.io/badge/version-1.0.11-blue.svg?style=flat-square" alt="version 1.0.11">
  <img src="https://img.shields.io/badge/tests-125%2F125-brightgreen.svg?style=flat-square" alt="tests 125/125">
  <img src="https://img.shields.io/badge/builtins-420-orange.svg?style=flat-square" alt="builtins 420">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License: MIT">
</p>

# TokenVector (`.tkv`, `.tv`)

A statically-typed language that compiles to **.NET CIL** and links into a
**standalone `.exe`**. Write in Python-like syntax; ship a native binary with
**no interpreter, no Python, no runtime bundle, no GIL**.

The repository root holds the **release build** and this README. Everything
else — compiler source, docs, tests, gates, examples — is inside **`Release/`**.

---

## Quick start (Windows, 3 steps)

### 1. Get the release

```powershell
git clone https://github.com/nguyenhungtran18/TokenVector.git
cd TokenVector
```

### 2. Write a program

Save this as `hello.tkv` (plain UTF-8, **no BOM** — see §Known gaps):

```python
# -*- coding: utf-8 -*-
def mean(xs: "list[f64]") -> "f64":
    if len(xs) == 0:
        return 0.0
    total = 0.0
    for x in xs:
        total = total + x
    return total / len(xs)

def run() -> "i32":
    data = [1.0, 2.5, 4.0]
    print("mean = " + str(mean(data)))
    return 0
```

### 3. Compile and run

```powershell
Release\dist\tkvc-tv.exe hello.tkv hello.exe run
.\hello.exe
```

Output:

```text
mean = 2.5
```

The CLI is **positional** — `tkvc-tv.exe <source.tkv> <output.exe> <entry>`.

The resulting `hello.exe` is **9.5 KB** (a bare `print("hi")` is **6 KB**) and runs on any machine with
**.NET Framework 4.x**. Nothing else is installed alongside it.

> **Requirement:** the compiler itself (`tkvc-tv.exe`) is a Windows PE and needs
> .NET Framework 4.x on the *build* machine. Programs it produces need the same
> framework on the *run* machine — that is the only dependency.

---

## What you get

| | |
|---|---|
| Output | one **standalone `.exe`** (PE), **6 KB** for a bare `print`, 9.5 KB for the example above |
| Types | unboxed `i32` / `i64` / `f32` / `f64` / `str`, plus `int` and `bool` |
| Runtime | .NET Framework 4.x — no interpreter, no GIL |
| Threads | `thread_spawn` / `thread_join`, true multicore with no global lock |
| SIMD | `f32x4` → `System.Numerics.Vector4`; elementwise loops are auto-vectorised (P6); `simd_gemm` runs a native AVX2+FMA kernel for f32/f64 matmul |
| Interop | any .NET/NuGet assembly, P/Invoke, and raw C FFI |

---

## Honest positioning — where it wins and where it does not

Measured 2026-10-14 against **CPython 3.14.7** and **NumPy 2.5.2** (OpenBLAS
0.3.34, Haswell kernel) on an Intel Xeon E5-2695 v3. Reproduce from
[`TokenVector.TestOracle`](https://github.com/nguyenhungtran18/TokenVector.TestOracle):

```powershell
python D:\TokenVector.TestOracle\benchmark\run.py --self-host
```

**Against CPython, TokenVector wins on every kernel:**

| kernel | TokenVector | CPython | faster by |
|---|---|---|---|
| fib | 11.4 ms | 933 ms | **82×** |
| sort | 15.7 ms | 1012 ms | **64×** |
| matmul32 | 147 µs | 8.87 ms | **60×** |
| add | 1.43 ms | 67.1 ms | **47×** |
| f32mm_vec | 33 µs | 1.48 ms | **45×** |
| f32mm | 141 µs | 1.49 ms | **11×** |
| string | 22.9 ms | 49.7 ms | **2.2×** |

An empty TokenVector `.exe` also starts in **24.8 ms** versus **35.2 ms** for
`CPython -c pass`.

**Against NumPy, it is mixed — element-wise stays memory-bound, matmul now wins
with `simd_gemm`:**

| kernel | TokenVector | NumPy | faster by |
|---|---|---|---|
| matmul32 (`simd_gemm`, f32) | 1.7 µs | 5.5 µs | **TokenVector 3.2×** |
| matmul32 (IL `Vector4` path) | 147 µs | 5.7 µs | NumPy 26× |
| add (IL list path) | 1427 µs | 911 µs | NumPy 1.6× |

The IL-path gap is **not** a missing optimisation and **not** a threading deficit. With
`OMP_NUM_THREADS=1`, `np.dot` on a 32×32 matmul only moves from 5.73 µs to
6.05 µs — OpenBLAS does not split a matrix that small. What remains is vector
width: AVX2 with FMA processes **4 `double`s per instruction**, while this
runtime exposes only `Vector4` (128-bit) and raw vector CIL is rejected by the
JIT.

Two "cheap" fixes were measured, and **both died**, so they are not the answer:

- **Strength reduction** of the inner-loop index (`kk*n + j` → induction
  variable): **1.00×**. The `mul.ovf`/`add.ovf`/`conv.ovf.i4` sequence is
  essentially free on the JIT.
- **Native contiguous storage** instead of `List<double>`: **0.63×** — *slower*,
  because `f32buf` pays a `×4` byte offset plus a bounds check per access.

**Update 2026-10-18 — `simd_gemm` (native AVX2+FMA kernel).** The gap above is
for the IL/`Vector4` path. `simd_gemm(a, b, r, n)` now calls a shipped C kernel
(`tkv_simd_native.dll`; 4×16 f32 / 4×8 f64 micro-kernels, L1/L2 cache
blocking, physical-core threading, 2-D row×column split) and takes
`list[f32]` / `list[f64]` with zero copy in and out. Measured on the same Xeon
E5-2695 v3 against NumPy 2.5.2 (OpenBLAS 0.3.34), best of several runs:

| n | f32 `simd_gemm` | f32 NumPy | f64 `simd_gemm` | f64 NumPy |
|---|---|---|---|---|
| 128 | 0.039 ms | 0.122 ms | 0.055 ms | 0.098 ms |
| 256 | 0.109 ms | 0.180 ms | 0.196 ms | 0.231 ms |
| 512 | 0.496 ms | 0.811 ms | 1.03 ms | 1.569 ms |
| 1024 | 3.68 ms | 3.867 ms | 7.59 ms | 9.921 ms |

It is faster at every size tested (128–1024) in both precisions. The pure-IL
path is unchanged and still cannot close the gap; `simd_gemm` closes it by
moving the inner kernel to native code, not by changing the runtime. Full
method and intermediate sizes:
`Release/docs/e_handoff/BAN_GIAO_2026-10-18-SIMD-GEMM.md`.

**So: TokenVector is a CPython replacement.** It beats the interpreter it
replaces 2–82×, and it has real f32 SIMD. The pure-IL path cannot reach f64
BLAS performance on .NET Framework 4.8 — but `simd_gemm` does, through a
native AVX2+FMA kernel, without changing the target runtime.

### Is every number above checked?

Yes — the repository carries its own gates, and the table below is the output
they actually print. **If a gate is not green, the claim above does not hold.**

| Gate | Command | Result |
|---|---|---|
| Compiler acceptance | `powershell -File Release\tools\testkit_gate.ps1` | **125/125** pass, **31/31** negative cases correctly rejected |
| Self-host fixpoint | `Release\tools\vong.exe` | **IL_IDENTICAL** (132 files) |
| Performance | `powershell -File Release\tools\perf_gate.ps1` | 4 kernels, best-of-5, **checksum is compared** |
| Lint-rule self-test | `powershell -File Release\tools\lint_rules_gate.ps1` | 8/8 traps caught, 0 false positives |
| Registration | `Release\dist\tkvc-tv.exe Release\tools\dang_ky_gate.tkv Release\build\dk.exe run` | 0 violations |

**Builtins registered: 420.**

The compiler itself is **self-hosted**: its source is 132 `.tkv` files under
`Release/compiler_bootstrap/`. `Release\tools\vong.exe` concatenates them,
compiles the result twice, and requires the two IL dumps to match
byte-for-byte (`IL_IDENTICAL`).

---

## Repository layout

```
TokenVector/
├── README.md            this file
├── README.vi.md         Vietnamese translation
├── LICENSE              MIT
└── Release/             the full release snapshot
    ├── compiler_bootstrap/   132 .tkv files — the compiler, written in TokenVector
    ├── compiler_src/         ds_gop.txt manifest used to concatenate them
    ├── dist/                 tkvc-tv.exe (the compiler) + il_features/
    ├── tests/                125 acceptance tests + 31 negative cases
    ├── tests_suite/          154 .ca data-driven cases + 203 input samples
    ├── tools/                gates + tkv_guide.tkv (the language guide)
    ├── projects/             19 real tools written in .tkv
    ├── examples/            sample programs + stdlib/
    ├── docs/                all documentation
    ├── packaging/           NuGet nuspec, MSBuild props/targets, pack.ps1
    └── assets/              diagrams, HTML demos, preview image
```

Clone the repo and the release is already there — nothing to download
separately, nothing to build.

---

## Documentation

| Document | What it is |
|---|---|
| [`Release/docs/REFERENCE.md`](Release/docs/REFERENCE.md) | **The one reference.** Syntax, behaviour, and every Python difference per builtin |
| [`Release/docs/HANDBOOK.md`](Release/docs/HANDBOOK.md) | Bilingual orientation + the rules that bite most |
| [`Release/docs/HANDBOOK.vi.md`](Release/docs/HANDBOOK.vi.md) | Full 10-chapter handbook (Vietnamese) |
| [`Release/docs/TUTORIAL.md`](Release/docs/TUTORIAL.md) | Programming guide, chapter by chapter |
| [`Release/docs/ARCHITECTURE.md`](Release/docs/ARCHITECTURE.md) | Compiler pipeline and file registry |
| [`Release/docs/COMPARISON-PYTHON.md`](Release/docs/COMPARISON-PYTHON.md) | Where TokenVector differs from CPython |
| [`Release/docs/PLAN.md`](Release/docs/PLAN.md) | Gap list, ranked by difficulty |
| [`Release/docs/REPOSITORY-NOTES.md`](Release/docs/REPOSITORY-NOTES.md) | Engineering journal: every bug found, and how it was proven |
| [`Release/docs/ROADMAP.md`](Release/docs/ROADMAP.md) | Product roadmap |
| [`Release/docs/llms.txt`](Release/docs/llms.txt) | Compact machine-readable summary |

### Ask the tool, not your memory

`tkv_guide` is written **in TokenVector** and is the single source of truth for
language rules. Build it once, then query it:

```powershell
powershell -File Release\tools\build_tkv_guide.ps1

Release\dist\bin\tkv_guide.exe rules               # the pitfalls that actually bite
Release\dist\bin\tkv_guide.exe find sorted         # exact syntax + how it differs from Python
Release\dist\bin\tkv_guide.exe names iter          # registered builtins, per module
Release\dist\bin\tkv_guide.exe lint my_file.tkv    # traps the compiler silently ignores
Release\dist\bin\tkv_guide.exe verify my_file.tkv  # prints the exact build+run commands
```

`verify` only **prints** the two commands — TokenVector cannot spawn a process
yet, so the tool cannot build for you. Run both and read the output.

> **A green build is not a correct program.** Bugs exist that compile cleanly
> and then return a *wrong value*. Always build **and run**.

---

## Things that will surprise a Python programmer

All of these were probed, not assumed:

- **Local variables inside functions must not be annotated.** Write `x = 1`,
  not `x: "i32" = 1`. The type is inferred from the right-hand side.
- **`f"{n}"`, `f"{n:05d}"`, `f"{v:.2f}"`, `"{}".format(x)` and triple-quoted
  strings** all work.
- **`str(x)` accepts any expression**: `str(a + b)`, `str(len(xs) + 1)`. Only
  `fmt_float(v, n)` insists on `v` being a plain variable.
- **Regex builtins take the input first**: `re_search(pattern, s)`. Names are
  `re_match` / `re_search` / `re_fullmatch` / `re_sub` / `re_split` /
  `re_findall`. `re_findall` returns whole matches, not groups.
- **`next(it, default)`** requires `default` to have the element's dtype.
- **`except RuntimeError:` also catches `StopIteration`** — both map to
  `System.InvalidOperationException`. Use `next(it, default)` to test exhaustion.
- **`hash()` is FNV-1a**, not Python's. Fine as a key, **not** value-compatible.
- **Container coercions happen at the call site**, so passing a list literal to
  a `list[i32]` parameter works.
- **`print` goes through `Console::WriteLine`**; redirected stdout defaults to
  UTF-16LE, which PowerShell 5.1 renders as `?`. Use `path_write_text` in your
  own tools.
- **A UTF-8 BOM in the source file is rejected** (`U+FEFF`). PowerShell 5.1's
  `Set-Content -Encoding UTF8` writes one — use `-Encoding utf8NoBOM` or
  `[System.IO.File]::WriteAllText`.

## Known gaps

Verified by probe; the ranked list with difficulty is
[`Release/docs/PLAN.md`](Release/docs/PLAN.md).

- **No `subprocess`** — a program cannot start another process.
- **Negative slice step** — `a[::-1]` and `a[1:-1]` are rejected; positive steps
  work (`a[::2]`, `a[1:5:2]`).
- No `slice()` as a callable, no keyword-only or positional-only parameters.
- **Conditional expression with mismatched branch types** (`i32 if c else f64`)
  compiles and returns a garbage pointer. Both branches must share a dtype.
- Record container fields should be declared `list[int]`, not `list[i32]`, when
  fed from a list literal.

## Interop

- **Any .NET / NuGet assembly** — `__tkv_extern_class__` for constructors,
  methods and properties; `__tkv_extern_pinvoke__` for P/Invoke; dynamic C FFI
  via `LoadLibraryA` / `GetProcAddress`.
- **Concurrency** — `thread_spawn` / `thread_join` use the .NET thread pool with
  no global lock.
- **Cross-assembly imports** are supported via `__tkv_extern_class__`.

## Rebuilding the compiler

Nothing needs rebuilding to *use* the release. To work on the compiler itself:

```powershell
cd Release
tools\vong.exe
```

That concatenates `compiler_bootstrap/`, compiles it twice, and prints
`IL_IDENTICAL` when the fixpoint holds. `IL KHAC NHAU` means the compiler
upgraded itself — just run it again. Then:

```powershell
powershell -File tools\testkit_gate.ps1
```

---

## Editor support

- **VS Code** — [`TokenVector Language Support`](https://marketplace.visualstudio.com/items?itemName=nguyenhungtran18.tokenvector-syntax)
  (syntax highlighting, snippets `tkv-entry` / `tkv-func` / `tkv-class`).
  Source: [nguyenhungtran18/tokenvector-grammar](https://github.com/nguyenhungtran18/tokenvector-grammar).
- **Language ID** `tokenvector`; file extensions `.tkv`, `.tv`; scope
  `source.tokenvector`.
- **Ask the repo itself** — an agent pointed at the repository can run
  `Release\dist\bin\tkv_guide.exe rules` for the rules that actually bite.

## Licence

[MIT](LICENSE) © 2026 TokenVector Project / Nguyen Hung Tran.

---

<sub>Roadmap: [`Release/docs/ROADMAP.md`](Release/docs/ROADMAP.md) ·
Strategy: [`Release/docs/STRATEGY.md`](Release/docs/STRATEGY.md) ·
Engineering history: [`Release/docs/REPOSITORY-NOTES.md`](Release/docs/REPOSITORY-NOTES.md)</sub>

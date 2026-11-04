<p align="left">
  <strong>English</strong> | <a href="README.vi.md">Tiếng Việt</a>
</p>

<p align="left">
  <img src="https://img.shields.io/badge/.NET-10-purple.svg?style=flat-square" alt=".NET 10">
  <img src="https://img.shields.io/badge/version-1.0.11-blue.svg?style=flat-square" alt="version 1.0.11">
  <img src="https://img.shields.io/badge/tests-135%2F135-brightgreen.svg?style=flat-square" alt="tests 134/134">
  <img src="https://img.shields.io/badge/builtins-423-orange.svg?style=flat-square" alt="builtins 423">
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
**.NET 10**. Nothing else is installed alongside it.

> **Requirement:** the compiler itself (`tkvc-tv.exe`) is a Windows PE and needs
> .NET 10 on the *build* machine. Programs it produces need the same
> framework on the *run* machine — that is the only dependency.

---

## What you get

| | |
|---|---|
| Output | one **standalone `.exe`** (PE), **6 KB** for a bare `print`, 9.5 KB for the example above |
| Types | unboxed `i32` / `i64` / `f32` / `f64` / `str`, plus `int` and `bool` |
| Runtime | .NET 10 — no interpreter, no GIL |
| Threads | `thread_spawn` / `thread_join`, true multicore with no global lock |
| SIMD | `f32x4` → `System.Numerics.Vector4`; elementwise loops are auto-vectorised (P6); `simd_gemm` runs a native AVX2+FMA kernel for f32/f64 matmul |
| Interop | any .NET/NuGet assembly, P/Invoke, and raw C FFI |

---

## Honest positioning — where it wins and where it does not

Measured 2026-11-04 against **CPython 3.14.7** and **NumPy 2.5.2**
(OpenBLAS 0.3.34, Haswell kernel). Full method and checksums:
[`Release/benchmark/KETQUA.md`](Release/benchmark/KETQUA.md).

**Against CPython, TokenVector wins on every kernel in the harness:**

| kernel | TokenVector | CPython | faster by |
|---|---|---|---|
| fib(32) | 14.9 ms | 1169 ms | **78×** |
| sort | 1.51 ms | 37659 ms | **24989×** (different algorithms; see note) |
| matmul32 (native) | 3.2 µs | 308 ms | **96250×** |
| add | 0.582 ms | 1540 ms | **2647×** |
| string | 5.28 ms | 337 ms | **64×** |

**Against NumPy the picture is mixed, and `string` is now bounded by
`join`, not per-character allocation:**

| kernel | TokenVector | NumPy 2.5.2 | faster by |
|---|---|---|---|
| matmul32 (`simd_gemm`, f64) | 3.3 µs | 5.2 µs | **TokenVector 1.58×** |
| matmul32 (IL f32x4 path) | 9.5 µs | 5.2 µs | NumPy 1.83× |
| add | 0.582 ms | 0.845 ms | **TokenVector 1.45×** |
| sort | 1.51 ms | 3.93 ms | **TokenVector 2.61×** (different algorithms; see note) |
| string | 5.28 ms | 2.23 ms | NumPy 2.37× |
| string — SIMD scan row | 4.58 ms | 2.23 ms | NumPy 2.05× |

NumPy is native machine code (BLAS/ufuncs), not a managed runtime. The
IL path cannot chase BLAS consistently; `simd_gemm` is the native route.
The sort row uses a 16-bit counting kernel on this workload and falls back
to merge for negative/out-of-range input, so its ratio measures a different
algorithm, not a general-purpose comparison sort.

### Is every number above checked?

Yes — the repository carries its own gates, and the table below is the output
they actually print. **If a gate is not green, the claim above does not hold.**

| Gate | Command | Result |
|---|---|---|
| Compiler acceptance | `powershell -File Release\tools\testkit_gate.ps1` | **134/134** pass, **42/42** negative cases correctly rejected |
| Self-host fixpoint | `Release\tools\vong.exe` | **IL_IDENTICAL** (133 files) |
| Performance | `powershell -File Release\tools\perf_gate.ps1` | 4 kernels, best-of-5, **checksum is compared** |
| Lint-rule self-test | `powershell -File Release\tools\lint_rules_gate.ps1` | 8/8 traps caught, 0 false positives |
| Registration | `Release\dist\tkvc-tv.exe Release\tools\dang_ky_gate.tkv Release\build\dk.exe run` | 0 violations |

**Builtins registered: 423.**

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
    ├── compiler_bootstrap/   133 .tkv files — the compiler, written in TokenVector
    ├── compiler_src/         ds_gop.txt manifest used to concatenate them
    ├── dist/                 tkvc-tv.exe (the compiler) + il_features/
    ├── tests/                135 acceptance tests + 44 negative cases
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

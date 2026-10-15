<p align="left">
  <strong>English</strong> | <a href="README.vi.md">Tiếng Việt</a>
</p>

# TokenVector (`.tkv`, `.tv`)

A statically-typed language that compiles to **.NET CIL** and links into a
**standalone PE executable**. No interpreter, no CPython at run time, no GIL.

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

```powershell
cd D:\TokenVector
dist\tkvc-tv.exe demo.tkv demo.exe run
.\demo.exe
```

The output is a **~6 KB** `.exe` (hello-world) that runs on any machine with the
.NET Framework — **no Python, no runtime bundle, no venv**.

---

## 1. Status — verified, not aspirational

Everything below is checked by a gate in this repository. Numbers are from
2026-10-14.

| Gate | Command | Result |
|---|---|---|
| Compiler acceptance | `powershell -File Release\tools\testkit_gate.ps1` | **125/125** pass, **31/31** negative cases correctly rejected |
| Self-host fixpoint | `Release\tools\vong.exe` | **IL_IDENTICAL** (132 files) |
| Performance | `powershell -File Release\tools\perf_gate.ps1` | 4 kernels, best-of-5, **checksum is compared** |
| Lint-rule self-test | `powershell -File Release\tools\lint_rules_gate.ps1` | 8/8 traps caught, 0 false positives |
| Registration | `Release\dist\tkvc-tv.exe Release\tools\dang_ky_gate.tkv Release\build\dk.exe run` | 0 violations |

**Builtins registered: 420.**

> **What the compiler actually is.** The compiler source is **`compiler_bootstrap/`**
> — 132 files that really are TokenVector. `Release\dist\tkvc-tv.exe` is built by
> `Release\tools\vong.exe`, which concatenates those files and compiles them **twice**;
> the two IL dumps must match byte-for-byte (`IL_IDENTICAL`). That is what
> "self-hosted" means here.

> **Do not trust a claim in this repo that no gate checks.** Benchmarks in
> `docs/ROADMAP.md` are dated measurements; cross-checks against CPython/NumPy
> live in the `TokenVector.TestOracle` repository, and performance is checked
> against the compiler's own baseline (`tools/perf/baseline.txt`), never against
> a pre-built binary.

## 1b. Where TokenVector competes — and where it does not

Measured 2026-10-14 against **CPython 3.14.7** and **NumPy 2.5.2** (OpenBLAS
0.3.34, Haswell kernel) on an Intel Xeon E5-2695 v3. Reproduce with
`python D:\TokenVector.TestOracle\benchmark\run.py --self-host`.

**Against CPython, TokenVector wins everywhere:**

| kernel | TokenVector | CPython | TokenVector faster by |
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

**Against NumPy, it does not — and it should not pretend otherwise.** NumPy is
CPython calling **native machine code**, not a managed runtime:

| kernel | TokenVector | NumPy | NumPy faster by |
|---|---|---|---|
| add | 1427 µs | 911 µs | **1.6×** |
| matmul32 | 147 µs | 5.7 µs | **26×** |

That gap is **not** a missing optimization and **not** a threading deficit. An
`OMP_NUM_THREADS=1` measurement moves `np.dot` on a 32×32 matmul from 5.73 µs to
only 6.05 µs — OpenBLAS does not split a matrix that small. What remains is
vector width: AVX2 with FMA processes **4 `double`s per instruction**, while
this runtime exposes only `Vector4` (128-bit) and raw vector CIL is rejected by
the JIT (see §2 and `docs/PLAN.md` §8).

Two "cheap" compiler levers were measured and **both died**, so they are not the
answer either:

- **Strength reduction** of the inner-loop index (`kk*n + j` → induction
  variable): **1.00×**. The `mul.ovf`/`add.ovf`/`conv.ovf.i4` sequence is
  essentially free on the JIT.
- **Native contiguous storage** instead of `List<double>`: **0.63×** — *slower*,
  because `f32buf` pays a `×4` byte offset plus a bounds check per access.

**So the honest position is: TokenVector is a CPython replacement, not a BLAS
replacement.** It wins 2–82× over the interpreter it replaces, it has working
f32 SIMD (4.25× over its own scalar path on `f32mm_vec`), and it cannot reach
`f64` SIMD on .NET Framework 4.8 at all. Closing that last gap means changing the
target runtime, not optimizing this one.

## 2. What TokenVector is *not*

It is **not** CPython with a faster interpreter. It is a **transpiler to CIL**:

- **The compiler source is TokenVector**, not Python. Building `tkvc-tv.exe`
  needs no CPython at all; only `Release\dist\tkvc-tv.exe` and `Release\tools\vong.exe`.
- Syntax is Python-*inspired*, not Python-*compatible*. Known gaps are listed in
  §6 and are checked, not assumed.

## 3. Where things live

This repository root carries the **release** and the **README** only. Everything
else — compiler source, docs, tests, gates, examples — lives inside `Release/`.

```
Release/                  the full release snapshot
  compiler_bootstrap/     the compiler — 132 .tkv files (the real TokenVector source)
  compiler_src/           file manifest (ds_gop.txt) used to concatenate them
  dist/                   tkvc-tv.exe — the self-hosted compiler, plus il_features/
  tests/                  125 acceptance tests + 31 negative cases
  tests_suite/            154 .ca data-driven cases + 203 input samples
  tools/                  gates + tkv_guide.tkv (the language guide, written in TokenVector)
  projects/               19 real tools written in .tkv
  examples/               sample programs + stdlib/
  docs/                   all documentation (see below)
  packaging/              NuGet nuspec, MSBuild props/targets, pack.ps1
  assets/                 diagrams, HTML demos, preview image
```

Rebuild the compiler from inside `Release/`:

```powershell
cd Release
Release\tools\vong.exe            # concatenates compiler_bootstrap\ + compiles twice
                          # prints IL_IDENTICAL when the fixpoint holds
```

| Doc | What |
|---|---|
| `docs/REFERENCE.md` | **The one reference.** Syntax + behaviour + Python differences for every builtin |
| `docs/HANDBOOK.md` | Bilingual orientation + the rules that bite most |
| `docs/HANDBOOK.vi.md` | Full 10-chapter handbook (Vietnamese) |
| `docs/TUTORIAL.md` | Programming guide, chapter by chapter |
| `docs/ARCHITECTURE.md` | Compiler pipeline, file registry |
| `docs/COMPARISON-PYTHON.md` | Where TokenVector differs from CPython |
| `docs/PLAN.md` | Gap list, ranked by difficulty |
| `docs/REPOSITORY-NOTES.md` | Engineering journal: every bug found, and how it was proven |
| `docs/ROADMAP.md`, `docs/STRATEGY.md` | Product roadmap and positioning |
| `docs/llms.txt` | Compact machine-readable summary |

## 4. For agents and new contributors: ask the tool

Never work from memory — the details are large and some past "documentation"
was simply wrong. The tool is written **in TokenVector** and is the single
source of truth for language rules:

```powershell
cd D:\TokenVector
powershell -File Release\tools\build_tkv_guide.ps1

Release\dist\bin\tkv_guide.exe rules              # the pitfalls that actually bite
Release\dist\bin\tkv_guide.exe find sorted        # exact syntax + how it differs from Python
Release\dist\bin\tkv_guide.exe names iter         # registered builtins, per module
Release\dist\bin\tkv_guide.exe lint my_file.tkv   # traps the compiler silently ignores
Release\dist\bin\tkv_guide.exe verify my_file.tkv # prints the exact build+run commands
```

`verify` only **prints** the two commands — TokenVector cannot spawn a process
yet, so the tool cannot build for you. Run both and read the output.

> **A green build is not a correct program.** Bugs exist that compile cleanly
> and then return a *wrong value*. Always build **and run**.

## 5. Notable behaviours (all probed, not assumed)

- `f"{n}"`, `f"{n:05d}"`, `f"{v:.2f}"`, `"{}".format(x)` and `"""triple
  quoted"""` strings **all work**.
- `str(x)` accepts **any expression**: `str(a + b)`, `str(len(xs) + 1)`.
  Only `fmt_float(v, n)` insists on `v` being a plain variable.
- Local variables inside functions must **not** be annotated (`x = 1`, not
  `x: "i32" = 1`); the type is inferred from the right-hand side.
- Regex builtins take the **input first**: `re_search(pattern, s)`. Names are
  `re_match` / `re_search` / `re_fullmatch` / `re_sub` / `re_split` /
  `re_findall`. `re_findall` returns whole matches, not groups.
- `next(it, default)` requires `default` to have the element's dtype.
- **`except RuntimeError:` also catches `StopIteration`** — both map to
  `System.InvalidOperationException`. Use `next(it, default)` to test for
  exhaustion.
- `hash()` is FNV-1a, not Python's. Fine as a key, **not** value-compatible.
- Container coercions happen at the call site, so passing a list literal to a
  `list[i32]` parameter works.
- `print` goes through `Console::WriteLine`; redirected stdout defaults to
  **UTF-16LE**, which PowerShell 5.1 renders as `?`. Use `--file out.txt` with
  `tkv_guide`, or `path_write_text` in your own tools.
- **A UTF-8 BOM in the source file is rejected** (`U+FEFF`). PowerShell 5.1's
  `Set-Content -Encoding UTF8` writes one — use `-Encoding utf8NoBOM` or
  `[System.IO.File]::WriteAllText`.

## 6. Known gaps

Verified by probe; the ranked list with difficulty is `docs/PLAN.md`.

- **No `subprocess`** — a program cannot start another process. (This is why
  `tkv_guide verify` can only print commands.)
- **Negative slice step** — `a[::-1]` and `a[1:-1]` are rejected; positive steps
  work (`a[::2]`, `a[1:5:2]`).
- No `slice()` as a callable, no keyword-only or positional-only parameters.
- **Conditional expression with mismatched branch types** (`i32 if c else f64`)
  compiles and returns a garbage pointer. Both branches must share a dtype.
- Record container fields should be declared `list[int]`, not `list[i32]`, when
  fed from a list literal.

## 7. Interop

- **Any .NET / NuGet assembly**: `__tkv_extern_class__` for constructors,
  methods and properties; `__tkv_extern_pinvoke__` for P/Invoke; dynamic C FFI
  via `LoadLibraryA`/`GetProcAddress`.
- **Concurrency**: `thread_spawn` / `thread_join` use the .NET thread pool with
  no global lock.
- **Cross-assembly imports** are supported via `__tkv_extern_class__`.

## 8. Rebuilding the compiler

There is nothing to rebuild at root. `Release\dist\tkvc-tv.exe` is **derived from source in this
repository** and is regenerated by the self-host loop:

```powershell
Release\tools\vong.exe     # concatenates compiler_bootstrap\ + compiles twice
                   # prints IL_IDENTICAL when the fixpoint holds
```

After editing anything under `Release\compiler_bootstrap\`, run `Release\tools\vong.exe` until
it prints `IL_IDENTICAL` (`IL KHAC NHAU` means the compiler upgraded itself —
just run it again), then `Release\tools\testkit_gate.ps1`.

---

*Licence: see `LICENSE`. Roadmap and strategy documents live in
`docs/ROADMAP.md` and `docs/STRATEGY.md`; engineering
history lives in `docs/REPOSITORY-NOTES.md`.*

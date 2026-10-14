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
2026-10-02.

| Gate | Command | Result |
|---|---|---|
| Compiler acceptance | `powershell -File tools\testkit_gate.ps1` | **123/123** pass, **31/31** negative cases correctly rejected |
| Self-host fixpoint | `tools\vong.exe` | **IL_IDENTICAL** (132 files) |
| Performance | `powershell -File tools\perf_gate.ps1` | 4 kernels, best-of-5, **checksum is compared** |
| Lint-rule self-test | `powershell -File tools\lint_rules_gate.ps1` | 8/8 traps caught, 0 false positives |
| Registration | `dist\tkvc-tv.exe tools\dang_ky_gate.tkv build\dk.exe run` | 0 violations |

**Builtins registered: 376.**

> **What the compiler actually is.** The compiler source is **`compiler_bootstrap/`**
> — 132 files that really are TokenVector. `dist\tkvc-tv.exe` is built by
> `tools\vong.exe`, which concatenates those files and compiles them **twice**;
> the two IL dumps must match byte-for-byte (`IL_IDENTICAL`). That is what
> "self-hosted" means here.
>
> The `compiler_py/` submodule holds an older **Python** bootstrap. **It is out
> of scope since 2026-10-14** — do not modify, rebuild, or depend on it. Nothing
> in this repository's gate list needs it.

> **Do not trust a claim in this repo that no gate checks.** Benchmarks in
> `docs/ROADMAP.md` are dated measurements; cross-checks against CPython/NumPy
> live in the `TokenVector.TestOracle` repository, and performance is checked
> against the compiler's own baseline (`tools/perf/baseline.txt`), never against
> a pre-built binary.

## 2. What TokenVector is *not*

It is **not** CPython with a faster interpreter. It is a **transpiler to CIL**:

- **The compiler source is TokenVector**, not Python. Building `tkvc-tv.exe`
  needs no CPython at all; only `dist\tkvc-tv.exe` and `tools\vong.exe`.
- Syntax is Python-*inspired*, not Python-*compatible*. Known gaps are listed in
  §6 and are checked, not assumed.

## 3. Where things live

```
compiler_bootstrap/  the compiler — 132 .tkv files (the real TokenVector source)
compiler_src/        file manifest (ds_gop.txt) used to concatenate them
dist/                tkvc-tv.exe — the self-hosted compiler
tests/               123 acceptance tests + 31 negative cases
tests_suite/         154 .ca data-driven cases + 203 input samples
tools/               gates + tkv_guide.tkv (the language guide, written in TokenVector)
projects/            19 real tools written in .tkv
examples/            sample programs + stdlib/
docs/                all documentation (see below)
packaging/           NuGet nuspec, MSBuild props/targets, pack.ps1
assets/              diagrams, HTML demos, preview image
build/               generated — never committed
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
powershell -File tools\build_tkv_guide.ps1

dist\bin\tkv_guide.exe rules              # the pitfalls that actually bite
dist\bin\tkv_guide.exe find sorted        # exact syntax + how it differs from Python
dist\bin\tkv_guide.exe names iter         # registered builtins, per module
dist\bin\tkv_guide.exe lint my_file.tkv   # traps the compiler silently ignores
dist\bin\tkv_guide.exe verify my_file.tkv # prints the exact build+run commands
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

There is nothing to rebuild. `dist\tkvc-tv.exe` is **derived from source in this
repository** and is regenerated by the self-host loop:

```powershell
tools\vong.exe     # concatenates compiler_bootstrap\ + compiles twice
                   # prints IL_IDENTICAL when the fixpoint holds
```

After editing anything under `compiler_bootstrap/`, run `tools\vong.exe` until
it prints `IL_IDENTICAL` (`IL KHAC NHAU` means the compiler upgraded itself —
just run it again), then `tools\testkit_gate.ps1`.

The old Python bootstrap (`compiler_py/`, `tkvc.exe`) is **out of scope** — see
§1.

---

*Licence: see `LICENSE`. Roadmap and strategy documents live in
`docs/ROADMAP.md` and `docs/STRATEGY.md`; engineering
history lives in `docs/REPOSITORY-NOTES.md`.*

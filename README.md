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
cd D:\TokenVector\3.code
dist\tkvc.exe build demo.tkv --out demo.exe --entry run
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
| Compiler acceptance | `powershell -File tools\testkit_gate.ps1` | **117/117** pass, **31/31** negative cases correctly rejected |
| CPython parity probe | `powershell -File tools\parity_probe\run.ps1` | **119/119** identical output vs CPython 3.12 |
| .NET extern smoke | `powershell -File tools\ext_smoke.ps1` | **4/4** |
| Lint-rule self-test | `powershell -File tools\lint_rules_gate.ps1` | 8/8 traps caught, 0 false positives |
| Doc coverage | `python tools\gen_builtin_ref.py --check` | **234/234** registered names documented |
| Data ecosystem | `D:\TokenVector.Data\tools\datagate.ps1` | **18/18** |
| Inference | `D:\TokenVector.Inference\tv\tests\inference_tests.tkv` | **26/26** |

**Builtins registered: 376. Compiler sources: 126 `.tkv` files** (119 under
`compiler/il_features/`) — the compiler is written in TokenVector itself.

> **Do not trust a claim in this repo that no gate checks.** Benchmarks in
> `INTERNAL_LIB_ROADMAP.md` are dated measurements; reproduce with
> `python bench\run.py`, never from a pre-built binary.

## 2. What TokenVector is *not*

It is **not** CPython with a faster interpreter. It is a **transpiler to CIL**:

- **The compiler source is `.tkv`**, but `build_tkvc.ps1` stages those files as
  Python and freezes them with PyInstaller. So *building* `tkvc.exe` uses
  CPython; *running* a compiled `.tkv` does not.
- Syntax is Python-*inspired*, not Python-*compatible*. Known gaps are listed in
  §6 and are checked, not assumed.

## 3. Where things live

| Path | What |
|---|---|
| `3.code/compiler/` | The compiler. `il_codegen.tkv` + 119 `il_features/*.tkv` |
| `3.code/dist/tkvc.exe` | The compiler binary (gitignored; rebuild via `build_tkvc.ps1`) |
| `3.code/Testkit/` | **117 acceptance tests + 31 negative cases** + `tkv_test_lib.tkv` |
| `3.code/tools/` | Gates, plus `tkv_guide.tkv` (see §4) |
| `3.code/docs/REFERENCE.md` | **The one reference.** Syntax + behaviour + Python differences for every builtin |
| `3.code/docs/REPOSITORY-NOTES.md` | Engineering journal: every bug found, and how it was proven |
| `3.code/docs/PLAN.md` | Gap list, ranked |
| `3.code/examples/` | Sample programs and real case-study tools written in `.tkv` |
| `nuget/` | `pack.ps1` + nuspec for the published package |

## 4. For agents and new contributors: ask the tool

Never work from memory — the details are large and some past "documentation"
was simply wrong. The tool is written **in TokenVector** and is the single
source of truth for language rules:

```powershell
cd D:\TokenVector\3.code
powershell -File tools\build_tkv_guide.ps1

dist\tkv_guide.exe rules              # the pitfalls that actually bite
dist\tkv_guide.exe find sorted        # exact syntax + how it differs from Python
dist\tkv_guide.exe names iter         # registered builtins, per module
dist\tkv_guide.exe lint my_file.tkv   # traps the compiler silently ignores
dist\tkv_guide.exe verify my_file.tkv # prints the exact build+run commands
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

Verified by probe; the ranked list with difficulty is `3.code/docs/PLAN.md`.

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
- **Cross-assembly imports** are supported and exercised by the extern smoke
  test.

## 8. Rebuilding the compiler

```powershell
powershell -NoProfile -File .\build_tkvc.ps1
```

Only `3.code/compiler/**` plus `build_tkvc.ps1` are needed. The script
regenerates the plugin bootstrap so every feature module is really loaded, and
clears the PyInstaller cache — without that, a "successful" build can silently
ship the previous `exe`.

---

*Licence: see `LICENSE`. Roadmap and strategy documents live in
`INTERNAL_LIB_ROADMAP.md` and `TOKENVECTOR_VS_RUST_AND_KERNEL.md`; engineering
history lives in `3.code/docs/REPOSITORY-NOTES.md`.*

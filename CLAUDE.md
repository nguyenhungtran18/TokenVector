# TokenVector Engine & Ecosystem Guidelines

## Environment & Identity
- **Language**: TokenVector (`.tkv`, `.tv`).
- **Target**: .NET Common Intermediate Language (CIL) via AOT compiler (`tkvc.exe`).
- **Runtime Model**: Standalone native PE binaries (~8.5 KB), unboxed scalar types, true No-GIL multicore execution.
- **Rule**: DO NOT treat as Python. Do NOT recommend Python venv, pip, or standard CPython modules.

## Toolchain & Commands
- **Compile Standalone Binary**:
  `.\3.code\dist\tkvc.exe build <source.tkv> --out <output.exe> --entry run`
- **Run Built Binary**:
  `.\<output.exe>`
- **Acceptance Gate (run this, not native_test_suite)**:
  `.\3.code\tools\testkit_gate.ps1` — builds and runs all 65 `Testkit\*_test.tkv`,
  writes output to TEMP so a run never litters the repo, exits non-zero on any failure.
  The `native_test_suite.tkv` command below is a *library-author linter*
  (`check_file` entry) and does not currently build: the self-hosted
  transpiler has no `yield from` — see `3.code/docs/REPOSITORY-NOTES.md`.
- **Benchmark**:
  `python .\3.code\bench\run.py` — TokenVector vs CPython/NumPy, 7 kernels, builds
  its own kernels from `dist\tkvc.exe`. Do not report a speedup from a
  pre-built binary.

## Syntax & Coding Standards
- **File Header**: Always start with `# -*- coding: utf-8 -*-`.
- **Type Annotations**: Unboxed string scalar types are mandatory on all function signatures (`"i32"`, `"f64"`, `"str"`, `"bool"`).
  - `"bool"` is an **alias of `"i32"`**, not a separate type. Both are 0/1 and are
    interchangeable; `"bool"` exists so boolean code reads like Python's. The
    compiler canonicalises it in `TypeAnn.__init__` (`canon_dtype` in
    `compiler/typed_dsl_parser.tkv`), so nothing downstream needs to know.
  - `bool` only works as an *annotation*. Local variables are never annotated.
  - Beware: `str(<comparison>)` inline prints `"True"`/`"False"`, but the same
    value bound to a variable prints `"1"`/`"0"`. Assign before formatting.
- **Local Variables**: Types are inferred automatically from right-hand side expressions (do not annotate local variables inside function bodies).
- **Class Members**: Must be declared as typed fields at the class body level before `__init__`.
- **String Concatenation**: Use explicit `+ str(val)` rather than f-strings.
  - String literals are **double quotes only** — `'abc'` is a compile error.
  - Triple-quoted multi-line strings are not supported.
  - Methods can only be called on named variables, not on literals or
    arbitrary expressions: `"a,b".split(",")` fails, bind it first.
- **Literals**: hex `0x` only — no `0o` octal, no `0b` binary, no `1e3`
  scientific notation.
- **Module-Level Variables**: must be declared with a type, `k: "i32" = 0`,
  for `global` to see them. A bare `k = 0` is not module-level for that purpose.
- **Concurrency**: Native thread pooling via `thread_spawn` and `thread_join` without GIL constraints.

# TokenVector Engine & Ecosystem Guidelines

## Environment & Identity
- **Language**: TokenVector (`.tkv`, `.tv`).
- **Target**: .NET Common Intermediate Language (CIL) via AOT compiler (`tkvc.exe`).
- **Runtime Model**: Standalone native PE binaries (~8.5 KB), unboxed scalar types, true No-GIL multicore execution.
- **Rule**: DO NOT treat as Python. Do NOT recommend Python venv, pip, or standard CPython modules.

## Toolchain & Commands
- **CHECK BEFORE ADDING ANYTHING** (`docs/BUILTIN_REFERENCE.md` in `3.code`):
  - **370 names already registered** — run
    `python 3.code\tools\gen_builtin_ref.py` to regenerate it from the source.
  - **Before creating any file in `compiler/il_features/`, check the file does not
    already exist.** I once created `bytes_type.tkv` to add `bytes()` and silently
    overwrote a **live compiler module** that `il_codegen.tkv` imports — it broke
    the entire compiler (104/104 BUILDFAIL, `ModuleNotFoundError`). The reference
    lists every existing file with its size, plus all registered builtins,
  - methods, line/assign/statement parsers.
  - Do not hand-write the list; it would go stale and repeat the same mistake.
- **Build `tkvc.exe`**: `powershell -NoProfile -ExecutionPolicy Bypass -File .\3.code\build_tkvc.ps1`
  Phân nhóm module `compiler/il_features/` do **`tools/il_features_manifest.txt`**
  đăng ký (CORE đã khai báo tường minh — tin nó, đừng đoán). Script
  `tools/_split_il_features.py` **FAIL build sớm** nếu có module import một tên
  không tồn tại, nên không bao giờ có chuyện "sót file âm thầm". Build sinh
  `_il_features_bootstrap.py` trong staging để **mọi** module CORE đều được
  nạp thật (nếu không, lệnh `register_*` trong đó không bao giờ chạy) và tự xoá
  cache `--workpath` của PyInstaller (cache này che thay đổi, từng làm build
  "thành công" nhưng exe cũ). Xem `tools/_split_il_features.py` phần docstring.
- **Compile Standalone Binary**:
  `.\3.code\dist\tkvc.exe build <source.tkv> --out <output.exe> --entry run`
- **Run Built Binary**: `.\<output.exe>`
- **Acceptance Gate (run this, not native_test_suite)**:
  `.\3.code\tools\testkit_gate.ps1` — builds and runs all 113 `Testkit\*_test.tkv`
  plus 24 negative cases (currently `PASS=113 BUILDFAIL=0 TESTFAIL=0 NEG=24/24`),
  writes output to TEMP so a run never litters the repo, exits non-zero on any failure.
  Other gates, all green as of 2026-09-30: parity probe
  `.\3.code\tools\parity_probe\run.ps1` (**119/119** match CPython),
  `.\3.code\tools\ext_smoke.ps1` (4/4), `D:\TokenVector.Data\tools\datagate.ps1`
  (18/18), `D:\TokenVector.Inference\tv\tests\inference_tests.tkv` (26/26).
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
  - `str(<bool>)` prints `"True"`/`"False"` — matching CPython, both inline
    (`str(x > 0)`) and via a variable (`b = x > 0; str(b)`). An earlier version
    of this file claimed the variable form prints `"1"`/`"0"`; that was **wrong**
    and cost a wrong test expectation on 2026-09-30.
- **Local Variables**: Types are inferred automatically from right-hand side expressions (do not annotate local variables inside function bodies).
- **Class Members**: Must be declared as typed fields at the class body level before `__init__`.
  - `__init__` must take exactly the declared fields; `Stub()` with a `value` field fails.
  - `__eq__`, `__lt__`, `__gt__` and friends must be annotated `-> "i32"` (or `"bool"`).
  - **Methods must be indented inside the class body.** A dunder defined at module
    level (unindented) is silently *not registered*, so `a == b` falls back to
    reference comparison and `a < b` reports a misleading "record has no
    `__lt__`" error. This cost me a false bug report — `__eq__`/`__lt__`/`__gt__`
    on records all work correctly (verified 2026-09-30, pinned in
    `Testkit/rec_tuple_mb_test.tkv`). See `Testkit/record_lt_test.tkv`.
- **Identity**: `is` / `is not` exist. Containers compare by reference (correct
  for this runtime — .NET `List<T>` does not override `==`). Scalars and strings
  compare by *value*, because an unboxed scalar has no object identity; this is
  an approximation, matching Python for `None`/`True`/small ints.
- **String Concatenation**: Use explicit `+ str(val)` rather than f-strings.
  - String literals are **double quotes only** — `'abc'` is a compile error.
  - Triple-quoted multi-line strings are not supported.
  - Methods can only be called on named variables, not on literals or
    arbitrary expressions: `"a,b".split(",")` fails, bind it first.
- **Literals**: `0x` hex, `0o` octal, `0b` binary, and `1e3`/`1.5e2` scientific
  are all supported. A decimal integer above int32 in an `i32` context is a
  compile error, not silent corruption — use `int("...")` or `int64(...)`.
- **Module-Level Variables**: must be declared with a type, `k: "i32" = 0`,
  for `global` to see them. A bare `k = 0` is not module-level for that purpose.
- **Concurrency**: Native thread pooling via `thread_spawn` and `thread_join` without GIL constraints.
- **Lambdas**: work, but the signature must come from a declaration. Write
  `g: "func(i32) -> i32" = lambda x: x + 1`, or pass one straight to a
  `func` parameter: `apply_it(lambda x: x * 2, 5)`. Capturing outer
  variables works. A bare `g = lambda x: ...` is an error because the lambda
  node carries parameter *names* only, and this language has no type
  inference — every function has one known signature.
- **Exceptions**: `raise <Type>(msg)` builds a *new* exception; `raise e` re-raises
  the bound object (keeps the original instance, unlike the first form);
  `raise <Type>(msg) from e` chains; bare `raise` is only valid directly inside a
  `catch`. `raise e` requires `e` to be exception-typed (the `as` binding of an
  `except`, or a record deriving `Exception`) and is rejected at compile time
  otherwise. `raise <user record>(...)` always passes its argument as `str`, so
  such a record's ctor must take a `str`.
- **`try/except/else`**: `else` sits after every `except` and before `finally`,
  and runs only when **no** handler matched — it is skipped both when a handler
  caught the exception and when an unmatched one propagates. It runs *before*
  `finally`. `break`/`continue` inside `else` work, but only when there is no
  `finally`: with one, the `else` body is generated inside the `finally`'s
  protected region where CIL forbids a plain `br`.
- **Loop `else`**: `for ... else:` / `while ... else:` runs the `else` body when
  the loop finishes **without** `break`. `continue` does *not* skip it, and a
  `break` in a nested loop skips only that inner loop's `else` — an outer `else`
  still runs. Works for `for i in range(...)`, `for x in <list/dict/set>`
  (desugared to a range loop) and `for x in <record>` (`__iter__`/`__next__`).
- **Comprehensions**: `[...]`, `{...}` (set) and `{k: v ...}` (dict) all work,
  with **any** number of `for` clauses and `if` conditions, e.g.
  `[x*y for x in a for y in b if x != y if y > 0]`. The limits are all in the
  *shape* the macro can match, not in the feature: the comprehension must be
  the entire RHS of an assignment to a **bare name** (`out = [...]`, not
  `f({...})`), and it must sit on **one physical line**. A tuple target is
  only allowed for dict comprehensions over `.items()`
  (`{k: v for k, v in d.items()}`). Each `if` becomes its own nested block, so
  `{k: v for k in a if p for v in b if q}` gives `p` to the second `for`.
- **Slicing**: `a[i:j]` works on lists and strings, and `a[i:j:k]` adds a
  **positive** step (`a[::2]`, `a[1:5:2]`). .NET has no strided primitive —
  `GetRange`/`Substring` are contiguous — so a step is lowered to a loop. A
  negative step (`a[::-1]`) is rejected; slices still only work as the direct
  RHS of an assignment, and negative indices only as compile-time constants.
- **Set literal**: `s = {1, 2, 3}` works, as the whole RHS of an assignment to a
  bare name on one line. Duplicates are dropped, the element type widens to float
  if any element is a float, and the result is a mutable `set` (`.add()`,
  `.discard()`). `{}` is an empty **dict**, as in Python — an empty set is
  `set()` — so the inline form is blocked by pre-existing limits, not by this
  feature: `len(<expr>)` cannot infer an expression's shape and `in` only takes
  a bare name. `for v in s:` works and yields members in unspecified order.
- **Dict literal**: `d = {"a": 1, "b": 2}` works, with the same shape limits as
  the set literal. A duplicate key keeps the **last** value.
- **Known gaps** (all verified by probe on 2026-09-30, not assumed):
  `yield from`, `iter()`/`next()`, `slice()` as a callable,
  a **negative** slice step (`a[::-1]`), keyword-only and positional-only
  parameters, nested/tuple literals.
- **`key=` at a call site fails in the PARSER**, not in codegen: `max(xs,
  key=neg)` → *"expected ')', got '='"*; with a lambda the message changes to
  *"expected ']', got ':'"*. Note `il_core._parse_one_call_arg` **does**
  already emit `('kwarg', name, expr)`, so kwargs work on some call forms —
  plain `f(a, b=1)` takes a different path that stops at `=`. Fixing
  `max/min/sum` with `key=` therefore means touching the core call parser,
  which is why it is still listed as missing rather than half-done.
  `*`/`**` unpacking at a call site **is** implemented
  (`('star'|'star2', expr)` + `il_features/call_star_args.py`) — the older
  claim that it is missing is wrong. Note calls still have statically known
  arity, so a run-time-length sequence cannot be passed.
  A record **cannot have a container field** — the `.ctor` takes its parameters
  from the declared fields, with container fields filtered out, so a container
  field can never be filled. This is now a compile-time error. Hold containers
  in a plain function or at module level instead. `del xs[i]` works;
  `del xs[i:j]` does not. Conditional expressions `a if c else b` **do** work
  (probe 2026-09-30) — an earlier version of this file wrongly listed them as
  missing. `getattr()`/`setattr()` were silently broken and are **fixed**
  (2026-09-30): `getattr` was registered with a hardcoded `'str'` return dtype
  so an `i32` field was read as a string → `NullReferenceException` at run time.
  It now infers the field's real dtype via `return_dtype_fn` +
  `dtype_fn_wants_ctx=True` (`register_expr_builtin`), and a missing field is a
  compile error. `format(v, spec)` also works again — the long-standing
  "unknown cause" of `format(3.14159, ".2f") == "32f"` was
  `_py_spec_to_net` returning `.2f` verbatim; .NET reads that as a *custom*
  format and needs `F2`. Full list with difficulty
  ranking in `3.code/docs/PLAN.md`; per-item status in
  `3.code/docs/REPOSITORY-NOTES.md`.

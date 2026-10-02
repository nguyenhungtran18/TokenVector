# TokenVector Engine & Ecosystem Guidelines

## Environment & Identity
- **Language**: TokenVector (`.tkv`, `.tv`).
- **Target**: .NET Common Intermediate Language (CIL) via AOT compiler (`tkvc.exe`).
- **Runtime Model**: Standalone native PE binaries (~8.5 KB), unboxed scalar types, true No-GIL multicore execution.
- **Rule**: DO NOT treat as Python. Do NOT recommend Python venv, pip, or standard CPython modules.

## Toolchain & Commands
- **CHECK BEFORE ADDING ANYTHING** — the reference is now **ONE file**:
  `3.code/docs/REFERENCE.md`. §2 lists every builtin with **syntax + what it
  does + where it differs from Python**; §7 is the auto-generated name catalog.
  - **376 names already registered** — run
    `python 3.code\tools\gen_builtin_ref.py` to rewrite §7 in place (it writes
    **only between `<!-- BEGIN GENERATED -->` markers** and refuses to run if
    they are missing — the file can no longer be overwritten by accident).
  - `python 3.code\tools\gen_builtin_ref.py --check` **fails** if any registered
    name is not documented in the hand-written part. Run it after adding a
    function.
  - **Before creating any file in `compiler/il_features/`, check the file does
    not already exist.** I once created `bytes_type.tkv` to add `bytes()` and
    silently overwrote a **live compiler module** that `il_codegen.tkv` imports
    — it broke the entire compiler (104/104 BUILDFAIL, `ModuleNotFoundError`).
    §7 of the reference lists every existing file with its size, plus all
    registered builtins, methods, line/assign/statement parsers.
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
  `.\3.code\tools\testkit_gate.ps1` — builds and runs all 117 `Testkit\*_test.tkv`
  plus 31 negative cases (currently `PASS=117 BUILDFAIL=0 TESTFAIL=0 NEG=31/31`),
  writes output to TEMP so a run never litters the repo, exits non-zero on any failure.
  Other gates, all green as of 2026-10-02: parity probe
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
- **`iter()` / `next()` work (2026-10-02).** `it = iter(xs)` is the **only**
  supported position (it needs a target name to name the state after);
  `next(iter(xs))` is a compile error. Sources: **list, set, frozenset, dict
  (yields KEYS), str (yields 1-char strings)** — all normalised to `List<T>` at
  `iter()` time, so `next()` only knows one shape. **tuple is NOT supported**
  (ValueTuple has no indexer; use `for x in t:`). Each iterator gets hidden
  locals named after the **target variable** (`__itsrc_it` holds the `List<T>`,
  `__itpos_it` the `i32` cursor) — naming them by the **variable** instead of
  `id(node)` is the whole trick, because `next(it)` only sees the name.
  `next(it)` raises `StopIteration` at the end; `next(it, default)` returns
  `default`. `default` must have the **same dtype** as the elements (no
  Python-style promotion — one variable holds one type). `iter()` **cannot**
  work at module level: module level has no variables at all (only typed
  scalars / constants / functions), and `iter()` requires a variable name.
  `StopIteration` and `RuntimeError` are the same CLR type, so
  `except RuntimeError:` also catches it.
  Full limits in `3.code/docs/REFERENCE.md` §7.12.
- **Known gaps** (all verified by probe, not assumed):
  `yield from`, `slice()` as a callable,
  a **negative** slice step (`a[::-1]`), keyword-only and positional-only
  parameters, nested/tuple literals.
- **`key=` / `reverse=` at a call site WORKS (2026-10-02)** for `min`/`max`/
  `sum`/`sorted` (`REFERENCE.md` §7.14). The long-standing note here saying it
  *"fails in the PARSER"* was **wrong twice**: `il_core._parse_one_call_arg`
  has emitted `('kwarg', name, expr)` correctly since 2026-08-28, and what
  actually broke it was the **text-level `min/max` macro**, which only counted
  commas and rewrote `max(xs, key=f)` into `(xs > (key=f) ? ...)`; it now
  detects kwargs and declines (`_has_kwarg`). `min/max/sum` return the
  **element**, not the key (Python parity); `reverse=` is evaluated at
  *runtime* so `reverse=flag` works; `sum(xs, key=f)` is an **extension** —
  CPython's `sum()` has no `key`. A key's return type must be comparable
  (`i32 i64 f32 f64 int bool`) for `min/max/sum`; `sorted` additionally allows
  `str` because it compares through .NET's `List<ValueTuple<K,T>>.Sort()`.
  `*`/`**` unpacking at a call site **is** implemented
  (`('star'|'star2', expr)` + `il_features/call_star_args.py`) — the older
  claim that it is missing is wrong. Note calls still have statically known
  arity, so a run-time-length sequence cannot be passed.
  A record **can** have a container field, but it can never be filled through
  the `.ctor` — the ctor takes its parameters from the declared fields with
  container fields filtered out. **Cửa A (2026-09-30)**: build the record with
  no-arg/`scalar` ctor args and assign the container **late**, outside the
  constructor (`it = It(0)` then `it.src = xs`). The old rule was "must be
  assigned inside `__init__`"; it is now "must be assigned **somewhere**",
  checked over the whole AST (`_check_container_fields_assigned` in
  `tkv_compile.tkv`) — never-assigned container fields are still a compile
  error, because that is the silent case (field stays null). Declare such a
  field as `list[int]`, **not** `list[i32]`, when it is fed from a list literal:
  a list literal's dtype is `int` (struct `TkvInt`) and mixing the two causes a
  real type-confusion in the emitted IL. Passing a container argument to a ctor
  that expects scalar fields is now rejected in `_expr_call` instead of
  silently emitting `TkvInt::ToI64(container)`.
  `del xs[i]` works;
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

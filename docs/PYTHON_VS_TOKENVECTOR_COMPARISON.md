# Python (5 books) vs TokenVector — Function/Feature Comparison

Corrected/rewritten 2026-08-11. Ground truth for TokenVector = `compiler/` root tree
(not `release/3.code/...`). This version replaces the earlier grep-sampled pass with a
full sequential read of all 5 books and a line-by-line read of every `compiler/il_features/*.py`
file.

> **Status note (2026-08-11, phiên 4)**: this file is the research snapshot that
> `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` was derived from — it is **not** re-read line
> by line every session. §3/§4 below are frozen as originally written (2026-08-11, phiên
> 2) except for the rows/items explicitly annotated `[DONE phiên N]` below, which record
> what shipped after this snapshot was taken. **For current implementation status, treat
> `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`'s "Trạng thái thực tế" section as the source of
> truth**, not this file — `docs/NEXT_SESSION_HANDOFF.md` is a per-session handoff log,
> not a plan, and should not be read as one either. Shipped since this snapshot: Phase 0
> (bugfix), Phase 1 (`.format()`/`%`-format, `random`/`re` extensions, 2-arg
> `.find`/`.strip`), Phase 2 (`zip()` N-ary, `path_isfile`/`isdir`, `dict.update`,
> `math_pi`/`math_e`/`math_gcd`, lambda closures), Phase 3.1 (class inheritance —
> `super()`, multi-base, `@property`-adjacent virtual dispatch/override — ported from the
> `.tkv` self-hosted tree, which already had it, into the `.py` tree), Phase 3.3
> (first-class function values via a new explicit-type local-declaration syntax, plus
> `map()`/`filter()`/`functools.reduce()` built on top). **Still open**: Phase 3.2
> (`collections` — `namedtuple`/`Counter`/`defaultdict`) and the smaller items listed in
> the plan doc's "Còn lại chưa làm" section.

## 1. Methodology (corrected — no sampling this time)

**Books**: all 5 files under `Sách Python\*.md` were read **start to finish, sequentially,
in chunks, with nothing skipped** — no grep-frequency sampling was used to decide what to
look for. Lines actually read, by file:

| File | Lines |
|---|---:|
| `BasicOfPythonProgramming.md` | 7,771 |
| `HowtocodeinPython3.md` | 10,103 |
| `Python Tutorial.md` | 6,914 |
| `PythonPrograming.md` | 4,485 |
| `machine-learning-projects-python.md` | 5,731 |
| **Total** | **35,004** |

Each book was read by a dedicated pass that recorded every distinct builtin, method,
stdlib dotted-name call, and language construct encountered, with an approximate
frequency (high/medium/low or a rough count). Results were then merged and
de-duplicated across the five books for §3/§4 below.

**TokenVector inventory**: every one of the 66 files under `compiler/il_features/*.py`
was read in full (not just confirmed to exist), plus the dispatcher/codegen core
(`compiler/il_dispatch.py`, `compiler/il_codegen.py`, `compiler/il_core.py`), extracting
every name registered via `register_expr_builtin`, `register_expr_method`,
`register_line_parser`/`register_stmt_codegen`, `register_macro_expander`, and hard
dispatch dicts (`STR_METHODS`, `_MATH_FUNCS`, etc.), plus hub-dispatched `compile_*`
functions wired into `il_codegen.py`'s hardcoded `if name == '...':` chains. Per-module
exact function lists for `random`/`re`/`itertools`/`os`/`os.path`/`datetime`/`math`/
`json`/`hashlib`/`base64`/`http` are in §2b — **found vs. absent, by exact name**, not
file-existence-only as in the prior pass.

Known-limitations cross-check source: `docs/BUGS_TODO.md` (repo root) — read in full.

## 2. TokenVector current inventory — architecture

Two registration patterns exist in `compiler/`:

1. **Self-registering modules** — call `register_expr_builtin(name, ...)`,
   `register_expr_method(shape, name, ...)`, `register_line_parser(...)`,
   `register_stmt_codegen(...)`, or `register_macro_expander(...)` at module load time.
2. **Hub-dispatched modules** — define bare `compile_*` functions imported directly into
   `compiler/il_codegen.py`, dispatched by hardcoded `if name == '...':` chains at
   `il_codegen.py:1550` (stdlib calls) and `il_codegen.py:475` (file I/O). This is how
   `stdlib_random.py`, `stdlib_path.py`, `stdlib_math.py`, `stdlib_re.py`, and part of
   `file_io.py` are wired in — a mechanism the prior pass's methodology note (which named
   only `register_expr_builtin`/`register_expr_method`) did not account for at all.

`_MATH_FUNCS` dict lives at `il_codegen.py:150` and is the shared dispatch table for all
math trig/log functions (base set from `stdlib_math.py`, extended by `stdlib_math_trig.py`).

### 2a. Category counts (source-verified)

| Category | Count | Source |
|---|---:|---|
| `register_expr_builtin` names | 40 | `il_dispatch.py` registry |
| `register_expr_method` names | 13 | `il_dispatch.py` registry |
| String methods via `STR_METHODS`/`_EXTRA`/`_EXTRA2` dicts | 13 (upper, lower, strip, replace, join, startswith, endswith, find, rfind, isdigit, lstrip, rstrip, capitalize) | `string_methods_batch2.py:87-91`, `batch3.py:120-126`, `batch4.py:61`, merged in `record_feature.py:28` |
| String methods via registry | 4 (count, zfill, split, title) | `stdlib_string_count.py`, `stdlib_string_zfill.py`, `string_split.py:56`, `string_title.py:131` |
| List methods (line-parser/regex + registry) | append, remove, insert, sort, extend, reverse, count, index, pop, copy = 10 | `list_type.py:497-504`, `list_methods_batch2.py:81-84`, `list_methods_batch3.py:44-45`, `list_count_index.py:147`, `list_pop.py`, `list_copy.py:33` |
| Dict methods | get, pop, setdefault, items, keys, values = 6 | `dict_get.py`, `dict_pop.py`, `dict_setdefault.py`, `dict_items_list.py:68`, `dict_keys_values.py:55,58` |
| Set methods | add, remove, discard, to_list, union, intersection, difference = 7 | `set_type.py:129-131`, `set_methods_batch2.py:117-125`, `set_to_list.py:43` |
| Math functions (`_MATH_FUNCS`) | 18: abs, pow, exp, sqrt, tanh, sin, cos, floor, ceil, log, round, tan, asin, acos, atan, sinh, cosh, log10, trunc | `il_codegen.py:150`, `stdlib_math.py`, `stdlib_math_trig.py` |
| Hardcoded core builtins | abs, len, pow, print + range (for-desugar) | `il_codegen.py`, `print_feature.py`, `control_flow.py` |
| try/except/finally/raise | **SUPPORTED** (not "MISSING" as prior pass claimed) | `control_flow.py:1081` (`register_line_parser('try', ...)`), `:1085` (raise), codegen `:1104,1106` |
| enumerate/zip | **SUPPORTED but narrow** — `for`-header macro-expanders only, not general expressions; `zip` is 2-list-only | `stdlib_itertools.py:22` (`try_expand_for_enumerate`), `:41` (`try_expand_for_zip`), registered `:62-63` |
| lambda | **[DONE phiên 3-4]** was PARTIAL at snapshot time; now first-class (closures with free-variable capture since Phase 2.4, storable in `func`-typed variables + reassignable + re-invocable since Phase 3.3) | `il_codegen.py`'s `_compile_lambda_funcref`/`_compile_funcref_arg`, `_lp_typed_local_decl` |
| class inheritance / `super()` / `@property` | **[DONE phiên 4]** was MISSING at snapshot time; now supported in both trees — single real inheritance + `@interface` mixins + virtual dispatch/override + `super()`. `@property` itself was already present pre-snapshot (this doc's original MISSING claim for `@property` was itself wrong — see `_extract_record_def`'s `is_property` handling) | `record_feature.py`, `tkv_compile.py`'s `_extract_record_def`/`_build_record_methods` |
| map/filter | **[DONE phiên 3-4]** was MISSING at snapshot time; now supported via `map()`/`filter()`/`reduce()`, scoped to accept only a named function or a declared `func`-typed variable (not a bare inline lambda) | `compiler/il_features/stdlib_functional.py` |
| decorators / async-await / match-case / walrus `:=` | **[DONE phien 5] async/await** (pseudo-async: functions run synchronously, result wrapped in a completed `Task<T>`). **[DONE phien 5] custom decorators** — compile-time AST macro (`@deco` on a top-level function desugars to `f = deco(f)`, scoped: no decorator args, wrapper signature must match exactly, `deco` body must be exactly `def wrapper(...): ...` + `return wrapper`). match-case/walrus still MISSING | `il_features/async_await.py`, `tkv_compile.py`'s `_expand_custom_decorator` |

**Corrected total named builtins/methods: ~120-140** (higher-confidence than the prior
pass's "~110-130 soft estimate" because §2b below now enumerates the exact function names
in every stdlib file instead of counting files as present/absent).

### 2b. Exact per-module stdlib function surface (found vs. absent, by name)

This directly replaces Corner 2 of the prior pass, which only confirmed file existence.

| Module | FOUND (exact names) | Real Python names checked and confirmed ABSENT |
|---|---|---|
| **`random`** (`stdlib_random.py`, hub-dispatched `il_codegen.py:1591-1596`) | `random()`, `randint(a,b)` (inclusive both ends), `choice(lst)` (single-variable arg only) — **3 functions** | `shuffle`, `sample`, `uniform`, `seed`, `randrange`, `gauss`, `choices` |
| **`re`** (`stdlib_re.py`, hub-dispatched `il_codegen.py:1607-1610`) | `re_match` (self-anchoring via `Regex.IsMatch`), `re_sub` (`Regex.Replace`, no `\1`→`$1` backreference translation) — **2 functions**, both flat names, no `re.` dotted syntax | `search`, `findall`, `split`, `compile`, `fullmatch`, `subn`, `finditer` |
| **`itertools`** (`stdlib_itertools.py`) | Not real itertools at all — `enumerate` and `zip` are `for`-header macro expanders only (line 22/41, registered 62-63); `zip` supports exactly 2 lists — **0 real itertools functions** | `chain`, `product`, `permutations`, `combinations`, `count`, `cycle`, `repeat`, `groupby`, `islice` |
| **`os`** (`stdlib_os.py`, self-registers 109-122) | `os_getenv`, `os_mkdir`, `os_list_files` (uses `Directory.GetFiles`, approximate `os.listdir` analog, flat name not dotted) — **3 functions** | `os.remove`, `os.rmdir`, `os.rename`; `os.path.*` lives in a separate file (below), not here |
| **`os.path`** (`stdlib_path.py`, hub-dispatched `il_codegen.py:1597-1604`) | `path_join` (2-arg only, no `*args`), `path_exists` (ORs `File.Exists`/`Directory.Exists`), `path_basename`, `path_dirname` — **4 functions** | `splitext`, `isfile`, `isdir`, `abspath`, `normpath` |
| **`datetime`** (`il_features/datetime_type.py`) | **[DONE phien 5]** Unified onto a real `datetime`/`timedelta` dtype pair (physically int64 ticks): `datetime()->datetime` (the ONE "now" constructor — old `datetime_now_utc()`/`datetime_ticks()` from `stdlib_datetime.py` and `.tkv`-only `datetime_now()` from `stdlib_bcl.tkv` were all removed after the user flagged the 4-way naming overlap as a confusion/bug risk), `datetime_strptime(s,fmt)->datetime`, `d.strftime(fmt)->str` (fmt must be a literal, compile-time translated to .NET format), `datetime_ticks(d)->i64` (extracts ticks from an existing datetime — no longer a bare 0-arg call), `timedelta_days/hours/minutes/seconds(n)->timedelta`, `datetime_add`/`datetime_sub`/`datetime_diff` (plain int64 add/sub, no `+`/`-` operator overload — deliberate scope narrowing) | `il_features/datetime_type.py`, `Signature`/`typed_dsl_parser.py` DTYPES |
| **`math`** (`stdlib_math.py` + `stdlib_math_trig.py`) | `abs, pow, exp, sqrt, tanh, sin, cos, floor, ceil, log, round, tan, asin, acos, atan, sinh, cosh, log10, trunc` — **18 functions/values**. `pow`/`**` has a dual path: int exponents use custom `TkvIPow.Pow` (throws on negative exponent), floats use `Math.Pow` | `atan2`, `log2` (explicitly excluded per source comment — .NET Framework 4.0 target predates it), `pi`, `e`, `degrees`, `radians`, `hypot`, `gcd`, `isnan`, `factorial` |
| **`json`** (`stdlib_json.py`, `stdlib_json_get.py`, `stdlib_cjson.py`) | `json_dumps` (scalars + flat list/dict, str keys only), `json_parse`, `json_get_obj`, `json_get_str`, `json_delete` — **5 functions**, flat names, no dotted `json.dumps`/`json.loads`. Two parallel implementations exist (`stdlib_json.py` vs `stdlib_cjson.py`), worth reconciling | general nested/typed `json.loads` round-trip |
| **`hashlib`** (`stdlib_hashlib.py`) | `sha256_hex`, `md5_hex` — **2 functions** | `sha1`, `sha512`, `blake2` |
| **`base64`** (`stdlib_base64.py`) | `base64_encode`, `base64_decode` — **2 functions** | urlsafe variants, `b32encode` |
| **`http`** (`stdlib_http.py` + `stdlib_http_full.py`) | `http_get`, `http_post`, `http_post_type`, `http_put`, `http_delete` (all return str), plus generic `http_request` (verb-parameterized) — **6 functions** | headers/streaming/async variants |

Other files verified: `stdlib_shutil.py` (`assign_shutil_rmtree`, assignment-form only),
`stdlib_sqlite.py` (`db_open`, `db_exec`, `db_query_text`, `db_query_int`, `db_close`),
`stdlib_zipfile.py` (`zip_create`, `zip_extract`), `stdlib_eval.py` (`eval_arith` —
arithmetic strings only, not general Python `eval`), `stdlib_repeat.py`
(`assign_list_repeat`, `assign_repeat_str` — `[x]*n`/`"s"*n` patterns), `stdlib_xml.py`
(`xml_encode_name`, hub-dispatched).

Non-stdlib construct files verified by name: `control_flow.py` (if/for/while/try/break/
continue/return/raise/with_open), `tuple_type.py` (tuple_assign, return_tuple),
`closures.py` (nested_def), `generator_lazy.py` (yield_stmt, for_in_generator),
`dict_type.py` (for_in_dict_items, container_clear, assign_dict_new), `slicing.py`
(assign_list_slice), `str_accum.py` (sb_append), `int_builtin.py`/`float_builtin.py`
(`int(...)`/`float(...)` conversion), `fstring.py`, `comprehension.py`,
`generator_feature.py`, `operators.py`, `print_feature.py` — each confirmed to
implement the construct its filename suggests; no surprises found.

## 3. Full comparison table

Legend: freq = qualitative importance across the 5 books (high/medium/low, from full
sequential reads, not sampled). Status: COVERED / PARTIAL / MISSING, each cited to the
exact TokenVector file/registration found (or explicitly confirmed absent by full-file
read + grep, not inferred from filename).

| Python feature | Freq (books) | Status | TokenVector evidence |
|---|---|---|---|
| `print()` | very high, all 5 books | COVERED | `print_feature.py`, hardcoded stmt |
| `len()` | high, all 5 | COVERED | hardcoded, `il_codegen.py` |
| `range()` | high, all 5 | COVERED | `control_flow.py` for-loop desugar |
| `int()`/`float()`/`str()` conversion | high, all 5 | COVERED | `int_builtin.py`, `float_builtin.py`; str() via string_feature |
| `.append()` | very high, all 5 | COVERED | `list_type.py` line-parser |
| `for`/`while`/`if-elif-else` | very high, all 5 | COVERED | `control_flow.py` |
| `def`/functions, `*args`/`**kwargs` | very high, all 5 | PARTIAL | core parser supports def/params; `*args`/`**kwargs` variadic unpacking not confirmed present in any `il_features` file — needs explicit check next session |
| `class`, `self.`, inheritance, `super()`, `@property` | high, esp. `BasicOfPythonProgramming.md` and `HowtocodeinPython3.md` (dedicated OOP chapters in both) | **[DONE phiên 4]** was PARTIAL at snapshot time (this row's original claim that `@property` was missing was itself wrong — it already worked) | `record_feature.py` + `tkv_compile.py`: single real inheritance + `@interface` mixins + virtual dispatch/override + `super()`, both trees |
| `try/except/finally/raise` | high, esp. `HowtocodeinPython3.md`/`PythonPrograming.md`/`Python Tutorial.md` (each has a dedicated error-handling chapter) | **COVERED** (prior pass wrongly marked UNVERIFIED/likely-MISSING) | `control_flow.py:1081` `register_line_parser('try', ...)`, raise `:1085`, codegen `:1104,1106` |
| `lambda` | medium-high, esp. `PythonPrograming.md`'s map/filter/reduce section, ML book's Q-learning bots, `Python Tutorial.md`'s `sort(key=lambda...)` | **[DONE phiên 2-4]** was PARTIAL at snapshot time | free-variable capture (Phase 2.4) + storable/reassignable/re-invocable via `func`-typed variables (Phase 3.3) |
| f-strings | medium (light in most books; `Python Tutorial.md`/ML book's type-hinted functions use them lightly) | COVERED | `fstring.py` |
| list/dict/set comprehensions, generator expressions | high in `BasicOfPythonProgramming.md`/`Python Tutorial.md`, low elsewhere | COVERED (list); dict/set comprehensions NOT separately confirmed — `comprehension.py` needs a follow-up read for dict/set coverage specifically | `comprehension.py` |
| slicing `s[a:b:c]`, negative index/step | high, `BasicOfPythonProgramming.md`/`Python Tutorial.md`/`HowtocodeinPython3.md` all have dedicated sections | COVERED | `slicing.py` |
| generators / `yield` | medium, `BasicOfPythonProgramming.md`/`Python Tutorial.md` | COVERED | `generator_feature.py`, `generator_lazy.py` |
| closures | present in 2 books | COVERED | `closures.py` |
| `.upper()`/`.lower()` | high, all books that cover strings | COVERED | `STR_METHODS` |
| `.strip()`/`.lstrip()`/`.rstrip()` | high | COVERED, no-arg only | `STR_METHODS`/`_EXTRA`; `.strip(chars)` with an argument NOT supported per `docs/BUGS_TODO.md` |
| `.replace(old,new)` | high | COVERED, 2-arg only | `STR_METHODS`; no `count` 3rd arg |
| `.split()` | high | PARTIAL | `string_split.py`; arg-count limits not fully re-verified this pass |
| `.join()` | high | COVERED | `STR_METHODS` + `string_join.py` |
| `.startswith()`/`.endswith()` | medium-high | COVERED | `STR_METHODS_EXTRA` (`string_methods_batch3.py:120-121`) |
| `.find()`/`.rfind()` | high, dedicated sections in 3 books | PARTIAL | `STR_METHODS_EXTRA`; 2-arg `.find(sub,start)` explicitly unsupported, confirmed in `docs/BUGS_TODO.md` §I ("`s.find(x) can dung 1 tham so`") |
| `.format()` | **high** — `HowtocodeinPython3.md` has a full dedicated chapter (positional/keyword args, index reorder, conversion codes, precision, alignment/padding); also used in `BasicOfPythonProgramming.md` | ❌ MISSING | no `format` in any `STR_METHODS*` dict or registry |
| `%`-style string formatting | **high** in `BasicOfPythonProgramming.md` (dedicated Format Operator section) and dominant idiom in the ML book (`'Reward: %s' % ...`) — **this is a construct the prior 70-feature list completely missed** | ❌ MISSING | no `%` string-formatting operator found anywhere in `compiler/` |
| `.isdigit()` | medium | COVERED | `STR_METHODS_EXTRA` |
| `.capitalize()` | low-medium | COVERED | `STR_METHODS_EXTRA2` |
| `.title()` | low | COVERED | `string_title.py` |
| `.count()` (str) | medium | COVERED | `stdlib_string_count.py` |
| `.zfill()` | low | COVERED | `stdlib_string_zfill.py` |
| `.center()`/`.rjust()`/`.ljust()` | medium, `Python Tutorial.md` dedicated formatting section — **missed by prior 70-feature list** | ❌ MISSING | not found in any `STR_METHODS*` dict |
| `.sort()` (list) | high | COVERED, `key=`/`reverse=` support not fully confirmed | `list_methods_batch2.py` |
| `.reverse()` | medium | COVERED | `list_methods_batch3.py` |
| `.insert()`/`.extend()`/`.remove()` (list) | medium-high each | COVERED | `list_type.py`, `list_methods_batch2.py` |
| `.pop()` (list) | medium-high | COVERED | `list_pop.py` |
| `.index()`/`.count()` (list) | medium | COVERED | `list_count_index.py` |
| `.copy()` (list) | low | COVERED | `list_copy.py` |
| `.clear()` (list/dict) | low-medium, `BasicOfPythonProgramming.md`/`Python Tutorial.md` — **missed by prior list for dict** | PARTIAL | `dict_type.py` has `container_clear`; list `.clear()` not separately confirmed |
| `.get()` (dict) | high | COVERED | `dict_get.py` |
| `.keys()`/`.values()`/`.items()` | high | COVERED | `dict_keys_values.py`, `dict_items_list.py` |
| `.setdefault()` | medium | COVERED | `dict_setdefault.py` |
| `.update()` (dict) | medium, `HowtocodeinPython3.md` dedicated subsection — **missed by prior list** | ❌ MISSING | no `dict.update` registration found |
| `.add()`/`.discard()`/`.union()`/`.intersection()`/`.difference()` (set) | low-medium | COVERED | `set_type.py`, `set_methods_batch2.py`, registry |
| `sorted()`, `sum()`, `min()`, `max()`, `any()`, `all()` | high | COVERED | `stdlib_aggregates.py` |
| `abs()`/`round()`/`pow()`/`divmod()` | medium-high | COVERED except `divmod` | hardcoded (`abs`), `_MATH_FUNCS` (`round`,`pow`); `divmod()` — **missed by prior list**, ❌ MISSING, not found anywhere |
| `enumerate()`/`zip()` | high, all 5 books | **PARTIAL** (prior pass wrongly marked fully MISSING) — `zip` widened 2→N lists in the for-header **[DONE phiên 2, Phase 2.1]**; standalone-expression form for either still open | `stdlib_itertools.py` — `for`-header macro only (now N-ary for `zip`), no general-expression form |
| `map()`/`filter()`/`reduce()` | high in `BasicOfPythonProgramming.md` (dedicated sections, incl. `functools.reduce`) | **[DONE phiên 3-4]** was MISSING at snapshot time | `stdlib_functional.py`; `f` scoped to named function/declared `func`-typed variable, no bare inline lambda |
| `isinstance()`/`type()`/`issubclass()` | medium, `BasicOfPythonProgramming.md`/`Python Tutorial.md` | **[DONE phien 5]** compile-time constant-folded (no runtime check, consistent with static typing): `isinstance`/`issubclass` emit `ldc.i4.0/1`, `type(obj)` emits `ldstr` of the dtype/record name. Scalar (`int`/`float`/`str`) via `TypeAnn.dtype`; record via `record_bases` walk (reuses Phase 3.1 inheritance infra) | `il_features/typecheck.py` |
| `open()`/`with` context managers | high, all books except ML book | COVERED | `file_io.py`, `with_open` in `control_flow.py` |
| `namedtuple`, `Counter`, `defaultdict` (`collections`) | medium, `BasicOfPythonProgramming.md`/`Python Tutorial.md` dedicated subsections — **missed by prior list entirely** | **[DONE, xác nhận lại phiên 5]** was ❌ MISSING at snapshot time (doc lỗi thời) — `namedtuple` via real `namedtuple("Name",[...])` syntax (`_extract_namedtuple_def`, `tkv_compile.py`), `Counter`/`defaultdict` via `counter_type.py` | `tkv_compile.py`, `il_features/counter_type.py`; test `namedtuple_test.tkv`/`counter_test.tkv`/`defaultdict_test.tkv` |
| `math.*` core (sqrt/floor/ceil/log/pow/trig) | high, esp. ML book and `PythonPrograming.md` | COVERED | `_MATH_FUNCS` — 18 functions, see §2b |
| `math.pi`/`math.e`/`atan2`/`gcd`/`factorial`/`hypot` | medium, `BasicOfPythonProgramming.md`/`HowtocodeinPython3.md` | ❌ MISSING | confirmed absent, see §2b |
| `random.choice`/`randint`/`random` | high, esp. ML book and `Python Tutorial.md` | **PARTIAL** — 3 of ~7 common functions present, see §2b | `stdlib_random.py`: `random()`, `randint`, `choice` found; `shuffle`/`sample`/`uniform`/`seed` absent |
| `re.match`/`search`/`sub`/`findall` | medium, `Python Tutorial.md` | **PARTIAL** — 2 of ~7 present, see §2b | `stdlib_re.py`: `re_match`, `re_sub` found; `search`/`findall`/`split`/`compile`/`fullmatch` absent |
| `os.path.join`/`os.listdir`/`os.getcwd` | medium, `Python Tutorial.md` | **PARTIAL** — see §2b | `stdlib_os.py` (3 funcs) + `stdlib_path.py` (4 funcs); `os.getcwd`/`os.chdir`/`os.system` absent |
| `json.dumps`/`json.loads` | medium, `Python Tutorial.md` | PARTIAL | flat `json_dumps`/`json_parse`/`json_get_*`, no dotted syntax, two parallel implementations (`stdlib_json.py` vs `stdlib_cjson.py`) worth reconciling |
| `datetime.now`/`.strftime`/`timedelta` | low-medium, `BasicOfPythonProgramming.md`/`Python Tutorial.md` | **[DONE phien 5]** real `datetime`/`timedelta` dtype, `.strftime()`, `strptime`, `timedelta_*`, `datetime_add`/`sub`/`diff` | `il_features/datetime_type.py` |
| `itertools.chain`/`product`/etc. | low-moderate, `Python Tutorial.md` mentions only | ❌ MISSING (0 real itertools functions) | `stdlib_itertools.py` only implements `enumerate`/`zip` for-macros |
| `sys.argv`/`sys.path`/`sys.exit` | medium, `Python Tutorial.md`/`HowtocodeinPython3.md`/`BasicOfPythonProgramming.md` — **missed by prior list entirely** | ❌ MISSING | no `sys` module support found in `compiler/` |
| `logging` module | high in `HowtocodeinPython3.md` (dedicated chapter) — **missed by prior list, book-specific but real** | **[DONE phien 5]** free functions by level (`log_debug/info/warning/error/critical(msg)` + `log_set_level(n)`), no logger/handler/formatter objects. Prints `<LEVEL>:root:<msg>` matching `logging.basicConfig()` default; default threshold WARNING=30 (real Python numeric values) | `il_features/logging_feature.py` |
| `pdb`/debugging | high in `HowtocodeinPython3.md` (dedicated chapter) | N/A | tooling feature, not a compiled-program-facing language feature — out of scope |
| decorators / `@property`/`@staticmethod`/`@classmethod` | medium, present as a construct in `BasicOfPythonProgramming.md` (memo/zope examples), `Python Tutorial.md` glossary | `@property`/`@staticmethod` **DONE** (prior); custom `@deco` on top-level functions **[DONE phien 5]** (scoped: no args, exact signature match); `@classmethod` still MISSING | `tkv_compile.py`'s `_expand_custom_decorator` |
| `async def`/`await` | low, only glossary-level mentions in `Python Tutorial.md`, none in other 4 books | ❌ MISSING | not found |
| type hints/annotations (`typing.List`/`Tuple`/`Callable`) | medium, ML book uses them throughout its function signatures | N/A — TokenVector already has its own type-annotation system (`-> "i32"` etc.) by design | not a gap, different mechanism achieving the same end |
| `match`/`case`, walrus `:=` | not present in any of the 5 books (all predate or don't cover these) | N/A | correctly out of scope — no book demand for them |
| tuple packing/unpacking, multiple assignment, swap idiom | high, all 5 books | COVERED | `tuple_type.py` |
| `*args`/`**kwargs` variadic function params | high, `BasicOfPythonProgramming.md`/`Python Tutorial.md`/`HowtocodeinPython3.md` dedicated sections | **UNVERIFIED** — not confirmed present or absent in this pass; flagged for next session | needs direct check |
| docstrings | medium, most books | N/A | documentation-only, not a runtime feature gap |
| turtle graphics module | high in `BasicOfPythonProgramming.md` (entire case-study chapter) — niche, low reuse value | ❌ MISSING | not found, low priority (GUI/graphics, narrow book-specific demand) |
| pickle module | medium, `BasicOfPythonProgramming.md` dedicated section | **[DONE phien 5]** scalar-only round-trip: `pickle_dump_i32/i64/f64/str(v, path)` / `pickle_load_X(path)->X`, via `BinaryWriter`/`BinaryReader` with a self-defined binary format (not CPython's real pickle bytes — round-trip is only guaranteed within the same runtime). No list/dict/record support | `il_features/pickle_feature.py` |

## 4. Prioritized gap list (highest book-frequency-across-5-books first)

*(Frozen as of the original 2026-08-11 snapshot; items 1, 2, 4, 6 are now DONE — see the
status note at the top of this file and `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` for
current state. Left as originally written below for the historical record of the
prioritization reasoning.)*

1. **`.format()` string method + `%`-style formatting** — `.format()` has a full dedicated
   chapter in `HowtocodeinPython3.md` plus usage in `BasicOfPythonProgramming.md`; `%`
   formatting is the *dominant* string-formatting idiom in the ML book and has a dedicated
   section in `BasicOfPythonProgramming.md`. Two related, frequently-taught features,
   both entirely missing. **Highest priority — the prior pass under-ranked `.format()`
   and completely missed `%`-formatting.** — **[DONE phiên 2]**
2. **`class` inheritance / `super()` / `@property`** — OOP chapters appear in 3 of 5 books
   (`BasicOfPythonProgramming.md`, `HowtocodeinPython3.md`, ML book's model classes).
   `record_feature.py` only supports flat records — large usability gap. — **[DONE phiên 4]**
   note: `@property` itself turned out to already be present at snapshot time (this item's
   original framing was inaccurate on that one sub-point); the real gap closed in phiên 4
   was inheritance/`super()`.
3. **`try/except/finally/raise`** — re-verified as **already COVERED**
   (`control_flow.py:1081-1106`), contrary to the prior pass's "likely MISSING" claim.
   Drop from the active gap list; instead, next session should write regression tests
   confirming exact semantics (custom exception types? multiple `except` clauses?
   re-raise?) since presence was confirmed but exact surface wasn't stress-tested.
4. **`map()`/`filter()`/`reduce()`** — dedicated sections in `BasicOfPythonProgramming.md`;
   `reduce()` specifically was missed by the prior 70-feature list. All three missing.
   — **[DONE phiên 3-4]**, scoped: `f` must be a named function or declared `func`-typed
   variable, not a bare inline lambda (see plan doc for the reasoning).
5. **`enumerate()`/`zip()` as general expressions** — re-verified as **PARTIAL, not fully
   MISSING**: both work as `for`-header macros already (`stdlib_itertools.py:22,41`), but
   not as standalone expressions (`list(enumerate(x))`, `zip(a,b,c)` for 3+ lists).
   Extending the existing macro to a real expression form is a smaller lift than the prior
   pass's "not found anywhere" framing suggested. `zip` for-header itself widened to N-ary
   in phiên 2 (Phase 2.1); standalone-expression form is still open.
6. **`lambda`** — re-verified as **PARTIAL, not fully MISSING**: already parsed
   (`il_core.py:270-295`) and consumed in restricted contexts (`il_codegen.py:1296`).
   Next step is widening scope to general first-class closures, not building from zero.
   — **[DONE phiên 2-4]**: free-variable capture (phiên 2, Phase 2.4), then storable/
   reassignable/re-invocable via variables (phiên 4, Phase 3.3).
7. **`collections` module (`namedtuple`, `Counter`, `defaultdict`)** — dedicated
   subsections in `BasicOfPythonProgramming.md`/`Python Tutorial.md`. **Entirely missed by
   the prior pass's feature list.** Medium-high value, medium-large scope. — **STILL OPEN**
   (Phase 3.2, user chose "new built-in type" over "syntax sugar on record/dict"; not yet
   coded as of phiên 4).
8. **2-arg `.find(sub,start)`, `.strip(chars)`, `.replace(old,new,count)`** — each
   individually low-cost, each already flagged as a known limitation in
   `docs/BUGS_TODO.md`. Bundle as one modular task.
9. **`.update()` (dict), `.clear()` (list), `divmod()`, `sys.argv`/`sys.path`/`sys.exit`** —
   all appear with medium frequency across 2-3 books and were **missed entirely by the
   prior pass's ~70-feature checklist**. Individually small, worth a batch pass.
10. **`random.*`/`re.*`/`itertools.*`/`os.path.*` exact surface** — **now fully enumerated
    (§2b), no longer "unverified."** Concretely: `random` has 3/7 common functions
    (missing shuffle/sample/uniform/seed/randrange), `re` has 2/7 (missing
    search/findall/split/compile/fullmatch), `itertools` has 0 real functions
    (enumerate/zip are for-macros only, not itertools), `os.path` has 4/6
    (missing splitext/isfile/isdir/abspath/normpath). Each individually small; `random`
    and `re` gaps have the highest book-frequency and should go first.
11. ~~**`isinstance()`/`type()`/`issubclass()`**~~ — DONE, phiên 5.
12. ~~**`datetime` full object model**~~ — DONE, phiên 5.
13. ~~**`decorators`/`async def`/`await`**~~ — DONE, phiên 5 (both async/await
    and scoped custom decorators; scope decision reversed after user clarified
    TokenVector's goal is Python replacement, not just teaching — see comparison
    row above for the exact scoping).
14. ~~**`pickle`, `logging`**~~ — DONE, phiên 5 (scoped: logging is level-based
    free functions, pickle is scalar-only round-trip). **`turtle`, `pdb`** still
    deferred — `pdb` is near-meaningless for a program compiled to a static exe
    (no REPL/interactive runtime); `turtle` would need its own GUI canvas.

## 5. Suggested next-session plan (small modular tasks, "chia để trị")

*(Frozen as originally written; items 1-3, 6, 8, 9 (partial), 10, 12 are DONE — see
`docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` for what actually shipped, which diverged in
naming/grouping from this original sketch as real design decisions were made per-item.)*

1. `string_format.py` — `.format()` (positional/keyword args, index reorder, basic
   conversion codes) as a `STR_METHODS_EXTRA3`-style entry. Self-contained, testable.
   — **[DONE phiên 2]** (keyword args explicitly out of scope, see plan doc)
2. `string_percent_format.py` — `%`-style string formatting operator (`"%s" % x`,
   `"%.2f" % x`). Distinct feature from `.format()`, separate scoped task.
   — **[DONE phiên 2]**
3. `builtin_reduce_map_filter.py` — `functools.reduce`, `map()`, `filter()`; smallest
   scope if desugared to existing comprehension/loop machinery. — **[DONE phiên 3-4]**,
   shipped as `stdlib_functional.py`, NOT desugared (built on real delegate values instead,
   see Phase 3.3 in the plan doc — user chose the "first-class function values" route over
   desugaring when asked)
4. `builtin_enumerate_zip_expr.py` — widen the existing `for`-header
   `enumerate`/`zip` macros (`stdlib_itertools.py:22,41`) into standalone expression
   forms (`list(enumerate(x))`, `zip` for 3+ lists). Extends existing code, not new.
   — **PARTIAL**: `zip` widened to N-ary in the for-header (phiên 2, Phase 2.1);
   standalone-expression form for either still open.
5. `lambda_expr_widen.py` — widen existing lambda support (`il_core.py:270-295`,
   `il_codegen.py:1296`) from restricted-context to general first-class closures; reuse
   `closures.py` patterns. — **[DONE phiên 2-4]**
6. `stdlib_random_extend.py` — add `shuffle`, `sample`, `uniform`, `seed`, `randrange` to
   `stdlib_random.py` (3/7 → 7/7 common functions). — **PARTIAL [phiên 2]**: `uniform`/
   `randrange` done; `shuffle`/`sample`/`seed` explicitly deferred (need new
   void-statement dispatch / a persistent RNG engine design decision, see plan doc Phase
   1.3).
7. `stdlib_re_extend.py` — add `search`, `findall`, `split`, `compile`, `fullmatch` to
   `stdlib_re.py` (2/7 → 7/7). — **PARTIAL [phiên 2]**: `search`/`fullmatch` done;
   `findall`/`split`/`compile` deferred (need a `list<str>`/"compiled regex object"
   return-type design, see plan doc Phase 1.4).
8. `stdlib_path_extend.py` — add `splitext`, `isfile`, `isdir` to `stdlib_path.py`.
   — **PARTIAL [phiên 2]**: `isfile`/`isdir` done, `splitext` still open.
9. `dict_update.py` / `list_clear.py` / `math_extras.py` (`divmod`, `pi`, `e`, `gcd`) —
   small batch of individually-cheap, previously-unlisted gaps found this pass.
   — **PARTIAL [phiên 2]**: `dict.update`/`math.pi`/`math.e`/`math.gcd` done (`list.clear`
   turned out to already exist, false gap); `divmod()` still open.
10. `record_inheritance.py` (research + design spike, not full implementation) — decide
    whether `record_feature.py` should grow inheritance/`super()`/`@property`, per
    Zero-Assumptions policy — needs a design decision before code. — **[DONE phiên 4]**,
    user chose "full vtable + override"; turned out the `.tkv` self-hosted tree already had
    it, so it was a port rather than new design (see plan doc Phase 3.1).
11. `collections_module.py` (research + design spike) — scope `namedtuple`/`Counter`/
    `defaultdict` support; medium-large, needs its own planning pass. — **STILL OPEN**,
    user chose "new built-in type" (Phase 3.2), not yet coded.
12. ~~**Bug**: `datetime_ticks` returns a hash instead of real `.Ticks`~~ — already
    fixed in a prior commit (`3423ef5`), predates this doc's last accurate pass.
    — **[DONE phiên 2]** (Phase 0).

Item 13 from §4 (decorators/async/await) is DONE as of phiên 5 — see row above.
Item 14: pickle/logging DONE (phiên 5). turtle/pdb remain deferred (niche,
only attempted if requested again).

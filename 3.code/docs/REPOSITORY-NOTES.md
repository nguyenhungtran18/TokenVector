# TokenVector compiler — repository notes

This directory holds the TokenVector compiler source. It was brought under git
on **2026-09-27**. Until then the compiler existed only as files on disk, with
no version control at all, so any machine loss would have taken the compiler
and every fix made to it with it.

## Layout

| Path | Contents |
|---|---|
| `compiler/` | Compiler implementation. `.tkv` modules loaded by the bootstrap; `il_features/` holds the IL feature plugins (`operators.tkv`, `int_builtin.tkv`, `control_flow.tkv`, …). |
| `build_tkvc.ps1` | Builds the compiler with PyInstaller into `dist/`. |
| `tkv.tkv`, `tkv_compile.tkv`, `tokenvector_compile.tkv` | Compiler entry points and the `--class-name` / `--emit-il` CLI. |
| `Testkit/`, `test/`, `verify/`, `tools/` | Test suites. |
| `examples/`, `stdlib/`, `docs/` | Samples, runtime library, documentation. |
| `build/`, `dist/` | Build output. Ignored; recreated by `build_tkvc.ps1`. |

`.il` files are **tracked on purpose**. The `Testkit/*_regress.il` files are
golden baselines for regression tests, and `tools/*.il` are checked-in IL
samples. Only `*.exe`, `build/` and `dist/` are ignored.

## How to build

```powershell
cd D:\TokenVector\3.code
.\build_tkvc.ps1
```

That produces `dist\tkvc.exe` plus `dist\il_features\` (the plugin library it
loads at runtime — **not** junk, deleting it breaks the compiler).

The downstream `D:\TokenVector.Inference` project builds with
`dist\tkvc.exe`. Changing this compiler can therefore change the inference
project's output, so run its suite after every rebuild.

## `tkvc_patched.exe` was removed (2026-09-28)

There used to be a second compiler binary, `dist\tkvc_patched.exe`, plus a
PyInstaller onedir bundle `dist\tkvc_patched\`. Both are gone. The reason is
worth recording, because the arrangement was actively dangerous:

- **No build script ever produced `tkvc_patched.exe`.** `build_tkvc.ps1` only
  builds `tkvc`. The file existed solely because a human had once run
  `Copy-Item dist\tkvc.exe dist\tkvc_patched.exe -Force` (the old step in
  this document). So after any rebuild, `dist\tkvc.exe` was fresh while
  `dist\tkvc_patched.exe` silently kept the *old* bytes — and Inference, whose
  build script defaulted to that path, kept compiling against a stale
  compiler while looking perfectly healthy.
- **The two names were the same program.** They were byte-identical (same
  SHA256) and, because `plugin_loader.discover_plugin_dir()` resolves
  `il_features/` *next to the running exe*, both loaded the single
  `dist\il_features\` directory. Nine point eight megabytes of exact
  duplication with no behavioural difference — measured, 59/59 Testkit cases
  passing identically for each.
- **The onedir bundle was a genuinely older compiler.** It carried its own
  frozen `il_features\` copy that had drifted from `compiler/il_features/`
  (four files differing, plus a `list_pop.tkv` that no longer exists), and it
  failed a test the current compiler passes: building
  `Testkit/iterator_protocol_test.tkv` died with
  `UnboundLocalError: cannot access local variable 'ta'` in
  `il_codegen.py::declare_scalar`.

All 17 references to the old path (2 `.ps1` defaults, 15 documentation
lines) in `D:\TokenVector.Inference` were repointed to `dist\tkvc.exe`. If
you ever see `tkvc_patched` referenced again, that is a stale copy of a stale
document — the name no longer exists.

## Fixes made in this initial commit

These were developed against the `D:\TokenVector.Inference` test suite and are
the reason the compiler needed version control.

### `compiler/il_features/operators.tkv` — match opcode and operand width

The arithmetic branch selected its opcode from `operand_dtype` (inferred from
the two operands) but compiled the operands with `dtype` (the call-site
context). When the two disagreed, `mul.ovf` — the checked **integer** multiply —
was emitted on float32 operands, producing IL the runtime cannot execute:

```
ldc.r4 0.0
ldloc.s 6
ldloc.s 8
mul.ovf
call ... _td_f32_repeat(float32, int64)
```

The branch now widens to i64 when the two integer widths genuinely differ, and
leaves the existing path untouched otherwise. Widening unconditionally was
tried first and regressed two passing tests (`awq_asym_and_fp16`,
`resize_nearest_einsum`), so the narrow form is deliberate.

### `compiler/il_features/int_builtin.tkv` — honour `int()`'s call-site dtype

`int()` ignored the `dtype` argument and always emitted `conv.i4`, pushing an
`int32` where `List<int64>::Add` requires an `int64`. It now emits `conv.i8`
when the call site wants i64 and keeps `conv.i4` otherwise.

## `int()` parse 64-bit — gap B3 (2026-09-28)

`int("2147483648")` emitted `Int32.Parse` and died with a raw .NET
`OverflowException: Value was either too large or too small for an Int32`,
even though the surrounding code never asked for an `int32`. It was the last
unmet half of UI `UPSTREAM_REQUIREMENTS.md` R6 ("i64 literal/typeflow +
`int()` 64-bit"); the literal and typeflow halves already worked.

**Where the fix went, and why not somewhere more obvious.** The obvious fix —
make the string branch always call `Int64.Parse` — was rejected. `int()` is
registered with return dtype `i32`, and that dtype drives locals, `divmod`,
`range`, and list element inference across the whole language. Widening it
globally is exactly the blast radius the existing `int64()` builtin was added
to avoid (see the R6 note in `push_int64_builtin`).

So the fix is at the **inference** layer, and only fires on information that is
already certain at compile time:

- `_int_return_dtype` is registered as `return_dtype_fn` for `int`. It returns
  `'i32'` by default — identical to today's behaviour — and `'i64'` **only**
  when the argument is a string *literal* whose value provably exceeds int32.
- `push_int_builtin`'s string branch then emits `Int64.Parse` for that case.
- When the call site explicitly pins the result to `i32`, the extra
  `conv.ovf.i4` keeps the stack correctly typed. Without it,
  `_widen_if_needed` does nothing for i64→i32 (it is deliberately a
  widening-only helper), which would push an `int64` into an `int32` slot and
  reproduce the exact `BadImageFormatException` documented in that function.

**Blast radius: one construct.** `int("5")` still emits `Int32.Parse`.
Verified unchanged by `Testkit/i64_int_test.tkv` (16/16), which pins
`i32max`, `i32min`, and the plain-integer path.

### What is still deliberately not changed

`int(s)` where `s` is a **variable** is not a literal, so the compiler cannot
know its value and keeps `Int32.Parse`. For a variable string above 2³¹ use
`int64(s)`, which already worked. Widening that case would mean guessing at
runtime, and the alternative — silently truncating — would be a correctness
bug rather than a feature.

Two gotchas found while doing this, both worth knowing:

- A `str_lit` node's payload **still carries its quotes** (`node[1]` is fed
  straight to `ldstr`). `int('"2147483648"')` is a `ValueError`, so a helper
  that forgets to strip them silently reports "fits in int32".
- `EXPR_BUILTIN_NATIVE_INT` already neutralises widening for `int` in a `int`
  (TkvInt) context, so returning `'i64'` from the dtype function cannot corrupt
  the arbitrary-precision path.

## `.maxstack`: over-estimating, and a separate branch-depth defect

`il_codegen.tkv::_max_stack_for` originally counted only the arguments of
`call` / `callvirt` / `newobj`, plus a constant 8, ignoring stack
interactions entirely. Long method bodies therefore got a `.maxstack` far below
what they need: `_expand_lstm` in the inference test assembly declared 20
against a real peak depth of 439, and the CLR rejected it at JIT time.

Fixed on 2026-09-26 by adding `_stack_lines_upper_bound(body)`, which sums a
per-instruction upper bound. It is deliberately an **over**-estimate — the
same docstring argues that a high ceiling is much safer than a low one. The
gap is wide: `_expand_lstm` now declares 1343 against a measured peak of 437.
This is harmless, just loose; the real point of the change is that the
under-estimate class of failure is gone.

It does not, however, fix `_expand_lstm`. That method has a **second and
independent** defect: forward branches reach a merge label carrying a
different stack depth than recorded on the first pass, which the runtime
rejects with
`InvalidProgramException: Common Language Runtime detected an invalid program`.
The exe surfaces that to the caller as `BadImageFormatException`.

Measured on `_expand_lstm`, three such branch mismatches remain, two of them
consistently off by exactly 2 slots — the signature of a loop, where the
back-edge and the entry point disagree about what is on the stack. The
suspect is loop codegen in `control_flow.tkv` (`codegen_for` / `codegen_if`),
not the arithmetic path. This is the open item to fix; do not re-investigate
maxstack first, it has already been ruled out by measurement.

## Diagnosing "invalid program" — use PrepareMethod, not MethodHandle

`MethodHandle` is **not** evidence that a method compiles; obtaining one only
materialises a handle. This cost a long detour during the 2026-09-27 session,
where `MethodHandle` succeeded for every method and led to ruling out method
body size, local variable types and call targets — all wrongly.

The correct check is:

```csharp
RuntimeHelpers.PrepareMethod(m.MethodHandle);
```

which raises `InvalidProgramException` for genuinely invalid IL. A throw-away
probe built for this lives outside the repo; rebuilding it is a few minutes of
C#. Run it after any compiler change instead of inferring validity from
assembly load, from `MethodHandle`, or from a decompiler's notes — ILSpy
reported 880 notes across this assembly, most in methods that run fine.

## R7 native `i64` for counters/indices — and two latent IL bugs it exposed (2026-09-28)

`compiler/il_features/int_narrow.tkv` keeps provably-small integer locals as
native `int64` instead of `int` (a boxed `TkvInt`, which costs ~50 IL
instructions per `+ - *` because every step range-checks the `BigInteger`
tail). `matmul32` went 21965 us -> 4336 us (5.1x) and `add` 8373 us -> 1462 us
(5.7x) against the pre-R7 baseline, checksums unchanged.

Enabling it surfaced two **pre-existing** defects that had been silent because
ilasm does not verify operand types and the JIT tolerated the bad IL.

### 1. `conv.*` emitted on an object reference

`operators.tkv::_widen_expr_to` treated `int` as a scalar and emitted
`conv.r8` for it. But `int` is a 16-byte `TkvInt` **struct** — what sits on
the stack is an object pointer, so `conv.r8` reinterpreted a pointer as a
`double` and popped the reference without disposal. Silent garbage.
`int` must go through `TkvInt::ToF64` / `ToI32` / `ToI64`, exactly as
`_widen_if_needed` already did.

The same shape appeared via `_widen_if_needed`'s new `i32 -> i64` branch.
In `_slice_shape` (Inference):

```python
for _qx1064 in range(min(len(starts), len(shape))):
    _qx1021.append(_qx1064)
axes = _qx1021          # `axes` is a `list[i64]` parameter
```

`for`-loop counters are inferred `i32`, not `int`, so `_qx1021` was built as
`List<int32>` and assigned to a `List<int64>` slot. `List<int32>` and
`List<int64>` are different generic arguments; the compiler emitted
`conv.i8` **on the list reference**, truncating the pointer to 32 bits. Before
R7 no conversion was emitted at all, and reading element 0 of
`List<int32>[0,1,2]` as 8 bytes yields `0x0000000100000000` = 4294967296 —
which then became the index `shape[...]`. `ilasm` assembled it, the JIT ran
it, and the test passed on a corrupt value.

Fix: `int_narrow` now also collects `for x in range(...)` targets, and
`control_flow.tkv::declare_scalar_int` (which `fpw_for` calls, bypassing
`declare_scalar` in `il_codegen`) declares them `i64`. `i32 -> i64` is a
widening, so it is always lossless.

### 2. Consequences for the two index paths

- `il_core.emit_index_scalar` needs a narrowing step for `i64`:
  `conv.ovf.i4`. .NET's `get_Item`/`get_Chars` take `int32`. Without it an
  `int64` is passed straight into an `int32` parameter.
- `il_codegen._compile_index_store` must route through `emit_index_scalar`
  rather than compiling the index at `'i32'` directly, so both `'int'`
  (`TkvInt::ToI32`) and `'i64'` (`conv.ovf.i4`) narrow in one place.

`conv.ovf.i4` throws on an out-of-range index, which is what made defect 1
visible instead of silent. That is the intended behaviour: the project rule
is "no silent divergence" — trade a compile error for a loud runtime one.

### Debug switches

`TKV_NO_INT_NARROW`, `TKV_NO_WIDEN_I64`, `TKV_NO_IDXSTORE`, `TKV_NO_VBUF` and
`TKV_DBG_NARROW` gate the R7 pieces individually, so a regression can be
bisected without rebuilding `tkvc.exe`. Note `int_narrow.tkv` is a LIBRARY
plugin loaded at run time from `dist/il_features/`, so edits to it alone can be
tested by copying the file across — no PyInstaller rebuild required.

Post-fix: Testkit 61/61, Inference 26/26, gap tests PASS.

## The correctness gate was blind to summation order (2026-09-28)

While scoping the `f32x4`/`Vector4` work I checked what the benchmark
checksums can actually detect. `run.py` compares the TokenVector line to the
CPython line with **exact string equality**:

```python
match = (tv_out == py_out) and bool(tv_out)
```

and `k_matmul32.tkv` fills its inputs with `(i % 7) - 3` and `(i % 5) - 2`, so
every partial product and sum is an integer of magnitude <= 192. Verified with
exact rational arithmetic:

```
matmul32 f64 == exact (rational)?  True
max |C| = 10   -> < 2^53, every operation exact
checksum sum = 1.0
```

So the matmul checksum **cannot detect a change in summation order** — which is
precisely and only what SIMD would change. The gate was not wrong, it was
silent on one axis. Anything built on it would have looked green.

`k_f32mm.tkv` + `py_ref_f32.py` close that hole: `list[f32]`, inputs
`(i % 97) * 0.1` (inexact in binary32), a real `kk` reduction, and four
**per-element** probes (`r[0]`, `r[7]`, `r[500]`, `r[1023]`). Per-element is
load-bearing — on the *sum* the relative error is only 2.3e-08, because the sum
(460039) dwarfs each element's rounding error (~3e-05), so a sum-level check is
far too weak to catch anything.

Measured separation, so the tolerance is chosen from data rather than taste:

| | rel-err | tolerance 1e-5 |
|---|---|---|
| correct kernel | 8e-10 … 1.3e-07 | PASS |
| one term dropped | 1.8e-02 … 4.5e-02 | FAIL, 3–4 orders over |

That is the licence for tolerating reassociation: a real bug overshoots the
tolerance by 3–4 orders of magnitude, so the gate keeps its power.

## SIMD scoping, measured rather than assumed (2026-09-28)

`System.Numerics.Vector4` is **not** in mscorlib on .NET Framework 4.8 — it is
in `System.Numerics.dll`, the same assembly `complex` already uses, so it adds
no dependency and the standalone PE is unaffected. `System.Numerics.Vector<T>`
is **absent** on CLR 4.x, so **f64 cannot be vectorized there at all**.

CLR 4.x *does* lower `Vector4` to hardware (it is a long-standing JIT intrinsic
type, unlike `Vector<T>`). Measured on the real CLR 4.x runtime, f32 32x32,
true 16-byte load via pointer:

| | net48 (CLR 4.x) | .NET 8 |
|---|---|---|
| f32 + `Vector4`, in-box | **2.69x** | 2.67x |
| f32 + `Vector<T>`, 8-wide | absent | 4.58x |
| f64, any width | absent | `Vector<double>` |

So no retarget is needed for f32 SIMD. f64 would need .NET 8; real inference is
f32, so that is off the critical path.

Three plausible-sounding ideas were measured and **rejected**:

- 4 independent accumulators (break the dependency chain): **1.00x**. The loop
  is not latency-bound.
- Transposing/packing B to make the dot product contiguous: **1.10x**.
- Relying on the JIT auto-vectorizer: it does **not** fire. `DOTNET_JitDisasm`
  shows `ymm=0` for both a canonical dot-product loop and a rank-1 elementwise
  loop; only the explicit `Vector256` version emits `vmulps`/`vaddps` and `ymm`.

An earlier reading of the same probe was wrong and is worth recording: the
elementwise kernel was reporting 0.017 ns/MAC because the harness divided its
1024 MACs by 32768. Correct value is ~0.56 ns/MAC, i.e. scalar. Likewise, a
first net48 attempt reported `Vector4` as 4.4x *slower* — that was allocation
inside the loop, not `Vector4`; with a true vector load it is 2.69x faster.

## `v_hsum4` — the first step where float semantics move (2026-09-28)

Horizontal sum of a `Vector4`, and the first operation whose result differs
from a scalar loop. It is **not** a rounding-level change, which was the open
question at P0 when the tolerance was chosen.

### Summation order chosen: sequential, not pairwise

`v_hsum4` emits `((X+Y)+Z)+W`, not `(X+Y)+(Z+W)`. A scalar loop adds its last
four terms in that same sequential order, so this reproduces it exactly: the
summation order changes **only between the four independent accumulators**,
which is inherent to SIMD, and nowhere else. Pairwise would have changed both
and bought no extra speed — same four adds, same four field reads.

### Measured: the reassociation is more accurate, not less

On the `f32mm` benchmark, four parallel accumulators plus one horizontal sum at
the end, against an exact f64 reference:

| probe | vector f32x4 | scalar f32 | f64 exact | vec rel-err | scalar rel-err |
|---|---|---|---|---|---|
| p0 | 153.929992676 | 153.930010000 | 153.930000357 | 4.99e-08 | 6.27e-08 |
| p1 | 155.805999756 | 155.805980000 | 155.806000033 | 1.78e-09 | 1.29e-07 |
| p2 | 264.557983398 | 264.558000000 | 264.558002110 | 7.07e-08 | 7.98e-09 |
| p3 | 362.879974365 | 362.880000000 | 362.880000289 | 7.14e-08 | 7.96e-10 |

The vector path is **closer** to exact on three of four probes, and well inside
the 1e-5 envelope with ~140x margin. Shorter dependency chains, as expected for
blocked summation.

### 1.54x on matmul, not 5.89x — and why

`v_load4`/`v_store4` gave 5.89x on elementwise f32. A 4-wide 32x32 f32 matmul
gives **1.54x** (843.62 -> 547.95 us per matmul, same 4 matmuls both sides,
startup subtracted). The gap is the horizontal sum: one `v_hsum4` per output,
1024 per matmul, each 12 serial instructions (stloc + 4x (ldloca, ldfld) +
3x add) against 8 vector iterations. That is roughly a quarter of the inner
work. Elementwise has no reduction and so keeps the full width.

Also required: **B must be packed by column** (`pt[j*n+k] = b[k*n+j]`). A scalar
matmul reads `b[kk*n + j]`, a column, so its stride is n and no single 16-byte
load can serve it. This is a correctness requirement, not an optimisation — and
getting it wrong is silent, see below.

### Two silent bugs, both found by the gates rather than by reading

1. **`add` emitted after every lane load.** `stloc; ldloca; ldfld X; add; ...`
   puts `add` on a stack holding one operand, so the method is
   `InvalidProgramException` at run time. `add` belongs *between* two loads.
   Only reading the emitted IL made the placement visible.
2. **Loading B by row instead of column.** The first vector matmul returned
   rel-err ~0.5 against exact — a wrong-value failure, not rounding, and it
   would have looked like "SIMD is inaccurate" rather than "the kernel indexes
   the wrong axis". The 1e-5 tolerance caught it instantly; a checksum that
   only compared sums would not have.

Neither would have been caught by a runtime test alone. The IL assertion counts
`ldfld ::X` and `stloc.s __v4hsum` so a regression in the shape is visible.

## P5: matmul f32 4-lane as a gated artifact (2026-09-28)

`Testkit/vector4_matmul_test.tkv` — a full 32x32 f32 matmul on `f32x4`,
self-verifying inside the compiler's own gate, so the whole stack is shown to
compose into a real algorithm rather than a probe. It computes the same product
twice, once scalar-sequential and once 4-lane, and compares **all 1024 outputs**
rather than a few probes.

```
worst rel-err = 1.6990120463073473e-07 tai phan tu 962
ALL PASS vector4_matmul_test (7 checks)
```

That is 59x inside the 1e-5 tolerance, and consistent with P4: the 4-lane path
is not merely inside the envelope, it is slightly *closer* to exact.

### The gate has teeth, checked both ways

Three assertions compare `pt` (the column-packed copy of B) against `pb` (B as
given) at three index positions. They exist because the first attempt at this
kernel packed B by **row** and returned rel-err ~0.5 — a wrong-value failure
that reads as "SIMD is inaccurate" rather than "the kernel indexes the wrong
axis". Re-injecting that specific mistake:

```
worst rel-err = 0.8581535906379357 tai phan tu 106
FAIL mm4 lan toi da 1024 phan tu: rel=0.8581536 > 1e-05
FAIL r[0]: rel=0.5263302 > 1e-05
```

Source restored and verified by SHA-256. Note that comparing only the *sum*
would not have caught either version: the sums moved by only 0.3%.

### Tracked in the standard benchmark gate

`run.py` now carries `f32mm` (scalar) and `f32mm_vec` (4-lane) side by side, so
the SIMD payoff is a tracked number rather than a one-off measurement:

| kernel | us | worst rel-err |
|---|---|---|
| `f32mm` scalar | 818.0 | 1.29e-07 |
| `f32mm_vec` 4-lane | 571.4 | 7.14e-08 |

The IL for the vector inner loop is 2 `ldobj` + 1 `op_Multiply` + 1
`op_Addition` per iteration — one instruction each for four MACs.

Testkit 63/63, Inference 26/26, gap PASS, Data gate PASS, all seven benchmark
kernels within tolerance.

## P6 scoping: there is no opt-in flag, and auto-vectorising is feasible (2026-09-28)

### First, a correction to the plan

The plan said "P7: enable the fast path by default, flip `TKV_SIMD` to 1". No
such flag was ever created. Verified by grep: `f32x4` has no gate, and the only
environment switches in the compiler are the R7 debugging ones
(`TKV_NO_INT_NARROW`, `TKV_NO_IDXSTORE`, `TKV_NO_VBUF`), which *disable*
features rather than opt into them.

So the `f32x4` work is purely additive and **already always on** - there is
nothing to flip, and the primitives are available to every program today.
Reporting "P6 enabled the fast path" would be false. What P6 can actually mean
is: make the compiler emit `f32x4` **by itself**, for loops the programmer
wrote as plain scalar code.

### Feasibility: the pattern is mechanically recognisable

A plain elementwise loop - the way a user would actually write it, with no
`f32x4` anywhere:

```python
i = 0
while i < half:
    r[i] = a[i] + b[i]
    i = i + 1
```

compiles to exactly 15 IL instructions:

```
ldloc.s r
ldloc.s i
ldloc.s a ; ldloc.s i ; conv.ovf.i4 ; callvirt get_Item
ldloc.s b ; ldloc.s i ; conv.ovf.i4 ; callvirt get_Item
add
callvirt set_Item
ldloc.s i ; ldc.i8 1 ; add.ovf ; stloc.s i ; br
```

The shape needed for recognition is narrow and syntactic:

- exactly one induction variable, i64, unit stride, incremented by a literal 1
- exactly one store, `r[i] = expr`, where every `get_Item` in `expr` uses that
  **same** variable, unmodified
- no other loop-carried state, no early exit, no aliasing between the lists

No dependence analysis is required, because R7 already proved the increment
overflow-free (`add.ovf` on an i64 counter) and normalised the index to i64.

The rewrite is then mechanical: drop the loop, emit a `Vector4` loop over
`v_load4`/`v_store4` with stride 1, and keep the original scalar loop for the
`n % 4` tail.

### Why it is safe, and what the gate must prove

Elementwise operations are **bit-exact** regardless of lane count - there is no
summation, so there is nothing to reassociate. That is what separates this from
the reduction case: auto-vectorising a `sum += a[i]` would need the 1e-5
tolerance and is a different decision. Restricting P6 to elementwise keeps it
bit-exact and therefore keeps every existing checksum unchanged, which is the
property the whole gate is built on.

A safe implementation must still show, not assume, that:

- a deliberately wrong transform (e.g. stride 2 instead of 1) turns the
  benchmarks red - same negative test used for the checksum gate and for
  `v_hsum4`
- Testkit, Inference, gap and Data all stay green with **default** settings
- the emitted IL actually contains `ldobj`/`stobj` per four elements and that
  the scalar tail is present (assert with tools/assert_il.ps1)

### Honest cost, stated before doing it

This is the first change in the whole R7 line that would alter the numerics of
code that does not mention `f32x4`. Everything so far is additive: a new dtype,
new builtins, and an opt-out-free but purely additional surface. Automatic
vectorisation removes work from existing code paths, so a mistake here is silent
and global rather than local to the new feature. That is why it is the step the
plan flags as highest risk, and why this entry records the pattern and the
safety argument rather than the code.

Not implemented in this commit. The measured payoff of the target shape is
already known - 5.89x on elementwise f32 (P3), 1.43x on a 32x32 f32 matmul (P5)
- so the opportunity is quantified and the design is unambiguous; what remains
is the implementation, which should land as its own commit with the negative
test above built in from the start.

## Known gap: the self-hosted compiler has no `yield from` (2026-09-28)

Found while rebuilding `dist/tkvc.exe` from the working tree to run the gate.
`Testkit/native_test_suite.tkv` does not build with `tkvc.exe`:

    il_codegen: con thua token khong parse duoc sau bieu thuc: 'sub_numbers'
    (trong 'from sub_numbers()')

That is `native_test_suite.tkv:175`, `yield from sub_numbers()` inside the
generator `main_numbers()`. Minimal repro, same compiler:

    def g() -> "list[i32]":          # compiles and runs
        yield 1
        yield 2

    def g() -> "list[i32]":          # fails
        yield 1
        yield from h()

Plain `yield` works. `yield from` is not handled: `tkv_compile.tkv` has no
YIELDFROM case at all, and the failure surfaces as a confusing parse error
about leftover tokens rather than an unsupported-feature message.

Why this is pre-existing and why it was invisible: the compiler sources are a
Python subset. `build_tkvc.ps1` copies each `.tkv` to a same-named `.py` and
ships those to PyInstaller, and the Python path understands `yield from` -
`compiler/il_codegen.tkv:400-411` uses it repeatedly. The self-hosted
TokenVector transpiler at the repo root is the one that lacks it. So the same
file is valid for the packaging path and invalid for the shipped compiler, and
nothing in the 63-file gate ever loads `native_test_suite.tkv` (the gate globs
`*_test.tkv`; this file is named `native_test_suite.tkv`), so 63/63 stayed
green while this file could not build.

Consequences for anyone picking it up: implementing it means extending the
generator state machine in `tkv_compile.tkv` to delegate to a second iterator
(MoveNext/Current feeding the same yield path), and it cannot be validated by
the very suite it blocks - `native_test_suite.tkv` is the 16-case language
suite plus the `check_file` static analyser, and it is the only file that
would exercise the feature. Worth doing, but it is a feature, not a cleanup,
so it is recorded rather than half-implemented.

Also fixed here: `__init__` in that file declared `def __init__(self, name)`
with no annotation, which the linter rejects, so it could not build even
before `yield from` was reached. Annotated `name: "str"`, per the project
rule that function parameters always carry their type. The other unannotated
`__init__` parameters in the tree (99 of them, mostly in `tkvcalc*`,
`_tkv_arbiter` and the compiler's own parser) are reachable only through the
packaging path or not at all, and are left alone.

## `raise <bien>` (2026-09-28)

Dung xong va da gate: `Testkit/raise_var_test.tkv` 7/7. Phan biet parser chi la
dau hau khoi `(` - `raise X(...)` co, `raise e` khong. Codegen nap bien roi
`throw`; kieu THAT kiem o bien dich, dung chung quy tac voi tham so cua
`raise ... from`, nen `raise <so>` bi tu choi luc bien dich thay vi box roi nem
luc chay.

Ca hai dong nay **da ton tai** va phai giữ:

- `raise <record tu dinh nghia>(...)` **ep** tham so kieu `str` (duong dan raise
  ep `dtype='str'` khi bien dich bieu thuc tham so). nen record loi cua nguoi
  dung phai co field `str`; neu khai field `i32` thi sinh `.ctor(String)` ma
  record khong co, va exe chet luc chay voi
  `MissingMethodException: Void MyErr..ctor(System.String)`.
- Do do, `raise <record> from <bien>` **hong san** o HEAD: codegen phat
  `.ctor(String, Exception)`, ma record chi co `.ctor` khai trong `__init__`.
  Comment trong `codegen_raise` kiem nhan "record tu dinh nghia ke thua Exception"
  co san ctor nay la **sai** - chi cac class trong `_EXC_TYPE_MAP` moi co.
  Chua sua: dung `raise X(msg) from e` voi class builtin.

## `try/except/else` (2026-09-28)

Dung xong va da gate: `Testkit/try_except_else_test.tkv` 10/10. Xem "Buoc 3" o
`PLAN.md` cho so do nhan. Hai diem can nho khi sua tiep:

- Thuan `else` (khong `finally`) duoc sinh NGOAI vung `.try`, nen `break`/
  `continue` trong no chay binh thuong. Co `finally` thi thuan `else` phai
  sinh BEN TRONG `.try` cua finally de finally van chay sau no - va luc do
  `break`/continue bi tu choi, vi `codegen_break` phat `br` THUAN (khong phai
  `leave`), ma CIL cam `br` thoat khoi vung bao vuc. `try_depth` hien chi duoc
  dung o `codegen_return`, chua dung o `break`/`continue` - day la ly do phai
  chan o parser thay vi lai sua `codegen_break`.
- `try/finally` co them `else`, va `try/else` khong co `except`, deu khong hop
  le trong Python nen bi pre-flight linter (`syntax_baseline.py`, goi `ast.parse`)
  tu choi TRUOC khi parser cua compiler kip thay. Hai guard trong `try_parse_try`
  chi la phong thu cho duong `--no-lint`.
  Linter nem ra traceback thay vi thong bao dep, nhung do la hanh vi chung cua
  moi dang sai cu phap Python, khong rieng `try/else`.

## `else` cua `for` / `while` (2026-09-28)

Dung xong, gate 15/15, doi chieu CPython 3.11 khop het ca o vong lap long nhau.
Xem "Buoc 4" o `PLAN.md` cho ly do bo co `did_break`.

Mot diem can nho khi sua tiep: `else` cua vong lap **khac** `else` cua `try` o
nghia do doc:

- `try/except/else` - `else` bi BO QUA khi co handler bat duoc loi.
- `for/else` va `while/else` - `else` bi BO QUA khi gap `break`. `continue`
  khong bo qua `else`.

Hai chung deu la "chay khi khong co gi chan duong chon nhanh nay", nhung dieu
kien phai chan la hai thu khac nhau. Hay nham hai cai la rat de viet sai test.

`for x in <list>` chay qua macro `for_in_list` o `try_expand_for_in_list`, ma
macro chi ghi lai DONG `for`, dong `else:` goc van nguyen tai cho - nen khong
can sua macro. Rieng `for x in <record>` thi phai sua tay trong
`codegen_for_in_iter`, vi no khong qua macro (macro "buoc qua" neu container la
bien record, xem `_known_record_vars` trong `try_expand_for_in_list`).

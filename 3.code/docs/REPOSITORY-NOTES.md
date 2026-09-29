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

## Comprehension: tai sao `PLAN.md` sai ve dict comprehension (2026-09-28)

`PLAN.md` 4b xep "Dict comprehension" vao *can thiet ke*, kem ghi chu "list
comprehension co; dict can duong ghi khac". **Sai.** Kiem lai thi
`try_expand_dict_or_set_comp` trong `il_features/comprehension.py` da co san tu
truoc va chay dung - `d = {x: x * x for x in range(4)}` ra ket qua dung ngay tu
truoc phien nay. Tieu chi bi chan o PRE-FLIGHT LINTER
(`syntax_baseline.tkv` -> `_collect_exempt_comprehensions`), voi dieu kien
`len(generators) == 1`.

Day la loai sai nguy hiem hon loai "chua lam": danh sach gap khai bao mot tinh
nang **da chay**, nen nguoi doc tuong tin la no chua lam. Da giu lai tu do
nay bang `Testkit/comprehension_multi_for_test.tkv` (17/17) - co ca cac dang
1 `for` va dang `.items()` da co san truoc, de khong ai xoa nham di.

Tu do sua tieu chi cua linter: cho N generator, va bo `len(ifs) > 1` trong
`_comp_generator_ok`. Macro `parse_comprehension_inner` sua cung luc -
sai mot co, khac mot thì linter va macro lech nhau, va loi se hiện ra o mot
cho ma kho doan.

Gioi han con lai cua comprehension KHONG phai giới han cua tính năng ma là gioi
han cua *shape* ma macro khop duoc. No deu dung o linter va deu ro rang:
- phai là RHS duy nhất của gán cho **tên đơn**: `out = [...]`, không phải
  `f({...})`
- phai nằm trên **một dòng vật lý** (`_LIST_COMP_OUTER_RE`/`_DICT_COMP_OUTER_RE`
  là `^...$`, không `DOTALL`); linter kiem bang `end_lineno`
- target nhiều biến chi danh cho dict-comp tren `.items()`

## Slice co buoc `a[i:j:k]` (2026-09-28)

Xong, gate 16/16, 8 ca list doi chieu CPython 3.11 khop het. Xem "Buoc 6" o
`PLAN.md`.

`ast.Num` da bi **XOA** tu Python 3.12, may nay chay 3.14. Neu dung no trong
`syntax_baseline.tkv` thi ca pre-flight linter chet bang `AttributeError`, va
`tkvc.exe` nem traceback thay vi in thong bao linter - trieu chung nhin KHONG
giong loi cu phap ma rat kho doan. Dung `ast.Constant`.

Mot loi khac cung dung loai nao, nen ghi lai: `infer_scope` la `_DtypeOnlyScope`,
co `__getitem__` va thuoc tinh `._d`, **khong co** `.get()`. Goi `.get()` se
AttributeError.

Pham vi: chi buoc DUONG. `a[::-1]` bi `visit_Slice` chan truoc khi bien dich bat
dau. Ly do khong lam: doi chieu so sanh, sua moc am, sua dieu kien thoat - nhieu
truong hop de sai hon la sinh IL sai. Neu sau nay lam, phai sua ca ba, va
phai khoa bang test kiem tra bien am (vd `a[5:0:-2]` -> [4, 2]).

## Set literal `{1, 2, 3}` (2026-09-28)

Xong, gate 13/13. Xac nhan truoc khi lam: **`{` khong co trong tokenizer**
(nhom `OP` trong `il_core.py` chi co `[`, `]`) nen truoc day bao loi
"khong tokenize duoc bieu thuc". Phai sua 5 noi: tokenizer, parser, codegen,
first-pass, linter. Uoc luong "re" luc dau cua toi SAI.

**'{}' la DICT RONG va da ho tro san.** Nhanh parser cua toi nem loi o `{}` va
lam hong ngay 4 test (`identity`, `dict_update`, `comprehension_multi_for`,
`record_contains`). Sai o cho: duong gop `d = {}` chay qua khop VAN BAN
(`try_rhs_dict_new`, regex) chu khong can node, nhung van co duong nao do
goi `parse_expr` va cham nhanh `{`. Da doi thanh tra node rong de duong gop di
tiep. Bai hoc chung: **trong nguoi nhay `{}` thi phai hoi "co phai dang gi
khac khong" truoc khi bao loi**.

Phan biet set/dict bang dau ':' sau phan tu dau: `{1, 2}` la set,
`{"a": 1}` la dict (van chua ho tro, parser bao loi rieng cho no).

**Da viet EXPR_CODEGEN cho dang inline roi BO.** Ly do: moi duong tieu thu mot
set literal inline deu bi chan boi han che CO SAN khac -
`len({1,2,3})` bao "khong suy duoc hinh dang cua bieu thuc", va
`2 in {1,2,3}` bao "`in` chi ho tro ... 1 bien dict/set/list/chuoi don".
Khong test duoc nen bo thay vi giu code khong toi duong. Neu sau nay `len`/
`in` chap nhan bieu thuc, day la cho can mo lai.

## DUYET SET BI HONG - loi co san, khong phai hoi quy (2026-09-28)

`for v in s:` bi viet lai boi macro `for_in_list` thanh
`for i in range(len(s)): v = s[i]`, ma set KHONG lay duoc theo chi so (giong
Python). Loi: "'s[...]' - 's' la set, ma set KHONG lay duoc theo chi so".

Da kiem tra de khong nhan nham: `s = set()` + `.add()` roi `for v in s:` cung
 loi y het, nen day la han che cua MOC set trong macro, khong phai cua set
literal moi them. Chua sua - macro `for_in_list` dung chung cho list/dict/set,
va sua no la viec rieng, can bo test rieng cho ca 3 container.

## Duyet set `for v in s:` (2026-09-28)

Xong, gate 11/11. Sua duoc phep: macro `for_in_list` viet mac dinh
`for i in range(len(s)): v = s[i]`, ma HashSet<T> khong co indexer.

Sua bang cach chuyen sang list roi lap, dung `s.to_list()` da co san
(`set_to_list.tkv` - file do sinh ra CHINH vi file nay, va ghi ro "VI SAO
CAN: 'for x in <set>:' KHONG chay duoc"). Khong viet duong lap rieng tren
Enumerator cua HashSet: phai code valuetype/Enumerator moi, lap 1 lan.

Can them `_known_set_vars` + `set_known_set_vars()` (cung co che
`_known_dict_vars`/`_known_record_vars`) va quet truoc 3 nguon: `s = set()`,
`s = {...}`, va `s = <ham tra ve set>()`, cong tham so ham kieu set.

**Bai hoc: `sig.params` la list PARAM OBJECT, khong phai list tuple.** Unpack
`for name, ta in sig.params` se TypeError lam hong **MOI file** (gate 0/77) -
khac het loi cua tung test. Phai dung `p.name` / `p.type_ann`.

## Set literal + tham so ham: `container_arg_hints` (2026-09-28)

Khi lam set literal, thu truyen cho tham so `set[i32]` bi
`OverflowException` luc CHAY (khong phai luc bien dich). Khac phai "duyet
set hong" - ma la **duong goi** phat `TkvInt::ToI32` tren CHINH con set thay
vi tren phan tu, vi kieu khai bao lech.

Nguyen nhan: `declare_set` (tu `.add()`) xet `container_arg_hints` TRUOC khi
suy kieu, `declare_set_literal` (cua toi) thi KHONG. Hai duong phai cho ra
CUNG kieu cho cung gia tri - `s = set(); s.add(1)` va `s = {1}` phai giong nhau.
Da them buoc do. Khong thi nhieu loi "bien dich OK, chay thi no" ma
khong co thong bao nao tro toi khai bao kieu.

## CONG VIEC CHUA LAM: set lam tham so `__init__` (2026-09-28)

`class C: def __init__(self, s: "set[i64]")` roi `C(t)` - hong. Da kiem tra
de khong nham la hoi quy cua set literal: `t = set(); t.add(1)` cung hong y
het. Nguyen nhan: `_container_arg_hints` (il_codegen.py) khong duoc nap cho
VI TRI GOI CONSTRUCTOR, chi nap cho loi goi ham thuong.

Hien tai: set truyen cho HAM THUONG chay; cho `__init__` cua lop thi hong.
Bai test dung ham thuong de tranh vung nay. Sua la viec rieng - phai nap
`container_arg_hints` cho constructor record, va can test ca 3 container.

## Field container tren record: tu choi, thay vi hong im lang (2026-09-29)

Da chan o `tkv_compile.tkv`'s `_extract_record_def` (ngay canh cac
`raise TranspileError` cho field khong hop le) - day la noi DUY NHAT sinh ra
`records[name]`, nen cha 1 lan la moi noi khac deu thay do.

Ba bieu hien truoc khi chan, KHONG cai nao bao loi bien dich:
  1. `self.items = [1,2,3]` trong `__init__` -> `len(c.items) == 0`
  2. `c.items[0]` -> OverflowException luc CHAY
  3. container lam tham so `__init__` roi `C(t)` -> OverflowException; call
     site con `TkvInt::ToI32` tren CHINH con container

Goc rau: tham so `.ctor` cua record lay tu FIELD (khong phai tu chu ky
`__init__` - cai do bi bo qua luc bien dich) va container bi LOC BO khoi danh
sach do. Comment o `il_codegen.tkv:5566` noi y "khoi tao rong ben trong .ctor,
dung nhu `__init__` that viet `self.items = []`" - nhung chinh duong ghi do cung
khong stick.

Da quet 216 file `.tkv` de chac chan khong pha gi: KHONG record TokenVector nao
khai field container. `SyntaxFinding` trong `syntax_baseline.tkv` KHONG phai
record - no la dataclass Python thuan co gia tri mac dinh (`Optional[str] = None`),
va file do ship thanh `.py` chu khong transpile (traceback xac nhan:
`File "compiler\syntax_baseline.py"`).

**Bai hoc nho ve cat chuoi:** kiem tra container bang `dtype[:5] in ('list[',
'dict[', 'set[')` - `'set['` dai **4** ky tu, nen `set[i64]` khong bao gio khop
va loi cham nham vao nhanh "record can N tham so" sai thay vi thong bao dung.
Dung `startswith`.

**Gioi han cua cong kiem tra — doc truoc khi them check.** Cong BAT BUOC moi file
test build duoc (`BUILDFAIL` la that bai). File test chua class co field
container de chung minh bi chan thi CHINH no khong build. Vi vay
`Testkit/record_container_field_test.tkv` chi kiem **khong chan nham** (moi kieu
field scalar van chay: i32/str/f64, doc trong bieu thuc, so sanh, cong); phan
"bi chan" duoc chung minh bang 3 probe tach rieng. KHONG duoc them
`check("bi tu choi", "1", "1")` vao do - do la kiem tra rong.

## Dict literal `d = {"a": 1}` (2026-09-29)

Xong, gate 16/16. Nua con lai cua cu phap `{...}` (set literal lam ngay truoc).
`il_core.py` sinh node `dict_literal` (danh sach cap khoa/gia tri);
`dict_type.py` sinh `Dictionary<K,V>::.ctor()` roi `set_Item` tung cap - dung
CHUNG idiom voi `_compile_index_store` (il_codegen.tkv) nen khong phat lai chu ky
IL nao. Tuong ung het voi set literal: chi dang `ten_don = {...}` tren MOT dong.

Hai loi parse da gap, ca hai deu "trong nhe" va deu bat duoc ngay vi test tung
dung:
1. Vong lap kiem `,` TRUOC khi xu ly cap DAU TIEN, nen thoat ngay roi
   `expect_op('}')` gap `:`. Loi nay khong bao gi o dau - chi hien ra khi
   bien dich ca file.
2. Quen TIEU THU dau ':' sau khoa dau tien, nen `parse_expr` cho gia tri bat
   dau tai `:` va bao "khong parse duoc factor tai OP ':'". Phai `advance()`
   qua `:` truoc khi parse gia tri.

`{}` van tra node rong de duong gop `d = {}` di tiep (khong nem loi) - da co
case hoi quy trong test.

Khoa trung lap: gia tri CUOI CUNG thang, dung het Python va het `set_Item`
cua .NET.

## `f32buf` - substrate do duan so huu cho P6 (2026-09-29, P6 buoc 1)

P6 (tu dong vector hoa) **khong chay tren `List[f32]`**, va ly do da ghi san
o dau `vector4_type.tkv` (muc "SUBSTRATE: CON TRO THO, KHONG PHAI
`List<T>._items"`): `v_load4`/`v_store4` doc 16 byte LIEN TIEP, nen can DIA CHI
mot vung bo nho lien tiep. Lay dia chi phan tu `List<T>` phai cham field private
`_items` cua BCL - **da bi tu choi co chu dich**: (a) `_items` khong phai API hop
dong, khong co gi dam bao o runtime dot nao khac, (b) TokenVector chua co tien le
nao cham field private cua BCL. Grep toan compiler: khong co `ldelema`, `Unsafe`,
`fixed`, `GCHandle` nao.

Ghi chu kha thi o REPOSITORY-NOTES ("P6 scoping") noi "ban viet lai thi co
mechanic" — **do chi dung khi cac toan hang da nam san trong bo dem native**.
Kernel `bench/k_f32mm_vec.tkv` dang chay duoc doc `v_load4` sau khi CHEP du
vao `alloc_bytes`, va comment noi ro chuyen sang doc HANG de lay dia chi la sai
ket qua hoan toan (rel-err ~0.5), khong phai lech lam tron. Vong lap elementwise
ma nguoi dung that su viet — tren `List[f32]` — **khong dien dat du dieu kien do**.

Vi vay `f32buf`: bo dem f32 native ma DUAN so huu. Kieu la `('f32','f32buf')`
(shape moi, dung co che `('str','strbuf')` / `('i32','bytearray')` co san), gia
tri la dia chi `native int`, chieu dai luu o local AN dinh theo TEN bien
(`__f32buf_<ten>_len`) vi `IntPtr` tu AllocHGlobal khong mang kich thuoc.

Chi DUNG THAO TAC: `f32buf(n)`, `a[i]`, `a[i] = v`, `len(a)`. Khong `.append`,
khong cat, khong duyet, khong `in`, khong long nhau. Do la chu dich - be mat
nho hon la im lang lam sai.

Hai lan dat nhanh SAI trong luc lam (ca hai cung do la khop sai ham):
- Nhanh ghi `a[i] = v` dat vao `_expr_index_expr` thay vi `_compile_index_store`.
- Nhanh doc `a[i]` dat vao `_expr_index_expr` thay vi `_expr_index` (doc bang
  bien TRAN di qua `_expr_index`; `_expr_index_expr` la cho co so la BIEU THUC).
Ca hai lan deu lo ra bang thong bao chung "chi ho tro mang rank 1 hoac 2" - KHONG
chi ra rang container la gi, nen phai kiem bang thu doc cach binary de tim ham
that, khong phai tin thong bao.

## P6 bước 2: tự động vector hóa vòng lặp trên `f32buf` (2026-09-29)

`_p6_vectorize_while` (trong `compiler/il_features/control_flow.tkv`, gọi từ
`codegen_while` TRƯỚC khi phát vòng lặp vô hùa) nhận diện MỘT DẠNG vòng lặp:

```
n = <giá trị>
i = 0
while i < n:
    r[i] = a[i] + b[i]
    i = i + 1
```

rồi biên dịch thành: vòng lặp bước 4 (`v_load4` nạp, `v_store4` ghi, 16 byte
một lần) + đuôi scalar cho `n % 4` phần tử còn lại. Biến đếm `i` kết thúc ở `n`
y hệt bản gốc nên code sau vòng lặp không nhìn thấy khác biệt gì.

**Nguyên tắc: có BẤT KỲ nghi ngờ nào thì KHÔNG vector hóa.** Biến đổi này sửa
SỐ HỌC của code mà không hề nhắc tới vector — một lỗi sai sẽ không có triệu
chứng gì. Đó là lý do P6 chẩn đoán bằng cách thử biên dịch rồi so sánh IL, chứ
không phải bằng cách sinh ra rồi kiểm tra kết quả.

Điều kiện CHẤP NHẬN (trượt hết đều trả về False → chạy scalar):
- điều kiện là `iv < n` với cả hai là **biến** (không phải hằng số)
- thân **đúng hai** câu lệnh: 1 `idx_assign` + 1 `i = i + 1`
- `r` là biến `f32buf`; mọi `r[i]` trong vế phải dùng **chung** `iv`
- vế phải chỉ gồm `+ - * /`, và **mọi lá phải là `v_load4`**

Hai giới hạn cần biết:
- **Hằng số trong vế phải bị từ chối** (`a[i] * 1.5`). `_expr_num` từ chối mọi
  dtype trừ `f32x4` (không có lệnh `ldc` nào sinh được một vector), và chưa có
  intrinsic `v_set4` để broadcast. Muốn hỗ trợ: thêm `v_set4` trước.
- **`f32buf` chưa dùng được làm tham số/giá trị trả về** (P6 bước 1 chỉ tạo ở
  local nên đúng), nên mỗi trường hợp test phải nối thẳng vòng lặp thay vì gọi
  hàm.

### Bài học khi chẩn đoán (cả 3 đều tồn tại trong codebase)

1. **Node hằng số lưu dạng CHUỖI: `('num', '1')`, KHÔNG phải `('num', 1)`.**
   Parser giữ hằng số nguyên nguyên văn bản vì số có thể vượt int64. Một số
   nơi sinh node bằng int thực nên đã dùng idiom "chấp cả 3 dạng" (xem
   `list_pop.tkv`). Đây là nguyên nhân gốc của việc recognizer trả False ở khi
   mọi điều kiện đều có vẻ đúng. `_p6_num_val` là hàm hóa giải.
   Tương ứng: `_is_float_literal` (`il_core.py`) làm `'.' in text` nên node
   `('num', 4)` (int) sẽ ném `TypeError` chứ không phải báo lỗi đẹp.
2. **Cache PyInstaller bị bẩn sẽ làm `dist/tkvc.exe` hỏng giữ nguyên hình dạng.**
   `ModuleNotFoundError: No module named 'il_features.X'` lúc build, trong khi
   staging có đúng file. Xóa `build/pyinstaller/tkvc` (thư mục `.toc` của
   PyInstaller) rồi build lại. `build/pyinstaller_src` KHÔNG đủ — nó chỉ là
   staging do biên dịch sinh ra.
3. **Kiểm tra kết quả ĐÚNG không chứng minh transform CÓ chạy.** Test ban đầu
   cho ra đúng toàn bộ giá trị ở `n=8` nhưng vector hóa chưa bao giờ chạy —
   nó chỉ chạy đường scalar. Phải kiểm tra **IL** (`stobj`/`ldobj`, nhãn
   `_vstart`) chứ không kiểm tra kết quả. Ngoại ra cảnh báo: `while i < 8` có
   biên lại là hằng số nên không khớp mẫu — phải truyền `n` qua tham số mới thử
   được.

Gate: `Testkit/p6_vectorize_test.tkv` 16/16, toàn bộ **82/82**. Đã đối chiếu
bit-exact với CPython trên 13 độ dài × 3 phép (0, 1, 2, 3, 4, 5, 7, 8, 9, 15,
16, 17, 33).

## P6 bước 3: mutation test + phát hiện gate KHÔNG bắt được test fail (2026-09-29)

Bước này nhằm trả lời: *làm sao biết transform P6 thật sự đúng, chứ không chỉ
ra kết quả đúng?* Cách làm là cố tình phá transform rồi xem gate có đỏ không.

### Hai lỗi của acceptance gate (tồn tại từ lâu, không phải do P6)

1. **Regex soát FAIL sai định dạng.** Gate tìm `\[FAIL\]`, nhưng `check()` trong
   `tkv_test_lib.tkv` in `FAIL <tên> got=... expected=...` — không có ngoặc vuông.
   Regex cũ **không khớp dòng nào**, nên mọi test thật bại vẫn được tính PASS.
2. **`run()` trả mã thoát nhưng exe không truyền ra exit code.** Docstring của
   `test_summary` nói rõ "dùng làm exit code của chương trình", nhưng entry của
   exe bỏ qua giá trị trả về, nên `$rc` luôn bằng 0 và nhánh `EXIT$rc` cũng không
   bao giờ chạy.

Hai lỗi **độc lập cùng hướng**, nên gate về cơ bản chỉ phát hiện được build fail
và timeout. Hệ quả: `input_py_tree_test` và `path_isfile_isdir_test` **luôn fail**
nhưng báo xanh suốt. Nguyên nhân là của *harness*, không phải của test:
- `input_py_tree_test` cần stdin, gate không cấp stdin.
- `path_isfile_isdir_test` hỏi đường dẫn tương đối, exe lại chạy ở thư mục con.

Đã sửa cả ba: nhận diện FAIL theo định dạng thật + dòng tổng kết `A/B PASS`
(A ≠ B là fail), cấp stdin cho test cần, và chạy **mọi** exe với
`-WorkingDirectory Testkit` để test tương đối luôn đúng chỗ.

### Kết quả mutation test

| Mutation | Kết quả chạy | Gate cũ | Gate mới |
|---|---|---|---|
| Tắt hẳn transform (`return False` ngay đầu) | 82/82 test vẫn PASS — kết quả **đúng** vì chạy đường scalar | PASS | **ILFAIL**, exit 1 |
| Bỏ đuôi scalar (`br end` thay vì vòng tail) | `n=1,2,3` toàn `-999.0` | **PASS** (không thấy) | **TESTFAIL**, exit 1 |

Dong thu hai **lọt qua gate cũ**. Nguyên nhân rất đáng nhớ:

**Bộ đệm `f32buf` cấp phát bằng `Marshal.AllocHGlobal` nên vùng nhớ CHƯA KHỞI
TẠO, và bộ phân phối thường trả lại đúng khối cũ.** Khi transform bỏ sót phần tử
cuối, phần tử đó giữ giá trị của lần chạy trước — mà lần chạy trước lại là phép
tính đúng — nên kết quả vẫn **khả dụng** và test vẫn xanh. Sửa: mọi test giờ
tiền vào `r` bằng `-999.0` (không thể nào là kết quả đúng của phép cộng/nhân),
nên phần tử nào transform không ghi thì lộ ra ngay.

Bài học chung: **test của biến đổi sinh học phải tiên vào dữ liệu bằng giá trị
loại trừ**, nếu không "sai âm thầm" sẽ tự ngụy trang thành "đúng".

### Vì sao cần assert IL, không chỉ kiểm kết quả

Mutation "tắt hẳn transform" cho ra kết quả **hoàn toàn đúng** ở mọi test. Không
có gì ngoài IL phân biệt được "đã vector hóa" với "chưa vector hóa". Vì vậy
`testkit_gate.ps1` có thêm pha `IL ASSERTIONS`: build lại test có `--emit-il` rồi
đòi `.il` phải chứa `stobj` (v_store4), `_vstart` và `_tstart` (nhãn vòng vector
và nhãn đuôi scalar). Giá trị hiện tại của `p6_vectorize_test.tkv`: `stobj` ×3
(`add_case`, `chain_case`, `copy_case`; `mul_case`/`div_case` có hằng số nên bị từ
chối đúng chủ đích), `_vstart` ×6, `_tstart` ×6.

## P6 bước 4: đo hiệu quả — tăng tốc thật nhưng chỉ ~1.4–2.1×, không phải 4× (2026-09-29)

### Cách đo

Không nhồi P6 vào bảng của `run.py`. Ở đây câu hỏi là *"compiler biên dịch vòng
lặp này nhanh hơn bao nhiêu"*, tức so **chính compiler với chính nó** — chạy
một phép cộng trong Python làm mốc thứ phẩm không thêm gì vào hiệu quả đo
được, chỉ làm chậm bản đo.

Hai kernel `bench/k_p6_vec.tkv` và `bench/k_p6_scalar.tkv` **giống hệt nhau** —
cùng dữ liệu, cùng phép tính, cùng số lần lặp — và chỉ khác ở **điều kiện vòng
lặp**:

| | điều kiện | P6 |
|---|---|---|
| `k_p6_vec.tkv` | `while i < nb` (biến) | vector hóa |
| `k_p6_scalar.tkv` | `while i < 262144` (hằng số) | từ chối, chạy scalar |

Chênh lệch thời gian đó ra công **đúng hiệu quả của P6**: cùng thuật toán, cùng
bộ đệm, cùng dữ liệu, cùng compiler.

`bench/p6_bench.py` tự kiểm chứng hai điều trước khi in số, vì cả hai đều có
thể làm phép đo thành vô nghĩa mà không ai nhận ra:

1. **IL phải khác nhau**: bản vector có `stobj`/`_vstart`, bản scalar thì không.
   Nếu compiler bắt đầu rút gọn hằng số thành biến, hai bản trùng nhau và phép
   đo hết ý nghĩa. Đây cũng là cách bảo đảm bản "scalar" thật sự chạy scalar.
2. **Checksum phải giống nhau** — tức hai bản thống nhất về mặt số học.

### Kết quả

```
N         reps      công việc      scalar    tự động   tăng tốc
4096      4000      16.4M           13.3ms     8.2ms      1.62x
16384     1000      16.4M           12.9ms     7.4ms      1.74x
65536     400       26.2M           22.0ms    16.1ms      1.36x
262144    60        15.7M           15.8ms    11.0ms      1.44x
```

Các lần chạy lặp cho tăng tốc tốt nhất trong khoảng **1.6–2.1×** (đo có nhiễu
thực tế), và **~1.4×** khi bộ đệm lớn. Tập 3 bộ đệm đi từ 48 KB (vừa L2) tới
3 MB (vượt L2).

**Có một cái bẫy đo lý trong hàng này:** lần đo đầu tiên với `N=4096` cho
**0.81× — tức bản vector chậm hơn**. Đó là sai số do trừ startup (~25 ms) khi
thời gian đo chỉ ~2 ms. Tăng số lần lặp lên để công việc thật lấn át chi phí
cố định thì con số thật là 1.6–1.9×. Bài học: ở kernel chạy vài ms, phép trừ
startup không đáng tin; hãy chọn số lần lặp để tổng công việc ≥ 15M phép.

### Vì sao không đạt 4× (đếm từ IL, không phải đoán)

Vòng vector sinh **42 lệnh IL cho mỗi 4 phần tử**. Trong đó:

- **20 lệnh không làm phép tính nào** — chỉ tính địa chỉ byte cho 3 toán số
  (`a`, `b`, `r`). Mỗi toán số tốn 7 lệnh vì chỉ số là `TkvInt` (int64 có kiểm
  tra tràn) nên phải qua `conv.i4`, `conv.i8`, `mul.ovf`, `add`, `conv.i`.
- **~10 lệnh mới là việc thật**: 2 `ldobj`, 1 `op_Addition`, 1 `stobj`.

Tức công việc tính địa chỉ **đắt gấp hơn 2 lần** công việc vector. Đây là hạn
chẵn sẵn của P6, không phải lỗi.

### Bước tiếp theo đã định

Giữ một con trỏ byte tách riêng tăng 16 mỗi vòng lặp thay vì tính lại `i*4` ba
lần. Biến `i` vẫn phải giữ vì điều kiện thoát dùng nó, nhưng có thể hẹp về
`i32` trong khi đó — **phải canh giác** vì biến người dùng có thể lớn hơn
int32. Đây là việc đo đạt trước, không phải suy đoán: 20/42 lệnh là mục tiêu.

### Lưu ý về phạm vi

`p6_bench.py` cố ý **không** thêm vào `KERNELS` của `run.py`. Mốc CPython cho
kernel này sẽ tốn hàng chục giây mà không đóng góp gì cho câu hỏi đang đặt ra.
Bảng của `run.py` vẫn là bảng so sánh ngôn ngữ; phép đo hiệu quả biên dịch thuộc
về script riêng.

## P6 bước 5: vòng đời và giới hạn của `f32buf` (2026-09-29)

Hai hậu quả của việc dùng `Marshal.AllocHGlobal` đều đã xử lý.

### 1. Giới hạn — và tại sao phải dùng so sánh KHÔNG DẤU

`f32buf` là vùng nhớ thô: không có `get_Item` của BCL lo phần kiểm tra. Truy cập
ngoài vùng trước đây đọc/ghi địa chỉ bất kỳ — **không phải lỗi báo, mà làm hỏng
vùng nhớ khác**. Nay mọi lần truy cập đều kiểm tra `0 <= i < len`, ném
`IndexOutOfRangeException`.

Điểm mấu chốt: phải là `conv.u` + `blt.un` (**so sánh không dấu**), không phải
`blt` có dấu. Vì `len >= 0` luôn, `(uint)i < (uint)` đúng khi và chỉ khi
`0 <= i < len`. Nếu dùng `blt` có dấu thì `a[-1]` **lọt qua** (−1 < 4) và tính ra
địa chỉ *trước* vùng đệm — đọc nhầm vùng nhớ khác, không báo lỗi nào. Có test riêng
cho việc này.

### 2. Vòng đời — `f32buf_free(b)`

Bộ nhớ native không được GC theo dõi, nên bộ đệm sót lại đến hết tiến trình. Trong
vòng lặp tạo nhiều bộ đệm, đó là rò rỉ bộ nhớ thật.

Sau `f32buf_free(b)`, **cả con trỏ lẫn độ dài đều đặt về 0**. Đây là chủ đích, không
phải làm đẹp: mọi truy cập `b[i]` sau đó lọai ở kiểm tra giới hạn (`0 <= i < 0` sai
với mọi `i`) và ném `IndexOutOfRangeException` — tức *"dùng sau khi giải phóng"* biến
từ **cori memory** thành **lỗi sạch**. `FreeHGlobal(IntPtr.Zero)` là no-op nên gọi hai
lần cũng an toàn.

**Vì sao KHÔNG tự giải phóng khi ra khỏi hàm:** lambda có thể bắt bộ đệm, và bộ đệm
bị bắt sẽ sống lâu hơn hàm định nghĩa. Giải phóng tự động khi đó biến *rò rỉ bộ
nhớ* (phục hồi được) thành *dùng sau giải phóng* (lỗi nghiêm trọng, lỗi ngay).
Rò rỉ thì mất bộ nhớ; dùng sau giải phóng thì hỏng dữ liệu. Chọn cái nhẹ hơn.

### 3. Cái giá: +7 lệnh IL cho mỗi lần truy cập

Đếm từ IL thật, không phải ước lượng:

```
conv.i8 / dup / conv.u / ldloc <len> / conv.i8 / conv.u / blt.un <label>
```

**7 lệnh** trên đường không lỗi, cộng khối `throw` ở đường lạnh.

Hệ quả đo được, và cần nói thẳng:

| | scalar | vector | tăng tốc |
|---|---|---|---|
| trước khi thêm giới hạn | 13.3 ms | 8.2 ms | 1.62× |
| sau khi thêm giới hạn | 21.6 ms | 5.9 ms | 3.65× |

- **Vector gần như không đổi** (8.2 → 5.9 ms): vòng vector dùng `v_load4`/`v_store4`
  trực tiếp, không đi qua đường truy cập phần tử từng cái.
- **Scalar chậm lên ~62%**: đây là cái giá thật của việc luôn kiểm tra.

Và **tỷ lệ 3.65× này không so sánh được với 1.62× của lần trước** — cả hai đã đổi, và
mẫu số (scalar) đã chậm lên. Hiệu quả *riêng* của P6 vẫn là ~1.6–2.1× trên cùng mẫu
số. Muốn tách phần đóng góp của giới hạn thì so vector với scalar *cùng có* giới hạn —
đó mới là so sánh người dùng thật sự thấy.

Một điểm tích cực thật sự: vòng vector kiểm tra `(i+3) < len` **một lần cho cả 4 phần
tử**, còn vòng scalar kiểm tra 4 lần. Đây là cải thiện thuật toán hợp lệ, không phải
ngu nham: 4 phần tử đều trong khoảng, và chỉ số luôn bắt đầu từ 0 nên không thể âm.

Số đo ở đây **có nhiễu lớn giữa các lần chạy** (cùng một cấu hình cho 3.11× rồi
3.65×). Đừng trích con số đơn lẻ; hãy chạy lại `p6_bench.py` và nhìn cả dải.

### 4. Bẫy khi làm việc (đã mắc, đáng ghi lại)

- **Script sửa file bằng heredoc PowerShell là không đáng tin.** `\\n` bị ăn mất,
  dấu nháy kép bị ăn mất. Hai lần nó làm hỏng file nguồn. Sửa file bằng công cụ sửa
  có neo *duy nhất*, hoặc bằng script Python có **kiểm tra số lần xuất hiện = 1**
  trước khi ghi.
- **Công cụ sửa khớp MỜ.** Một lần nó khớp `if name == 'len':` ở *hàm khác* và chèn
  code sai chỗ, làm hỏng `il_codegen.tkv`. Sau đó `git checkout` xoá **cả** các sửa
  đổi đúng trong cùng file đó. Phải làm lại từ đầu, có kiểm tra.
- **`scope` của codegen là lớp `_Scope`, KHÔNG phải `dict`.** `scope.get(x)` trả
  `None` âm thầm thay vì ném lỗi. Phải dùng `scope[x]` trong `try/except`.
- **`FreeHGlobal` trả `void`** — không có gì trên stack để `pop`. Thêm `pop` làm IL
  mất cân bằng và sinh `InvalidProgramException` khi chạy, không phải khi build.
- **Cache PyInstaller bẩn** (`ModuleNotFoundError` khi build dù staging có file đúng):
  xoá `build/pyinstaller/tkvc`.

Gate: `Testkit/f32buf_bounds_free_test.tkv` 19/19, toàn bộ **83/83**.

## P6 bước 6: tối ưu địa chỉ trong vòng vector (2026-09-29)

P6-4 chỉ ra 20/42 lệnh IL của vòng vector chỉ dùng để tính địa chỉ byte cho
3 toán số. Sửa được phần lớn bằng một thay đổi **2 dòng** — và nó còn sửa luôn
một lỗi tiềm ẩn.

### Nguyên nhân: `_ofs_i32` hẹp rồi mở rộng ngay lập tức

`vector_block.tkv`'s `_addr` tính địa chỉ như sau:

```
compile p o i64
_ofs_i32(ofs)      <- OFFSET ve i32
conv.i8            <- roi MO RONG len i64
add
```

Và `_ofs_i32` làm: nếu offset có kiểu `i64` thì biên dịch ở i64 rồi **`conv.i4`**
(hẹp về 32 bit). Kết quả là `conv.i4` + `conv.i8` — **một vòng đi-vòng vô nghĩa**
trên một số vốn đã là i64. Hai lệnh thừa trên **mỗi** lần tính địa chỉ.

### Nó không chỉ thừa — nó **sai**

`conv.i4` **cắt cụt 32 bit cuối cùng**. Với offset byte ≥ 2^31 (buffer ≥ 512 MB),
`v_store4(p, 0x80000000, v)` trước đây:

```
0x80000000 --conv.i4--> 0x00000000 --conv.i8--> 0x00000000
```

tức **ghi vào đúng đầu bộ đệm** thay vì địa chỉ thật — đọc/ghi sai địa chỉ mà
không báo lỗi nào. Sau khi sửa, offset giữ nguyên và trỏ tới vùng nhớ không hợp
lệ, nên **AccessViolationException** — đúng như nó phải là. Xác minh bằng probe
`v_load4(p, 2147483648)`: trước đây trả về dữ liệu ở offset 0, nay báo lỗi.

Bài học: một `conv` trông "thừa" thường đang **che một phép kiểm tra sai**. Ở đây
nó không kiểm tra gì cả — nó chỉ làm hỏng dữ liệu.

### Kết quả

`_ofs_i32` → `_ofs_native`, biên dịch thẳng ở i64, bỏ `conv.i8` trong `_addr`.

- Vòng vector: **42 → 36 lệnh IL** cho 4 phần tử (−14%).
- Địa chỉ mỗi toán số: 8 → 6 lệnh.
- `conv.i4` và `conv.i8` trong vòng vector: **0**.
- Thời gian vector (N=4096): 8.2 ms (P6-4) → 5.4 ms (P6-5, có giới hạn) → 5.4 ms.
- Gate **83/83**, không hồi quy. Thay đổi này áp cho cả `v_load4`/`v_load8`/
  `v_store4`/`v_store8`.

### Phần CHƯA làm, và vì sao

Còn **6 lệnh trong 36** là do `i*4` bị tính **ba lần** cho ba toán số. Muốn bỏ
thì phải tính một lần rồi giữ trong một local tạm.

**Vướng:** `.locals` được sinh từ `locals_decl` **trước** khi dựng thân hàm
(`gen_il_function`, L5945→5971→5973), nên không thể khai local muộn từ recognizer.
Cần một `first_pass_walk` cho `while` chạy **cùng một** logic khớp mẫu ở first-pass
để khai local.

**Vì sao dừng lại:** hai bộ khớp mẫu phải khớp *đúng từng lệnh*, và lệch một chút
sẽ cho một trong hai hậu quả xấu. First-pass khớp mà codegen không → local thừa
(vô hại). Ngược lại, codegen dùng mà first-pass không khai → **local chưa khai báo
→ `InvalidProgramException` lúc chạy**. Có thể chặn được bằng cách codegen kiểm tra
`scope` trước khi dùng, nhưng đó là thêm một điều kiện phải giữ đúng.

Đổi lại: 6/36 lệnh (~17% vòng vector) trên một đường đã nhanh hơn scalar ~4×.
Tỷ lệ giá trị/chi phí không tốt so với thay đổi 2 dòng ở trên. **Nếu muốn làm tiếp
thì nên làm, nhưng là một việc riêng có kiểm thử riêng, không gộp vào đây.**

Hướng khi đã làm thì đơn giản: cho recognizer phát
`<off> = i*4; stloc <tmp>` một lần ở đầu vòng vector, rồi mỗi toán số chỉ cần
`ldloc <base>` + `ldloc <tmp>` + `add`. Biến `i` vẫn phải tăng 4 mỗi vòng vì điều
kiện thoát dùng nó.

## Conditional expression: dạng Python `a if c else b` (2026-09-29)

Quyết định: thêm **dạng Python**. Lý do hoá học bên dưới cho thấy hai dạng
**không đối xứng về chi phí**, nên "hỗ trợ cả hai" là lựa chọn sai.

### Hai dạng bị chặn ở hai tầng khác nhau

| dạng | parser riêng | thực ra chết ở đâu |
|---|---|---|
| `c ? a : b` | **đã làm được từ trước** | `tkv_compile.tkv:3854` |
| `a if c else b` | thiếu production | chính nó |

**`c ? a : b` không chết ở parser.** `il_core.tkv`'s `parse_ternary` đã hiện
thực đầy đủ, và `parse_expr("c ? a : b")` trả về đúng
`('ternary', ('var','c'), ('var','a'), ('var','b'))` khi gọi trực tiếp. Nó chết
sớm hơn: `_parse_program_ast` gọi **`ast.parse` của Python** ngay dòng đầu để
rút record, chữ ký hàm và hằng số module — mà Python không có `?:`. Thông báo
lỗi vì thế là `invalid syntax (<unknown>, line N)`, không phải lỗi của parser
TokenVector.

Nói cách khác: **xương sống của front-end là AST của Python.** Tháo nó ra thì
cả trích xuất record/signature/hằng số phải viết lại — không phải việc vá.

**`a if c else b` chỉ thiếu một production.** Toàn bộ phía sau đã có sẵn: temp
trong first-pass (`_walk_walrus_preorder`, L408), suy luận kiểu (L460/515/560),
`_expr_ternary` sinh IL (L3367). Thêm production là xong.

### Sửa kèm phát hiện: `_infer_literal_dtype` lọt điều kiện

`1.5 if c == 0 else 9.5` báo lỗi *"gán lại biến kểu 'int' bằng biểu thức chứa
số thực"*. Nguyên nhân: `_infer_literal_dtype` quét `node[1:]` để tìm hằng số
đầu tiên, nên gặp `0` trong **điều kiện** `c == 0` trước và trả `'int'`. Hằng số
trong điều kiện không đại diện cho kiểu *kết quả* — y hệt lý do chỉ số của
`slice` đã bị loại trước đây (L1360). Đã thêm nhánh `ternary` chỉ quét
`node[2]`/`node[3]`.

Đây là lỗi **tiềm ẩn có sẵn**: nó áp dụng y hệt cho dạng `?` — chỉ là dạng `?`
chưa bao giờ đi tới được tầng đó. Bật dạng Python ra là lộ ra.

### Tôi đã SAI một lần — và CPython bắt được

Sau khi có output đầu tiên, tôi thấy `so: 7 3` với `a=3, b=7, c=0` và tưởng
sai, vì mô hình nhớ của tôi là "`a if c else b` thì `c` đúng thì lấy `b`" — tức
đảo hai nhánh. Tôi đã sửa thành đảo. **Sửa đó làm sai hơn.**

Đối chiếu CPython cho thấy `a if 0 else b` ra `b`, `a if 1 else b` ra `a` —
tức **thứ tự nhánh của dạng Python giống hệt dạng `?`**, không đảo. Đã hoàn
tác. Nếu không có bước đối chiếu, tôi sẽ commit một compiler biên dịch đúng,
chạy không lỗi, và cho ra **kết quả sai**.

Bài học: với conditional expression, đừng suy luận từ trí nhớ — hãy hỏi
CPython. Nó rẻ hơn nhiều so với một bug âm thầm.

### Thông báo lỗi cũ đang chỉ sai

`parse_expr` từng bảo: *"có thể do dùng sai cú pháp ternary (DSL này dùng
`cond ? a : b`, KHÔNG phải `a if cond else b` kiểu Python)"* — tức **bảo dùng
đúng cái đang không dùng được**, và lại giữ dạng Python là thứ *đáng lẽ* phải
dùng. Đã viết lại: nêu hai nguyên nhân thiếu `else` / thiếu `:` **và** nói thẳng
rằng `?` không dùng được vì `ast.parse`.

### Kết quả

- Dạng Python hoạt động: số, float, chuỗi, index, bool chưa chuyển đổi, dùng
  giữa biểu thức, lồng 3 tầng. **16/16**, đối chiếu CPython từng dòng.
- Dạng `?` **vẫn không dùng được** — và giờ đã nói rõ vì sao.
- Gate **84/84**.

Muốn mở lại dạng `?` thì phải xử lý trước `_parse_program_ast`. Cách ít hại
nhất: một tiền xử lý **văn bản** chuyển `X ? Y : Z` thành `Y if X else Z`
trước khi gọi `ast.parse` — Python-valid và cùng nghĩa. Rủi ro: phải đặt đúng
ranh giới ba toán số khi `?`/`:` lồng nhau. Đó là việc riêng có kiểm thử riêng.

## Thử mở dạng `c ? a : b`: đi qua `ast.parse`, vướng lỗi temp — ĐÃ THOÁT (2026-09-29)

Đã làm được phần đầu rồi **dừng lại có chủ đích**. Ghi lại để không ai phải dò lại.

### Phần làm được

Tiền xử lý văn bản trong `tkv_compile.tkv` trước khi gọi `ast.parse`: đổi
`?` → ` if 0 else ` và dấu `:` tương ứng → `,`. `ast.parse` **không đánh giá**
nên không cần giữ nghĩa; chỉ cần parse được và giữ cấu trúc top-level (ternary
chỉ nằm trong thân hàm nên không đụng vào). Không chèn dòng mới nên `lineno` của
Python vẫn đúng cho các thông báo lỗi về sau.

Bộ quét có nhận biết chuỗi (`"..."`, `"""..."""`, thoát `\`), chú thích `#`, và
độ sâu ngoặc `[](){}` — nên `s = "a ? b : c"`, `a[1:2]`, `{"k": 1}` và chú thích
đều **không bị sửa**. Nhánh rỗng: nếu không có `?` thì trả về nguyên văn, nên
mọi file hiện có hành vi **giống hệt từng byte**. 11 ca thử đều đúng, gồm
lồng nhau `a ? b ? c : d : e` và `lst[a ? i : j]`.

Có một lỗi nhỏ tự thấy trong lúc test: ban đầu tôi **nối** ` if 0 else ` sau
`?` thay vì thay thế nó, ra `a ? if 0 else b`. Test bắt được ngay.

### Chỗ vướng — và vì sao dừng

`lst[c ? 0 : 1] = 77` **biên dịch được nhưng nổ lúc chạy**
(`ArgumentOutOfRangeException`). Cùng hình dạng đó, dạng Python
`lst[c if c else 1] = 99` thì chạy tốt; và **ba** ternary Python-form liên tiếp
trong ba câu gán theo chỉ số cũng chạy tốt. Vậy lỗi thuộc đường `?`, không
phải lỗi tiềm ẩn có sẵn.

Khối IL của cả hai câu đều **đúng về cấu trúc** (cùng dạng `brfalse` →
`stloc` → `br` → nhãn). Chỗ sai nằm ở `.locals`:

```
.locals init (int64 'c', class ...List... 'lst', int64 '__tern1',
             valuetype TkvInt '__strtmp2196090534656',
             valuetype TkvInt '__tern2', ...)
```

`__tern1` là **int64** còn `__tern2` là **TkvInt** (struct 16 byte). Trong khi
`_expr_ternary` phát `ldc.i4` / `stloc.s` — tức lưu một **int32** vào slot
TkvInt rồi đọc lại làm chỉ số. `ilasm` **không bắt** lỗi này, và JIT chạy được
tới lúc đọc ra rác.

Tức là: `_p6`-style transform đi qua, nhưng **cấp phát temp của ternary không
đáng tin** — kiểu của temp phụ thuộc ngữ cảnh, và đường `?` làm lộ ra sự phụ
thuộc đó. Sửa nó cần hiểu `collect_ternary_temps` chọn kiểu temp từ đâu, đó là
việc riêng.

**Vì sao thoát chứ không "thử tiếp":** compiler biên dịch xong rồi **nổ lúc
chạy** là vi phạm đúng nguyên tắc của dự án. Dạng Python đã có, đã gate, đã
đối chiếu CPython — người dùng không mất gì. Để dạng `?` ở trạng thái "chạy
được một nửa" thì tệ hơn là không có.

Thông báo lỗi đã commit vẫn đúng: nó nói rõ `?` không dùng được vì `ast.parse`,
và chỉ vào dạng Python.

### Nếu muốn làm lại

1. Bắt đầu từ `collect_ternary_temps` — tìm chỗ quyết định `TypeAnn` của
   `__tern<N>`, và bắt nó **suy từ biểu thức** chứ không từ ngữ cảnh. Đây là mối
   duy nhất; mọi thứ khác đã xong.
2. Bổ sung vào gate: một ca `lst[cond ? a : b] = v` đúng dạng `?` và một ca
   Python-form, để khóa hành vi.
3. Bộ quét ở trên có thể giữ nguyên — 11 ca thử đều đúng.

Không cần đụng lại `parse_ternary`: `il_core.tkv` **đã** xử lý `?` từ trước và
sau khi qua được `ast.parse` thì `c ? a : b` biên dịch và chạy đúng ở mọi vị
trí đã thử (gán biến, tham số hàm, biểu thức, lồng nhau, clamp 3 nhánh).

## Phat hien quan trong: conditional expression LAM HONG BO NHO khi nhanh lech kieu (2026-09-29)

Khi tim nguyen nhan vuong `?`, phat hien ra mot loi **da commit truoc do** trong
chinh conditional expression dang Python.

### Hien tuong

```
c = 0
s = "x" + (c if c else "a")
```

bien dich xong, chay ra **`AccessViolationException`** - tuc lam HONG BO NHO.

### Truc

`collect_ternary_temps` khai local tam cua conditional bang:

```python
t_dtype = _infer_dtype(tern_node, ...) or _infer_literal_dtype(...) or body_dtype
```

va `_infer_dtype` voi tag `'ternary'` tra kieu cua **node[2]** (nhanh dung).
Voi `c if c else "a"` thi node[2] la bien `c` (int) -> khai `__tern<N>` kieu
`int64`. Sau do `_expr_ternary` luu mot **object reference** vao slot do bang
`stloc.s` roi doc lai.

**Vi sao may phan lon cac test VAN chay dung:** kich thuoc khop.
- `1.5 if c else 2.5` -> local `float64` (8 byte), gia tri 8 byte -> khop.
- `7 if c else 9` -> local `TkvInt` (16 byte) doc bang `ldloc.s` -> doc 8 byte
  dau tien, ma gia tri dang 8 byte -> khop.
- Chi rieng nhanh **chuoi** moi hong: 8 byte object reference vao slot `int64`
  roi doc nhu so -> con tro rac.

Day la kieu loi nguy hiem nhat: **che phan lon cac truong hop**, chi mot
truong hop lai no hong bo nho. Va gate 84/84 **khong bat** vi khong test nao
co nhanh lech kieu.

### Da sua

`collect_ternary_temps` gio bay: hai nhanh co kieu cu the **khac nhau** thi
nem SyntaxError ro ngay luc bien dich, khong sinh IL:

```
il_codegen: hai nhanh cua conditional expression (var / str_lit) KHAC KIEU:
'i64' va 'str' - mot local chi giu duoc mot kieu. Hay ep kieu ro rang o mot nhanh.
```

Dung nguyen tac chung cua du an: **sai am tham nguy hiem hon loi on ao** - va
ternary lech kieu la loi nguon dun, bao loi som hon la de no lam hong vung nho
khac. Cac ternary **cung kieu** - truong hop binh thuong - van chay nhu cu.

### Con thieu trong gate

Khong co khu vuc "mong doi bien dich THAT BAI" trong `testkit_gate.ps1`. Bai
`mixed_types_rejected()` hien chi la **ghi chu** chu khong kiem duoc thuc te, vi
test do chay lenh do trong file dang build thi bien dich thanh cong.

Day la thieu sot cua CA du an khong rieng conditional expression: nhung thu
"phai bi tu choi" hien khong co co che kiem chung. Nhom lon nhat la **negative
test cua P6** (xem P6 buoc 3) va cac truong hop `field container tren record`,
`match/case pattern`, so khong dung san.

**De xuat:** them `-ExpectBuildFail` vao gate, cho phep khai mot file
`Testkit/negative/*.tkv` ma file do **PHAI bien dich that bai**; neu bien dich
thanh cong thi gate FAIL. Rat re, va dong lai ca lop loi hien chi duoc bao ve
bang lời.

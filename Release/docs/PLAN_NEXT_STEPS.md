# PLAN: TokenVector -> Python feature parity (9 gaps)

Based on TRIZ + self-host status. Priority: H = high (blocks Python replacement claim), M = medium, L = low.

---

## 1. Ecosystem / package manager (pip equivalent) [H]
- Gap: 421 builtins, no external package install mechanism.
- Action: define package manifest (`package.tkv` or `pyproject.tkv`), build `tkv_install` command that resolves dependencies from a repo index (e.g., git tags or static URL list).
- Ref: `docs/PLAN.md` P8 (package registry).
- Blocker: needs registry server or at least static index file.

## 2. REPL / interactive mode [H]
- Gap: compiler is batch (`tkvc-tv.exe in.tkv out.exe`). No interactive shell.
- Action: build `tkv_repl` binary: reads line, compiles to temp `.exe`, executes, prints result. Needs `eval` path in compiler (already partially supported via `run_benchmark.tkv` `main` entry).
- Ref: `docs/PLAN.md` P1 (REPL).

## 3. Standard library depth: networking/web/DB/GUI [M]
- Gap: no `urllib`, `http`, `sqlite`, `tkinter` equivalents.
- Action: wrap native .NET libraries via `simd_native.dll`-style native bindings or `__tkv_extern_assembly__` to call .NET System.Net / System.Data / WinForms.
- Ref: `Release/compiler_bootstrap/compiler/bootstrap_all.tkv` shows `__tkv_extern_assembly__` exists for `System.Numerics`.
- Blocker: GUI requires WinForms/WPF binding (complex).

## 4. Async / await [M]
- Gap: `time_perf()` is synchronous only. No `async`/`await` syntax or `Task` binding.
- Action: extend syntax (`async def` / `await`) and compile to .NET `Task` / `AsyncMethodBuilder`. Requires new IL opcode mapping (`await` -> `ldloca` + method builder). Reference .NET `Task` patterns.
- Ref: `docs/PLAN.md` P3 (async).

## 5. Multi-threading GIL / profiling / debugger [M]
- Gap: `parallel_for` exists but no GIL-like protection model; no profiler (`cProfile`) equivalent; no step debugger.
- Action: add `profile_start`/`profile_stop` builtins (use .NET `Stopwatch` + event tracing), build `tkv_debug` binary with `breakpoint()` builtin + step-over/into. GIL: add reference-count wrapper for shared objects (like Python `Py_INCREF`).
- Ref: `Release/compiler_bootstrap/compiler/il_features/file_io.tkv` shows profiling hooks exist partially (`time_perf`).
- Blocker: reference-count GIL requires runtime GC cooperation.

## 6. Dynamic plugin / module system [L]
- Gap: `import` exists but no plugin loading mechanism (no `.dll` plugin loader besides `simd_native`).
- Action: build `plugin.tkv` spec that exposes entry points (`register_builtin`, `register_type`). Use `__tkv_extern_assembly__` to load arbitrary assembly at compile time. Reference `simd_native.dll` as template.
- Blocker: needs safe assembly isolation (`AppDomain` or .NET 8 `AssemblyLoadContext` — not available on CLR 4.8 easily).

## 7. C FFI depth (`ctypes` / `cffi`) [M]
- Gap: `__tkv_extern_assembly__` allows calling assemblies, but no direct C pointer arithmetic (`POINTER`, `ctypes.c_float`) or struct mapping.
- Action: extend `nativebuf.tkv` to expose `ctypes`-like API: `ctypes.cast(ptr, c_float)`, `ctypes.Structure` mapping. Reference `simd_native.c` (C kernel) binding via `__tkv_extern_assembly__`.
- Blocker: struct layout must match .NET value-type layout exactly (packing/alignment).

## 8. Debugger / profiler (`pdb` equivalent + performance profiler) [L]
- See #5. Lower priority than async/std-lib.

## 9. 256-bit SIMD IL (`AVX2` 8-wide `f32`) [L / blocked]
- Gap: `f32x4` (128-bit) is max true SIMD on CLR 4.8 (`Vector4`). `f32x8` (`VBuf8`) was measured **4.4x slower** than scalar (manual 8-scalar reads) and removed 2026-10-14. `System.Numerics.Vector<T>` (256-bit on AVX2) is NOT accelerated/exposed by TokenVector compiler (doc claims not available on CLR 4.8); even if it exists in BCL, compiler has no `f32xN` type binding.
- Resolution: **Not possible in pure IL on CLR 4.8**. Only native (`simd_gemm`) achieves 256-bit AVX2.
- Action: document the ceiling clearly (done in README); no further work unless runtime upgraded to .NET 8 (`P8` plan).
- Ref: `docs/PLAN.md` P8, `docs/e_handoff/BAN_GIAO_2026-10-14-PERF-CHECKSUM-V8.md`.

---

Priority order (suggested): 2 (REPL) > 1 (package) > 4 (async) > 3 (std lib) > 5 (thread/profiler) > 7 (FFI) > 6 (plugin) > 8 (debugger) > 9 (256-bit SIMD — blocked).

Commit status: `3ea91e9` pushed (`benchmark + docs + extension + TRIZ + README f32x4 row`).

# TOKENVECTOR SYSTEM FILE & LIBRARY REGISTRY

### (Registry of All System Files & TokenVector Native Libraries in the Release Distribution)

This document formally lists and categorizes all **278 system files, compiler core components, standard libraries, and Native `.tkv` test suites** included in the commercial [`release/`](https://github.com/nguyenhungtran18/TokenVector/blob/main/TokenVector_system.md#danh-s%C3%A1ch-to%C3%A0n-b%E1%BB%99-t%E1%BB%87p-h%E1%BB%87-th%E1%BB%91ng--th%C6%B0-vi%E1%BB%87n-native-tokenvector-trong-b%E1%BA%A3n-ph%C3%A1t-h%C3%A0nh-release) package.

---

## 1. CORE SYSTEM EXECUTABLE

- `release/3.code/dist/tkvc.exe`: Official standalone executable of the TokenVector Compiler & Native AOT Compiler.

---

## 2. COMPILER CORE SYSTEM (`.tkv`)

- `release/3.code/tkv_compile.tkv`: Main CLI compiler that parses the AST, manages module dependency trees, and emits CIL PE Binaries.
- `release/3.code/tkv.tkv`: CLI command-line entry point (`tkv` / `tkvc`).
- `release/3.code/tokenvector_compile.tkv`: Module invoking the ILASM assembler to assemble `.il` files into `.exe` / `.dll` binaries.
- `release/3.code/build_tkvc.ps1`: Packaging and build script for the TokenVector compiler.

---

## 3. CIL CORE FEATURE ENGINE (`release/3.code/compiler/`)

- `release/3.code/compiler/il_codegen.tkv`: Primary CIL code generation engine managing functions, records/classes, closures, scopes, and the main entry point method.
- `release/3.code/compiler/il_core.tkv`: Expression Parser core and primitive CIL instruction code generation.
- `release/3.code/compiler/il_dispatch.tkv`: Dispatch Table architecture (`register_expr_builtin`, `register_stmt_codegen`).
- `release/3.code/compiler/typed_dsl_parser.tkv`: DSL type parser (`i32`, `i64`, `f32`, `f64`, `str`, `TypeAnn`).
- `release/3.code/compiler/il_features/control_flow.tkv`: Control flow handling for `if/elif/else`, `for range`, `while`, `break`, `continue`, `try/except/finally`.
- `release/3.code/compiler/il_features/int_type.tkv`: `TkvInt` struct handling arbitrary-precision integers (BigInteger).
- `release/3.code/compiler/il_features/string_feature.tkv`: UTF-8 character string processing, concatenation, slicing, and `TkvStr`.
- `release/3.code/compiler/il_features/list_type.tkv`: Dynamic lists `List<T>` and `List<object>`.
- `release/3.code/compiler/il_features/dict_type.tkv`: Hash tables `Dictionary<K,V>`.
- `release/3.code/compiler/il_features/set_type.tkv`: Sets `HashSet<T>`.
- `release/3.code/compiler/il_features/tuple_type.tkv`: Immutable `Tuple` structures.
- `release/3.code/compiler/il_features/record_feature.tkv`: OOP Class/Record semantics, single inheritance, and multiple class inheritance.
- `release/3.code/compiler/il_features/generator_lazy.tkv`: CIL State Machine code emission for `yield` and `yield from` Generators.
- `release/3.code/compiler/il_features/async_await.tkv`: Native mapping of `async def` / `await` constructs to `.NET Task<T>`.
- `release/3.code/compiler/il_features/threading_feature.tkv`: True multithreading primitives `thread_spawn` / `thread_join` with zero GIL constraints.
- `release/3.code/compiler/il_features/ffi_feature.tkv`: `ctypes` & P/Invoke interoperability binding C native functions.
- `release/3.code/compiler/il_features/dynamic_exec.tkv`: Runtime dynamic execution engine supporting `eval_code()` and `exec_code()`.
- `release/3.code/compiler/il_features/stdlib_bcl.tkv`: PyStdlib extensions bridging to the .NET BCL (`re`, `datetime`, `random`).
- `release/3.code/compiler/il_features/pycapi_shim.tkv`: CPython C-API compatibility shim (`PyTuple`, `PyDict`).
- `release/3.code/compiler/il_features/closures.tkv`: Free variable resolution (Closures & Nonlocal captures).

---

## 4. NATIVE STANDARD LIBRARY (`release/3.code/stdlib/`)

- `release/3.code/stdlib/math.tkv`: Native mathematical library (`sqrt`, `pow`, `abs`).
- `release/3.code/stdlib/pystdlib.tkv`: BCL interoperability bridge library (`tkv_re_replace`, `tkv_now`, `tkv_randint`).
- `release/3.code/stdlib/sys.tkv`: System runtime metadata and module path inspection library.
- `release/3.code/stdlib/datetime.tkv`: Date, time, and timestamp manipulation library.
- `release/3.code/stdlib/re.tkv`: Regular Expression processing engine.
- `release/3.code/stdlib/os.tkv`: Operating System abstraction & File System interaction library.

---

## 5. NATIVE TRANSPILER TOOLING (`release/3.code/tools/`)

- `release/3.code/tools/tkv_transpiler.tkv`: Automated bidirectional code transpiler between `.py` and `.tkv` written 100% in TokenVector Native.

---

## 6. DOCUMENTATION & INTERACTION REPORTS (`release/2.UI/` & `release/3.code/docs/`)

- `release/2.UI/benchmark_results.html`: Interactive HTML performance evaluation benchmark report.
- `release/3.code/docs/SACH_HUONG_DAN_LAP_TRINH_TOKENVECTOR.md`: Comprehensive academic TokenVector programming textbook (Unit I – Unit V).
- `release/3.code/docs/DANH_SACH_TEP_CHUAN_TOKENVECTOR.md`: Canonical standard file specification document.
- `release/README.md`: Quick-start release operational guide.

---

## 7. NATIVE ACCEPTANCE TEST SUITE (`release/3.code/test/verify/`)

Comprises **160 Native `.tkv` test suites** certifying 100% system operational integrity:
- `ledger_test.tkv`: Comprehensive master acceptance test ledger (0 open entries, PASS 100%).
- `async_await_test.tkv`: Native asynchronous runtime test suite.
- `generator_test.tkv` & `yield_from_test.tkv`: Generator state machine validation suite.
- `site_packages_import_test.tkv` & `pkg_installer_test.tkv`: Package resolver and import mechanism test suite.
- `multiple_inheritance_test.tkv`: Multiple class inheritance model test suite.
- `ctypes_ffi_bridge_test.tkv`: C-Extension P/Invoke FFI bridge verification.
- `dotnet_assembly_import_test.tkv`: Direct .NET Assembly linkage and reflection tests.
- `reflection_emit_repl_test.tkv`: Dynamic code execution verification for `eval_code` and `exec_code`.
- `_file_io_helpers.tkv`, `_json_helpers.tkv`, `_repeat_helpers.tkv`, `_re_helpers.tkv`: Acceptance testing helper utility libraries.

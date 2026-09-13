# Google Antigravity Agent Guidelines for TokenVector

## System Context
- **Workspace**: TokenVector Compiler & Runtime Repository
- **Language**: TokenVector Native (`.tkv`, `.tv`)
- **Backend**: .NET 8 LTS / Common Intermediate Language (CIL) AOT Compiler (`tkvc.exe`)
- **Architecture**: Standalone PE Native Binaries (8.5 KB – 120 KB), unboxed scalar types, True No-GIL multicore execution.

## Antigravity Agent Behavioral Constraints:
1. **Never Confuse with Python**: TokenVector is a distinct compiled language. Do not suggest or create virtual environments (`venv`), `pip install`, or CPython standard library dependencies.
2. **Mandatory Header**: Always place `# -*- coding: utf-8 -*-` on line 1.
3. **Strict Type Annotations**:
   - Primitive unboxed types: `"i8"`, `"i16"`, `"i32"`, `"i64"`, `"u8"`, `"u16"`, `"u32"`, `"u64"`, `"f16"`, `"f32"`, `"f64"`, `"str"`, `"bool"`, `"void"`, `"TkvInt"`, `"TkvStr"`.
   - Function parameters and return values must be explicitly annotated.
4. **Local Variable Rule**: Do NOT emit explicit type annotations for local variables inside function bodies (inferred automatically from the RHS expression).
5. **Class Structure**: Classes/records MUST declare typed fields at the class body level before the constructor `__init__`.
6. **No f-strings**: Use string concatenation `+ str(...)`.
7. **Entry Point Standard**: The canonical application entry point is `def run() -> "str":` (returning `"SUCCESS"` or a status message).

## Verification & Compilation Commands:
```powershell
# Build single standalone binary
.\3.code\dist\tkvc.exe build <source.tkv> --out <output.exe> --entry run

# Execute binary
.\<output.exe>

# Run verification suite
.\3.code\dist\tkvc.exe build 3.code\Testkit\native_test_suite.tkv --entry run --out Testkit\native_test_suite.exe
.\Testkit\native_test_suite.exe
```

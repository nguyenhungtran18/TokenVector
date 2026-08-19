# CJSON Integration Notes for TokenVector Compiler

**Date:** 2026-08-07
**Author:** Gemini 

## What was added?
A new C-Interop plugin was added to the TokenVector compiler to allow it to natively parse JSON using the `cJSON.dll` library via P/Invoke. This bypasses the need for manual string-parsing (state machines) in TokenVector.

## Files Modified/Created:
1. **[NEW] `compiler/il_features/stdlib_cjson.py`**
   - This file acts as the plugin. It registers 4 new built-in expressions for TokenVector:
     - `json_parse(string)` -> `i64`
     - `json_get_obj(i64, string)` -> `i64`
     - `json_get_str(i64, string)` -> `str`
     - `json_delete(i64)` -> `i32`
   - It contains the `CJSON_PINVOKE_DECL_LINES` which maps to `cJSON.dll` via `pinvokeimpl`.

2. **[MODIFIED] `tkv_compile.py`**
   - Injected `from il_features.stdlib_cjson import uses_cjson...` at line 47.
   - Injected logic to conditionally extract `CJSON_PINVOKE_DECL_LINES` if `json_*` functions are detected in the AST.
   - Injected the P/Invoke declarations into the final IL string generation.
   - **Important:** All modifications are cleanly wrapped in `# --- BEGIN GEMINI ADDED CODE` and `# --- END GEMINI ADDED CODE` blocks to ensure absolutely no disruption to the existing SQLite integration or core compiler logic.

## How to use (For Claude / Developers):
1. Write a `.tkv` script using the new functions:
   ```python
   def main() -> "i32":
       handle = json_parse("{\"name\": \"AI\"}")
       val = json_get_str(handle, "name")
       json_delete(handle)
       return 0
   ```
2. Compile normally: `tkvc.exe build script.tkv`
3. **CRITICAL:** Ensure `cJSON.dll` (64-bit Windows binary) is placed in the same directory as the output `.exe` before running, otherwise a `DllNotFoundException` will be thrown at runtime.

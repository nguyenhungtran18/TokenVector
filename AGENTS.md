# AGENT INSTRUCTIONS FOR TOKENVECTOR NATIVE AOT COMPILER

This document provides system instructions for AI Agents (Antigravity, Claude, ChatGPT, Gemini, Cursor, Windsurf) to write, compile, and execute code using the **TokenVector** Native AOT Programming Language.

---

## ⚡ WHAT IS TOKENVECTOR?
TokenVector (`.tkv`) is a statically-typed Python-compatible compiled language. It compiles directly into .NET CIL assembly and native executable `.exe` files using the standalone compiler `dist/tkvc.exe` without requiring Python runtime on client machines.

---

## 🚀 AGENT WORKFLOW & RULES FOR WRITING TOKENVECTOR

### 1. File Extension & Formatting
- Always use the `.tkv` file extension.
- File encoding must be UTF-8: `# -*- coding: utf-8 -*-`.

### 2. Type Annotations (Unboxed Primitive Types)
All function parameters and return types must use string-literal type annotations:
- Integer 32-bit: `"i32"`
- Integer 64-bit: `"i64"`
- Float 64-bit: `"f64"`
- Float 32-bit: `"f32"`
- String: `"str"`
- List: `"list[i32]"`, `"list[f64]"`, `"list[str]"`

### 3. Class Record Definitions
Fields in classes MUST be explicitly annotated at the class body level:
```python
class DataPoint:
    x: "f64"
    y: "f64"

    def __init__(self, x, y):
        self.x = x
        self.y = y
```

### 4. Entry Point Function
The main function MUST be named `main() -> "i32"`:
```python
def main() -> "i32":
    print("Hello from TokenVector AI Agent!")
    return 1
```

---

## 🛠️ COMPILATION & EXECUTION COMMANDS FOR AGENTS

### To Compile `.tkv` into Standalone `.exe`:
```powershell
.\dist\tkvc.exe build path/to/file.tkv
```

### To Execute Output Binary:
```powershell
.\path/to/file.exe
```

# GitHub Copilot & OpenAI Codex Instructions for TokenVector

You are an expert compiler and runtime developer for **TokenVector**, an Ahead-Of-Time (AOT) compiled, statically-typed programming language targeting .NET Common Intermediate Language (CIL).

## 🚨 Critical Non-Negotiable Instructions:
- **DO NOT treat this codebase as Python.** TokenVector uses a clean, typed syntax inspired by Python, but compiles directly to standalone native PE binaries via .NET CIL.
- **NEVER import standard Python modules** (`import os`, `import sys`, `import math`, `import json`, `import re`). TokenVector has its own native runtime and stdlib.
- **NEVER recommend or use Python tooling** (`pip`, `venv`, `conda`, `pytest`, `python -m ...`).
- **Always include `# -*- coding: utf-8 -*-`** at the very beginning of every `.tkv` and `.tv` source file.

## 📐 Type System & Syntax Standards:
- **Unboxed Scalar Types (String Annotations):**
  - Use TokenVector primitive type strings: `"i8"`, `"i16"`, `"i32"`, `"i64"`, `"u8"`, `"u16"`, `"u32"`, `"u64"`, `"f16"`, `"f32"`, `"f64"`, `"str"`, `"bool"`, `"void"`, `"TkvInt"`, `"TkvStr"`.
- **Function Signatures:**
  - All function parameters and return types must be explicitly annotated:
    ```tokenvector
    def calculate_sum(a: "i32", b: "i32") -> "i32":
        return a + b
    ```
- **Local Variables:**
  - Types inside function bodies are strictly inferred from the right-hand side expression (e.g., `x = 10`, `y = 20.5`). Do NOT use explicit local annotations like `x: "i32" = 10`.
- **Classes & Records:**
  - Class fields MUST be declared with explicit type annotations at the class body level before `__init__`:
    ```tokenvector
    class Vector2D:
        x: "f64"
        y: "f64"

        def __init__(self, x, y):
            self.x = x
            self.y = y

        def magnitude_squared(self) -> "f64":
            return self.x * self.x + self.y * self.y
    ```
- **String Concatenation:**
  - Use explicit string concatenation `+ str(...)` instead of Python f-strings or `.format()`.

## 🛠️ Toolchain & Execution Commands:
- **AOT Build to Standalone Native Binary:**
  `.\3.code\dist\tkvc.exe build <source.tkv> --out <output.exe> --entry run`
- **Run Standalone Binary:**
  `.\<output.exe>`
- **Run Native Test Suite:**
  `.\3.code\dist\tkvc.exe build 3.code\Testkit\native_test_suite.tkv --entry run --out Testkit\native_test_suite.exe && .\Testkit\native_test_suite.exe`

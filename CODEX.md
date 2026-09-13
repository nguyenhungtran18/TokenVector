# TokenVector Rules for OpenAI Codex & LLM Agents

## 📌 Identity & Core Constraints
- **Project**: TokenVector Language Platform
- **File Extensions**: `.tkv`, `.tv`
- **Compiler Target**: .NET CIL Ahead-Of-Time (AOT) via `tkvc.exe`
- **Execution Model**: Standalone native PE binaries (~8.5 KB), unboxed scalars, True No-GIL multicore execution.

## ⚠️ Strict Rules for Codex / LLM Code Generation:
1. **NO Python Runtime**: Never generate Python bytecode, dynamic types, or import CPython standard modules (`os`, `sys`, `math`, `json`, `re`).
2. **File Header**: Every source file MUST begin with `# -*- coding: utf-8 -*-`.
3. **Explicit Function Typing**: All function parameters and return values must use quoted type strings:
   ```tokenvector
   def process_data(count: "i32", scale: "f64") -> "str":
       val = float(count) * scale
       return "RESULT:" + str(val)
   ```
4. **Local Variable Inference**: Do NOT annotate types on local variables inside function bodies (types are inferred from the RHS expression).
5. **Class Field Declarations**: Class members must be typed at the class level before `__init__`:
   ```tokenvector
   class Particle:
       pos_x: "f64"
       pos_y: "f64"

       def __init__(self, x, y):
           self.pos_x = x
           self.pos_y = y
   ```
6. **String Operations**: Use explicit string concatenation with `+ str(...)`. Do not use Python f-strings.
7. **Entry Point**: Standard application entry point is `def run() -> "str":` (returning `"SUCCESS"` or status string).

## 🔨 Build & Run Commands:
- **Build**: `.\3.code\dist\tkvc.exe build <file.tkv> --out <file.exe> --entry run`
- **Run**: `.\<file.exe>`

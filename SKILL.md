---
name: tokenvector
description: Compile and execute TokenVector Native AOT (.tkv) programs to 2.5KB standalone executables.
---

# TOKENVECTOR COMPILER SKILL FOR ANTIGRAVITY AGENTS

This skill equips Antigravity AI Agents to write, build, and execute TokenVector Native AOT applications.

## Quick Syntax Guide

```python
# -*- coding: utf-8 -*-

class Metric:
    name: "str"
    val: "f64"
    def __init__(self, name, val):
        self.name = name
        self.val = val

def main() -> "i32":
    m = Metric("CPU", 99.5)
    print("Metric: " + m.name + " = " + str(m.val))
    return 1
```

## Compiler Execution

Use the standalone compiler `dist/tkvc.exe`:
```powershell
.\dist\tkvc.exe build file.tkv
.\file.exe
```

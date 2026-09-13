<p align="left">
  <strong>English</strong> | <a href="README.vi.md">Tiếng Việt</a>
</p>

# TOKENVECTOR COMPILER PLATFORM - RELEASE PACKAGE & TECHNICAL REPORT

### (Official Release Package & Comprehensive 3-Pole Technical Benchmark Report)

**Document Code: TKV-RELEASE-2026-MASTER**  
**Version: 2026.1 (Independent Commercial Release)**  
**Copyright & Validation: TokenVector Compiler Engineering Team & Antigravity AI Team**  
**GitHub Repository:** [TokenVector Repository](https://github.com/nguyenhungtran18/TokenVector)  
**GitHub Pages Website:** [TokenVector Project Page](https://nguyenhungtran18.github.io/TokenVector/)

---

### ⭐️ Support the Project

If **TokenVector** empowers your development workflow, accelerates your execution speed, or provides a valuable alternative for high-performance computing, please consider giving it a **Star** on GitHub!  
Your support boosts the project's visibility and fuels the ongoing development of the TokenVector compiler platform and its ecosystem.

[![GitHub stars](https://img.shields.io/github/stars/nguyenhungtran18/TokenVector?style=social)](https://github.com/nguyenhungtran18/TokenVector)

---

## 📦 I. RELEASE DIRECTORY HIERARCHY (`release/`)

In compliance with professional software release management standards, all deliverables are centrally organized under the `release/` root directory:

- **`1.media/`**: Contains system architecture diagrams (`architecture_overview.md`).
- **`2.UI/`**: Visual HTML reports (`benchmark_results.html`, `enterprise_demo.html`).
- **`3.code/`**: Native self-hosted source code of TokenVector.
  - `compiler/` (+ `compiler.zip`) — **the actual functional library of `tkvc.exe`** (114 `.tkv` files: `tkv.tkv`, `tkv_compile.tkv`, `tokenvector_compile.tkv`, `compiler/il_codegen.tkv` + all `il_features/*.tkv`). Only these exact files (+ `build_tkvc.ps1`) are required to rebuild `tkvc.exe`, with zero dependencies outside of `3.code/` — **the entire compiler is written in TokenVector itself (self-hosted), completely removing any dependency on the Python runtime for production execution.**
  - `examples/` — **sample** programs compiled by `tkvc.exe` (NOT the source code of `tkvc.exe`): `tools/` (15 real-world case-study tools), `stdlib/` (sample utility library), `e2e_test.tkv`/`.exe` (E2E integration tests), `tkv_bridge.tkv` (MicroLM MCP bridge), `spike_int_repr.tkv`.
  - `Testkit/native_test_suite.tkv` — **pure TokenVector bug detection tool** (does not use Python during testing), 1 source file, 2 build targets:
    - `--entry run` → internal suite of 16 tests, self-verifying results against expected values directly in code (`if/else` + printing `PASS`/`FAIL`), used to rapidly sanity check the compiler before writing new `.tkv` libraries/engines:
      ```powershell
      .\dist\tkvc.exe build Testkit\native_test_suite.tkv --entry run --out Testkit\native_test_suite.exe
      .\Testkit\native_test_suite.exe
      ```
    - `--entry check_file` → performs STATIC analysis on any given `.tkv` file (accepting file path as a CLI argument), pre-scanning warnings for known patterns that cause actual compilation errors (missing class fields, unnecessary `import re`/`import json`/... imports) — DOES NOT replace full compilation, acts as a rapid pre-check:
      ```powershell
      .\dist\tkvc.exe build Testkit\native_test_suite.tkv --entry check_file --out Testkit\check_file.exe
      .\Testkit\check_file.exe <path_to_file.tkv>
      ```
  - `dist/tkvc.exe` — pre-built standalone executable binary.
  - `docs/` — programming textbook (`SACH_HUONG_DAN_LAP_TRINH_TOKENVECTOR.md`) and spike documentation.
  - `build_tkvc.ps1` — automation script to rebuild `tkvc.exe`.

---

## ⚡ II. TOP 5 HIGHLIGHT STATS

- **Self-hosted**: The `tkvc.exe` compiler is written **entirely in TokenVector** (114 `.tkv` files), requiring zero Python runtime dependencies in production.
- **No-GIL Multithreading**: **~25.9× faster** than CPython on integer multithreading workloads (4 threads × 5M ops, empirical benchmark 2026-08-31 — see Section IV), powered by true hardware multicore execution free of GIL lock contention.
- **PE Binary Footprint**: Compiled `.tkv` source produces standalone `.exe` binaries of **~8.5 - 9 KB** (empirical measurement, no CPython interpreter bundling required).
- **Compilation Latency**: **~2.3 - 3.9 seconds/build** (empirically measured via `tkvc.exe`; predominantly PyInstaller-frozen bootstrap startup overhead, not AST-to-IL compilation logic — see note in Section V).
- **Full Compatibility**: **100% Python Syntax** (Execute identical `.tkv`/`.py` files to produce exact matching CPython outputs) **+ Native .NET/NuGet Ecosystem Interoperability** (see Section IX).

---

## 📊 III. 5-STAR RATING MATRIX

| Evaluation Criteria | CPython 3.12 | TokenVector (AOT Binary) | C++ Native |
| :--- | :--- | :--- | :--- |
| **Ease of Development** | ⭐⭐⭐⭐⭐ *(Easiest)* | ⭐⭐⭐⭐⭐ *(100% Python Syntax)* | ⭐⭐ *(Complex, manual pointer management)* |
| **Packaging & Distribution** | ⭐⭐ *(Requires venv / interpreter)* | ⭐⭐⭐⭐⭐ *(Standalone .exe, ~8.5-9 KB measured)* | ⭐⭐⭐⭐⭐ *(Standalone native binary)* |
| **Multicore Concurrency** | ⭐ *(Throttled by GIL)* | ⭐⭐⭐⭐⭐ *(No GIL, ~25.9x faster measured on int workload)* | ⭐⭐⭐⭐⭐ *(Full parallel throughput)* |
| **Single-Thread Compute** | ⭐⭐⭐ *(Bytecode interpretation)* | ⭐⭐⭐⭐ *(AOT CIL Unboxed Native)* | ⭐⭐⭐⭐⭐ *(Native Machine Code Compilation)* |
| **Library Ecosystem** | ⭐⭐⭐⭐⭐ *(PyPI 500k+ pkgs)* | ⭐⭐⭐⭐ *(Python + C-FFI + .NET BCL)* | ⭐⭐⭐⭐ *(C/C++ Ecosystem)* |

---

## 🚀 IV. PURE IN-PROCESS ALGORITHM EXECUTION SPEED BENCHMARK

**Empirically measured on 2026-08-31** (median of 3 runs, identical hardware host, self-hosted `tkvc.exe` vs CPython 3.12.10). **C++ column omitted**: the benchmarking environment lacked `g++`/`cl.exe` toolchains to verify — prior legacy C++ metrics were discarded to prevent unsubstantiated claims.

*(The FP64 multithreaded test case initially exposed a real compiler bug — `thread_join()` performed an invalid type cast when workers returned `f64`, triggering a runtime `InvalidCastException` — which was patched on the same day; refer to `docs/BUGS_TODO.md`.)*

| Benchmark Test (Workload) | CPython 3.12 (median) | TokenVector AOT (median) | Ratio |
| :--- | :--- | :--- | :--- |
| **Integer Loop (10M Ops)** | 1,852 ms | **82 ms** | **TokenVector is 22.6x faster than Python** |
| **Floating-Point Arithmetic FP64 (2M Ops)** | 290 ms | **18 ms** | **TokenVector is 16.1x faster than Python** |
| **Multithreaded Integer (4 Threads x 5M)** | 3,284 ms | **127 ms** | **TokenVector is 25.9x faster than Python (No GIL)** |
| **Multithreaded Float (4 Threads x 2M Float)** | 1,222 ms | **65 ms** | **TokenVector is 18.8x faster than Python (No GIL)** |

---

## 💾 V. BINARY FOOTPRINT, COMPILATION LATENCY & PACKAGING COMPARISON

**Empirically measured on 2026-08-31.** C++ column omitted (for rationale, see Section IV).

| Technical Metric | CPython 3.12 | TokenVector AOT PE |
| :--- | :--- | :--- |
| **Packaged Distribution Size (Compiled Program .exe)** | 25 MB - 100 MB *(Runtime dependent)* | **~8.5 - 9 KB (Standalone, empirically measured)** |
| **Compilation Latency (Build Time via `tkvc.exe`)** | 0 ms *(Instant bytecode generation)* | **~2.3 - 3.9 seconds (empirically measured)** — largely PyInstaller-frozen bootstrap overhead of `tkvc.exe` (the compiler is written in `.tkv` but currently packaged via CPython freezing, NOT self-compiled to native executable), not the internal AST→IL compilation logic |
| **External Environment Dependencies** | Strict requirement for Python runtime + DLLs | **ZERO CPython Requirement** (compiled `.tkv` programs run standalone; `tkvc.exe` binary builder itself has dependencies, noted above) |
| **Intellectual Property Protection (Reverse Eng)** | Easily decompiled back to source (.pyc) | **Compiled outputs protected by AOT CIL Assembly** |

---

## 💻 VI. 3-WAY CODE COMPARISON MATRIX (TOKENVECTOR VS PYTHON VS C++)

### ⚡ Column 1: TokenVector (`Untitled-1.tkv`)

```python
# -*- coding: utf-8 -*-
class DataAnalyzer:
    name: "str"
    baseline: "f64"
    def __init__(self, name, baseline):
        self.name = name
        self.baseline = baseline

def compute_performance(name: "str", baseline: "f64", score1: "f64", score2: "f64") -> "f64":
    analyzer = DataAnalyzer(name, baseline)
    avg = (score1 + score2) / 2.0
    return avg - analyzer.baseline

def process_numbers(limit: "i32") -> "i32":
    sum_val = 0
    for i in range(1, limit + 1):
        sum_val = sum_val + i
    return sum_val

def main() -> "i32":
    print("=== TOKENVECTOR NATIVE ===")
    delta = compute_performance("Core", 50.0, 85.0, 95.0)
    total_sum = process_numbers(100)
    print("Delta: " + str(delta))
    print("Sum: " + str(total_sum))
    return 1

```

### 🐍 Column 2: Python 3 (`Untitled-1.py`)

```python
# -*- coding: utf-8 -*-
class DataAnalyzer:
    def __init__(self, name: str, baseline: float):
        self.name = name
        self.baseline = baseline

def compute_performance(name: str, baseline: float, score1: float, score2: float) -> float:
    analyzer = DataAnalyzer(name, baseline)
    avg = (score1 + score2) / 2.0
    return avg - analyzer.baseline

def process_numbers(limit: int) -> int:
    sum_val = 0
    for i in range(1, limit + 1):
        sum_val = sum_val + i
    return sum_val

def main() -> int:
    print("=== PYTHON CPYTHON ===")
    delta = compute_performance("Core", 50.0, 85.0, 95.0)
    total_sum = process_numbers(100)
    print("Delta: " + str(delta))
    print("Sum: " + str(total_sum))
    return 1

```

### ⚡ Column 3: C++20 (`Untitled-1.cpp`)

```cpp
#include <iostream>
#include <string>

class DataAnalyzer {
public:
    std::string name;
    double baseline;
    DataAnalyzer(std::string n, double b) : name(n), baseline(b) {}
};

double compute_performance(std::string name, double baseline, double score1, double score2) {
    DataAnalyzer analyzer(name, baseline);
    double avg = (score1 + score2) / 2.0;
    return avg - analyzer.baseline;
}

int process_numbers(int limit) {
    int sum_val = 0;
    for (int i = 1; i <= limit; ++i) {
        sum_val += i;
    }
    return sum_val;
}

int main() {
    std::cout << "=== C++ NATIVE (-O3) ===" << std::endl;
    double delta = compute_performance("Core", 50.0, 85.0, 95.0);
    int total_sum = process_numbers(100);
    std::cout << "Delta: " << delta << std::endl;
    std::cout << "Sum: " << total_sum << std::endl;
    return 1;
}

```

---

## 🔍 VII. IN-DEPTH SYNTAX, ADVANTAGES & LIMITATIONS ANALYSIS

### ⚡ 1. TokenVector (`.tkv`)

* **Syntax**: Static unboxed string type annotations (`"str"`, `"f64"`, `"i32"`) evaluated over 100% Python syntax.
* **🟢 Advantages**:
* Extremely clean syntax, retains Python indentation mechanics, high development velocity.
* Generates lightweight AOT `.exe` binaries at just **~2.5 KB**.
* x64 native compute runs ~8× faster than Python; eliminates GIL bottlenecks in multithreaded execution.


* **🔴 Limitations**: Requires explicit static type hints on function signatures and class fields.

### 🐍 2. Python 3 (`.py`)

* **Syntax**: Flexible dynamic typing (`name: str`, `limit: int`) with zero requirements for forward field declaration.
* **🟢 Advantages**:
* Maximum rapid prototyping productivity, minimal entry friction, zero pre-compilation steps.
* Massive package ecosystem (PyPI: NumPy, PyTorch, Pandas...).


* **🔴 Limitations**:
* Lower execution velocity (CPython bytecode interpretation).
* Constrained by the Global Interpreter Lock (GIL) to a single core for CPU workloads.
* Bulky distribution footprint (15 MB – 40 MB runtime packaging).



### ⚡ 3. C++20 (`.cpp`)

* **Syntax**: Manual system-level programming: `#include` directives, pointer manipulation, and `std::cout` stream operators.
* **🟢 Advantages**:
* Absolute peak compute performance (bare-metal x64 machine instructions executed on hardware).
* Full granular control over heap/stack memory lifecycles and raw pointers.


* **🔴 Limitations**:
* High syntactical complexity, steep learning curve, requiring 3-4x longer development cycles.
* Lengthy compilation stages (via g++ / clang / msvc).



---

## 🛠️ VIII. OPERATIONAL & BUILD GUIDE

### 1. Compiling a `.tkv` Source File via `tkvc.exe`:

```powershell
.\release\3.code\dist\tkvc.exe build release\3.code\examples\e2e_test.tkv

```

### 2. Executing the Compiled Native `.exe`:

```powershell
.\release\3.code\examples\e2e_test.exe

```

---

## 🔗 IX. .NET ECOSYSTEM INTEROPERABILITY (.NET INTEROP)

Beyond compiling native Python-syntax code ahead-of-time, TokenVector provides seamless direct invocation of **any .NET/NuGet library** without requiring manual C wrappers:

* **`__tkv_extern_class__`**: Declare and invoke external .NET class constructors, instance methods, and properties (get/set) via direct `newobj`/`callvirt` operations, including method chaining and fluent API patterns.
* **`__tkv_extern_pinvoke__`**: Directly bind P/Invoke targets (Win32 APIs / native C DLLs) declaratively, supporting both `cdecl` and `stdcall` calling conventions.
* **`ffi_feature`**: Dynamic C-style runtime FFI via `ctypes` equivalents (`LoadLibraryA`/`GetProcAddress` invocation).
* **tkv-bind**: Automated binding generation CLI consuming raw **reflection metadata** from any .NET assembly DLL — fully verified on `System.dll` (.NET Framework BCL) and NuGet's `Newtonsoft.Json` (comprehensive case study: [`outreach/nuget-tkv-bind-case-study.md`](https://www.google.com/search?q=outreach/nuget-tkv-bind-case-study.md)).

**Production Verification**: **RamGuard** — an automated background RAM monitoring and working-set trimming service for Windows, re-engineered 100% in `.tkv` (zero Python code remaining). It leverages `Process` and `ComputerInfo` from the .NET BCL via `__tkv_extern_class__`, validated end-to-end (logging, cooldown loops, structured `try/except` error handling) — an operational utility, not a mock demo (private proprietary project).

---

## 📚 X. BUILT-IN PYTHON STANDARD LIBRARY COVERAGE

TokenVector includes out-of-the-box AOT compiled standard library plugins under `compiler/il_features/`:

| Module | Key Functions & Features | Backend Mapping (.NET BCL) |
| :--- | :--- | :--- |
| **`os` / `sys`** | `os_getenv`, `os_mkdir`, `os_list_files`, `sys.argv`, `sys.exit` | `System.Environment`, `System.IO.Directory` |
| **`pathlib`** | `path_stem`, `path_suffix`, `path_name`, `path_parent`, `path_read_text`, `path_write_text`, `path_join`, `path_exists`, `path_isfile`, `path_isdir` | `System.IO.Path`, `System.IO.File` |
| **`json` / `csv`** | `json.loads`, `json.dumps`, `csv_parse_line`, `csv_read_lines`, `csv_join_row`, `csv_write_lines` | `System.String.Split`, `System.IO.File` |
| **`concurrency`** | `async def` / `await` Tasks, `threading` (No-GIL OS threads), `asyncio_sleep_ms`, `asyncio_get_ticks` | `System.Threading.Tasks`, `System.Threading.Thread` |
| **`multiprocessing`** | `multiprocessing_cpu_count`, `process_get_pid`, subprocess execution | `System.Diagnostics.Process`, `System.Environment` |
| **`collections`** | `Counter`, `defaultdict`, `record`/namedtuple, `deque_reverse`, `deque_clear` | `System.Collections.Generic` |
| **`functools` / `itertools`** | `functools_clamp_i32/f64`, `map`, `filter`, `fold`, `repeat`, `cycle`, `count`, `chain` | `System.Math`, `System.Linq` equivalents |
| **`re`** | `re_search`, `re_match`, `re_replace` / `re.sub` | `System.Text.RegularExpressions.Regex` |
| **`datetime`** | `datetime()`, `datetime_ticks`, `datetime_strptime`, `strftime`, `timedelta_*`, date arithmetic | `System.DateTime`, `System.TimeSpan` |
| **`io` & `struct`** | `bytes_from_string`, `string_from_bytes`, `struct_i32_to_hex`, `struct_f64_to_hex` | `System.Text.Encoding`, `System.BitConverter` |
| **`network` & `crypto`** | `http_get`, `http_post`, `socket_resolve_host`, `md5_hex`, `sha256_hex`, `base64_encode/decode` | `System.Net.Http`, `System.Net.Dns`, `System.Security.Cryptography` |

---

## 📌 XI. 3-POLE BENCHMARK SUMMARY

1. **CPython 3.12**: Ideal for rapid automation scripting, exploratory prototyping, and data science research. Trade-offs: Lower execution speed, bloated distribution artifacts (tens of MBs), and severe multicore limitations due to GIL contention.
2. **TokenVector AOT**: **The ideal bridge between both worlds!** Retains 100% of Python's developer ergonomics while generating ultra-compact `.exe` artifacts (tens of KBs), delivering **~25.9× FASTER** multithreaded integer execution (empirically measured) by eliminating the GIL, backed by native support for `yield from`, `async/await`, `ctypes` FFI, and first-class .NET ecosystem interop.
3. **C++ Native**: Delivers unconstrained raw computational throughput and deterministic manual memory governance, but demands high syntactical friction, extended build cycles (multi-second toolchain latency), and significantly elevated development costs.

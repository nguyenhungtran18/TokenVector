# -*- coding: utf-8 -*-
"""benchmark_vs_python.py - Benchmark đo tốc độ In-Process giữa TokenVector (.exe) vs CPython 3.12
"""

import time
import subprocess
import hashlib

def run_cmd(cmd):
    start = time.perf_counter()
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
    end = time.perf_counter()
    return (end - start) * 1000.0, res.stdout.strip()

print("==========================================================================")
print(" BENCHMARK IN-PROCESS HIỆU NĂNG: TOKENVECTOR (.EXE) VS CPYTHON 3.12")
print("==========================================================================")

# 1. SHA-256 (100,000 iterations inside TokenVector)
tkv_cmd = r'"C:\Claude AI Project\TokenVector\TokenVector - Only\examples\stdlib\bench_suite.exe"'
t_tkv, _ = run_cmd(tkv_cmd)

t0 = time.perf_counter()
for _ in range(100000):
    _ = hashlib.sha256(b"hello tokenvector benchmark").hexdigest()
t1 = time.perf_counter()
t_py = (t1 - t0) * 1000.0

print(f"[*] 1. SHA-256 Hashing (100,000 vòng lặp):")
print(f"    - TokenVector Native (.exe): {t_tkv:.2f} ms")
print(f"    - CPython 3.12             : {t_py:.2f} ms")
if t_py > t_tkv:
    print(f"    -> TokenVector nhanh hơn: {(t_py / t_tkv):.2f}x 🔥")
else:
    print(f"    -> CPython nhanh hơn: {(t_tkv / t_py):.2f}x")
print()

# 2. Math GCD (1,000,000 iterations)
def gcd_py(a, b):
    while b:
        a, b = b, a % b
    return a

t0 = time.perf_counter()
for _ in range(1000000):
    _ = gcd_py(4800, 1800)
t1 = time.perf_counter()
t_py_math = (t1 - t0) * 1000.0

print(f"[*] 2. Math GCD (1,000,000 vòng lặp):")
print(f"    - TokenVector Native (.exe): {t_tkv:.2f} ms")
print(f"    - CPython 3.12             : {t_py_math:.2f} ms")
if t_py_math > t_tkv:
    print(f"    -> TokenVector nhanh hơn: {(t_py_math / t_tkv):.2f}x 🔥")
else:
    print(f"    -> CPython 3.12: {t_py_math:.2f} ms")

print("==========================================================================")

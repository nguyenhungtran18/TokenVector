# -*- coding: utf-8 -*-
"""Benchmark day du: file size (source + compiled), so dong code, so
token, toc do bien dich, toc do chay, RAM peak - cho ca 4 hang muc Phase C,
3 ngon ngu (TokenVector/Python that/C#)."""
import subprocess
import time
import os
import re
import py_compile
import tempfile
import psutil

BASE = os.path.dirname(os.path.abspath(__file__))
N = '5000000'
CASES = ['bench_b3', 'bench_nested', 'bench_property', 'bench_multi']

TOKEN_RE = re.compile(r"[A-Za-z_]\w*|\d+\.\d+|\d+|->|==|!=|<=|>=|::|\S")


def count_loc(path):
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()
    return sum(1 for l in lines if l.strip())


def count_tokens(path):
    with open(path, encoding='utf-8') as f:
        text = f.read()
    # bo comment don gian (dong bat dau bang # sau khi strip, khong xu ly
    # comment giua dong / docstring - uoc luong tho, DU CONG BANG giua 3
    # ngon ngu vi ap dung CUNG 1 quy tac cho ca 3).
    lines = [l for l in text.split('\n') if not l.strip().startswith('#') and not l.strip().startswith('//')]
    text = '\n'.join(lines)
    return len(TOKEN_RE.findall(text))


def file_size(path):
    return os.path.getsize(path) if os.path.exists(path) else None


def run_with_peak_mem(cmd):
    t0 = time.perf_counter()
    p = psutil.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=BASE)
    peak = 0
    while p.poll() is None:
        try:
            mi = p.memory_info()
            peak = max(peak, getattr(mi, 'peak_wset', mi.rss))
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            break
        time.sleep(0.01)
    out, err = p.communicate()
    t1 = time.perf_counter()
    if p.returncode != 0:
        return None, None, f'FAIL: {err.decode(errors="replace")[:200]}'
    return t1 - t0, peak, out.decode(errors='replace').strip()


def compile_time_cs(cs_path, out_exe):
    csc = r'C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    t0 = time.perf_counter()
    r = subprocess.run([csc, '-nologo', '-optimize+', f'-out:{out_exe}', cs_path],
                        capture_output=True, text=True, cwd=BASE)
    t1 = time.perf_counter()
    if r.returncode != 0:
        raise RuntimeError(r.stdout + r.stderr)
    return t1 - t0


def compile_time_tvk(tkv_path, out_exe, entry_name):
    import sys
    sys.path.insert(0, r'C:\Claude AI Project\TokenVector')
    from tkv_compile import compile_tkv_cli
    t0 = time.perf_counter()
    compile_tkv_cli(tkv_path, out_exe, entry_name=entry_name)
    t1 = time.perf_counter()
    return t1 - t0


def compile_time_py(py_path):
    t0 = time.perf_counter()
    with tempfile.TemporaryDirectory() as td:
        py_compile.compile(py_path, cfile=os.path.join(td, 'out.pyc'), doraise=True)
    t1 = time.perf_counter()
    return t1 - t0


print(f"{'':20}{'TokenVector':>16}{'Python3':>16}{'C#':>16}")
for name in CASES:
    print(f"\n=== {name} ===")
    tvk_src = os.path.join(BASE, f'{name}.tkv')
    py_src = os.path.join(BASE, f'{name}.py')
    cs_src = os.path.join(BASE, f'{name}.cs')
    tvk_exe = os.path.join(BASE, f'{name}_tkv.exe')
    cs_exe = os.path.join(BASE, f'{name}_cs.exe')

    # 1. File size (source)
    print(f"{'Source size (bytes)':22}{file_size(tvk_src):>14}{file_size(py_src):>14}{file_size(cs_src):>14}")
    # 2. LOC
    print(f"{'LOC (non-blank)':22}{count_loc(tvk_src):>14}{count_loc(py_src):>14}{count_loc(cs_src):>14}")
    # 3. Token count
    print(f"{'Token count':22}{count_tokens(tvk_src):>14}{count_tokens(py_src):>14}{count_tokens(cs_src):>14}")
    # 4. Compile time (phai bien dich TRUOC khi do kich thuoc artifact)
    ct_tvk = compile_time_tvk(tvk_src, tvk_exe, name)
    ct_py = compile_time_py(py_src)
    ct_cs = compile_time_cs(cs_src, cs_exe)
    print(f"{'Compile time (s)':22}{ct_tvk:>14.3f}{ct_py:>14.3f}{ct_cs:>14.3f}  (py=.pyc bytecode compile, not a real 'build')")
    # 5. Compiled artifact size
    print(f"{'Compiled size (bytes)':22}{file_size(tvk_exe):>14}{'N/A (interp)':>14}{file_size(cs_exe):>14}")
    # 6. Run time + peak RAM
    tvk_t, tvk_mem, tvk_out = run_with_peak_mem([tvk_exe, N])
    py_t, py_mem, py_out = run_with_peak_mem(['py', py_src, N])
    cs_t, cs_mem, cs_out = run_with_peak_mem([cs_exe, N])
    print(f"{'Run time (s)':22}{tvk_t:>14.3f}{py_t:>14.3f}{cs_t:>14.3f}")
    print(f"{'Peak RAM (MB)':22}{tvk_mem/1e6:>14.2f}{py_mem/1e6:>14.2f}{cs_mem/1e6:>14.2f}")
    print(f"{'Output (sanity)':22}{tvk_out:>14}{py_out:>14}{cs_out:>14}")

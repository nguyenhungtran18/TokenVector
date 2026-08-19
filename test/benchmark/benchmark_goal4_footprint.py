# -*- coding: utf-8 -*-
"""Mục tiêu #4 (nhỏ gọn/thông minh/chạy cấu hình thấp) - ĐO BASELINE THẬT
(chưa tối ưu gì), lần đầu có số liệu cụ thể thay vì suy đoán kiến trúc.
So sánh 2 workload đã biên dịch+verify THẬT trước đó:
  A) fib_sum_upto - hàm nhỏ, đo overhead khởi động thuần (interpreter
     Python vs .exe CIL native).
  B) self_host_classify - suy luận MLP THẬT (đã khớp 100% sklearn, xem
     self_host_test.py) - đo footprint THỰC TẾ khi thay the sklearn/
     numpy/joblib bằng 1 file .exe độc lập (đúng use-case mục tiêu #3).
Đo: kích thước file, thời gian khởi động (cold, trung bình N lần),
peak RAM (RSS qua psutil, polling trong lúc chạy)."""
import statistics
import subprocess
import sys
import time
from pathlib import Path

import psutil

HERE = Path(__file__).parent.parent
PYTHON = sys.executable
N_RUNS = 15


def measure_run(args, cwd=None):
    """Chay 1 lan, do wall time + peak RSS (polling) - tra ve (wall_s, peak_mb, stdout)."""
    t0 = time.perf_counter()
    proc = psutil.Popen(args, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    peak_rss = 0
    while proc.poll() is None:
        try:
            rss = proc.memory_info().rss
            peak_rss = max(peak_rss, rss)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            break
    wall = time.perf_counter() - t0
    stdout, stderr = proc.communicate()
    return wall, peak_rss / (1024 * 1024), stdout.strip(), stderr


def bench(label, args, n=N_RUNS, cwd=None):
    times, peaks = [], []
    out = None
    for _ in range(n):
        w, p, o, e = measure_run(args, cwd)
        times.append(w)
        peaks.append(p)
        out = o
    return {
        'label': label,
        'median_wall_ms': round(statistics.median(times) * 1000, 1),
        'min_wall_ms': round(min(times) * 1000, 1),
        'median_peak_mb': round(statistics.median(peaks), 2),
        'sample_output': out,
    }


print("=" * 70)
print("A) fib_sum_upto: .exe (TokenVector) vs 'python -c' (interpreter startup)")
print("=" * 70)
exe_a = HERE / 'sample_alphaai_ported_fib_sum_upto.exe'
r_exe_a = bench('fib_sum_upto.exe', [str(exe_a), '10'])
r_py_a = bench('python -c fib_sum_upto(10)', [
    PYTHON, '-c',
    "def fib_sum_upto(n):\n"
    " fib=[0,1]\n"
    " for i in range(2,n): fib.append(fib[i-1]+fib[i-2])\n"
    " return sum(fib[:n])\n"
    "print(fib_sum_upto(10))"
])
for r in (r_exe_a, r_py_a):
    print(f"  {r['label']}: median={r['median_wall_ms']}ms min={r['min_wall_ms']}ms "
          f"peak_RAM={r['median_peak_mb']}MB output={r['sample_output']!r}")

print()
print("=" * 70)
print("B) self_host_classify: .exe (TokenVector, tu than) vs sklearn that (joblib+numpy+sklearn)")
print("=" * 70)
exe_b = HERE / 'self_host_classify.exe'
sample_row = ['5.1', '3.5', '1.4', '0.2']  # 1 mau Iris that
if exe_b.exists():
    r_exe_b = bench('self_host_classify.exe', [str(exe_b)] + sample_row, n=10)
    print(f"  {r_exe_b['label']}: median={r_exe_b['median_wall_ms']}ms min={r_exe_b['min_wall_ms']}ms "
          f"peak_RAM={r_exe_b['median_peak_mb']}MB output={r_exe_b['sample_output']!r}")
else:
    print("  BO QUA - self_host_classify.exe chua duoc build (chay self_host_test.py truoc)")
    r_exe_b = None

sklearn_script = (
    "import joblib, numpy as np\n"
    f"model = joblib.load(r'{HERE / 'golden_iris_model.pkl'}')\n"
    f"scaler = joblib.load(r'{HERE / 'golden_iris_scaler.pkl'}')\n"
    "from sklearn.datasets import load_iris\n"
    "names = load_iris().target_names.tolist()\n"
    "X = scaler.transform([[5.1,3.5,1.4,0.2]])\n"
    "print(names[model.predict(X)[0]])\n"
)
if (HERE / 'golden_iris_model.pkl').exists():
    r_py_b = bench('python sklearn (joblib+numpy+sklearn)', [PYTHON, '-c', sklearn_script], n=10)
    print(f"  {r_py_b['label']}: median={r_py_b['median_wall_ms']}ms min={r_py_b['min_wall_ms']}ms "
          f"peak_RAM={r_py_b['median_peak_mb']}MB output={r_py_b['sample_output']!r}")
else:
    print("  BO QUA - golden_iris_model.pkl chua co (chay golden_path_test.py truoc)")
    r_py_b = None

print()
print("=" * 70)
print("C) Kich thuoc file THAT")
print("=" * 70)
print(f"  {exe_a.name}: {exe_a.stat().st_size:,} bytes")
if exe_b.exists():
    print(f"  {exe_b.name}: {exe_b.stat().st_size:,} bytes")
print(f"  python.exe (interpreter): {Path(PYTHON).stat().st_size:,} bytes (CHUA tinh stdlib/site-packages)")

import site
sp_dirs = [Path(p) for p in site.getsitepackages() if Path(p).exists()]
for pkg in ('numpy', 'sklearn', 'joblib'):
    for spd in sp_dirs:
        pkg_dir = spd / pkg
        if pkg_dir.exists():
            total = sum(f.stat().st_size for f in pkg_dir.rglob('*') if f.is_file())
            print(f"  site-packages/{pkg}: {total:,} bytes ({total/1024/1024:.1f} MB)")
            break

print()
print("=" * 70)
print("TOM TAT (so sanh THAT, chua toi uu gi)")
print("=" * 70)
print(f"A) Overhead khoi dong: .exe {r_exe_a['median_wall_ms']}ms vs python -c "
      f"{r_py_a['median_wall_ms']}ms -> ti le {r_py_a['median_wall_ms']/max(r_exe_a['median_wall_ms'],0.01):.1f}x")
if r_exe_b and r_py_b:
    print(f"B) Suy luan MLP: .exe {r_exe_b['median_wall_ms']}ms vs sklearn that "
          f"{r_py_b['median_wall_ms']}ms -> ti le "
          f"{r_py_b['median_wall_ms']/max(r_exe_b['median_wall_ms'],0.01):.1f}x")
    print(f"   RAM: .exe {r_exe_b['median_peak_mb']}MB vs sklearn that {r_py_b['median_peak_mb']}MB")

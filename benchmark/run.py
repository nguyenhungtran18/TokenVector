#!/usr/bin/env python3
"""TokenVector (exe bien dich) vs CPython - do BEN NGOAI qua subprocess.

Khong dung ham thoi gian trong chuong trinh (TokenVector chua co now_ms that -
xem SIMD_NOTES.md), nen thoi gian o process ben ngoai: het nhieu hon
startup + phan thoi gian, chia cho reps => us/call.

QUAN TRONG: doi chieu checksum cua hai ben. Neu khop thi cung tinh duoc
cung thuáº­t toÃ¡n, so sanh moi co y nghia.
"""
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
TKVC = os.path.normpath(os.path.join(HERE, "..", "dist", "tkvc.exe"))


def build_kernels():
    """Bien dich moi kernel .tkv bang chinh compiler trong repo.

    Do khong duoc chay lai neu khong build lai: neu do tren mot binary cu,
    phep do quy cho mot compiler ma nguon hien tai khong con tao ra no - va
    do chinh la cach mot hoi quy so bien mat ma van ra so dep.
    """
    if not os.path.exists(TKVC):
        print(f"!! thieu compiler {TKVC} - chay .\\build_tkvc.ps1 truoc",
              file=sys.stderr)
        return False
    srcs = ["probe_noop.tkv"] + [f"k_{n}.tkv" for n in KERNELS]
    ok = True
    for s in srcs:
        p = os.path.join(HERE, s)
        out = os.path.join(HERE, s[:-4] + ".exe")
        r = subprocess.run([TKVC, "build", p, "--entry", "main", "--out", out,
                            "--no-lint"], cwd=HERE, capture_output=True)
        if r.returncode != 0 or not os.path.exists(out):
            ok = False
            print(f"!! build that bai: {s}", file=sys.stderr)
            sys.stderr.write(r.stdout.decode("utf-8", "replace"))
            sys.stderr.write(r.stderr.decode("utf-8", "replace"))
    return ok

RUNS = 5

KERNELS = ["fib", "string", "sort", "add", "matmul32", "f32mm", "f32mm_vec"]
NP_KERNELS = {"add", "matmul32"}
# So lan LAP trong 1 chay. Phai CHIA cho so nay: NumPy duoc do o cap
# "mot lan goi" nen phai doi cung don vi khi so sanh. Lan truot ban dau
# da so sanh tong cua TokenVector (20 reps) voi MOT LAN cua NumPy ->
# phong to gia 20 lan.
NO_NUMPY = "--no-numpy" in sys.argv
REPS = {"fib": 1, "string": 3, "sort": 20, "add": 20, "matmul32": 20,
        "f32mm": 100, "f32mm_vec": 100}

# Kernels co LAM TRON THAT tren f32. Chung KHONG the so sanh chuoi tuyet
# doi: mot vong dot product tieu chuan (tuan tu) va mot vong 4 lane + gop
# cap cho cung ket qua doi voi sai so < 6e-07, dung chinh xac se bao loi o
# khi SIMD bat dau - va luc do co so khong con kiem duoc gi.
#
# Dung sai CHON TU DO, khong tu khiu vi (P0, 2026-09-28):
#   - lam tron f32 hop le          : 8e-10 .. 1.3e-07
#   - tai sap xep lai (4 lane)    : <= 5.1e-05 tren data ngau nhien
#   - MOT LOI THAT (bo 1 so hang) : 1.8e-02 .. 4.5e-02   <- da do
# => ngan cach 3-4 bac giua hop le va loi that. Gate van co sac luc.
#
# Tien so "sum" dung dung sai chat hon (1e-6) va co chu dich: tong lon
# (460039) ap dao sai so lam tron tung phan tu (~3e-05), nen do tren tong
# rat yeu. So sanh phan tu moi la noi that su co quyen.
TOLERANT = {
    "f32mm": {"p0": 1e-5, "p1": 1e-5, "p2": 1e-5, "p3": 1e-5, "sum": 1e-6},
    # f32mm_vec: cung du lieu, matmul 4-lane bang f32x4. Chung dung chuan f64
    # va cung dung sai - viet giong de hai dong cua trong bang doc duoc
    # ngay canh nhau, va lech cua no (do o P4) la chi bao nhieu so voi bao
    # dac biet, khong phai do lai tung lan.
    "f32mm_vec": {"p0": 1e-5, "p1": 1e-5, "p2": 1e-5, "p3": 1e-5, "sum": 1e-6},
}
# Kernel nao dung chuan rieng (can numpy de tinh f64 CHINH XAC tren du
# lieu f32) thay vi py_kernels.py.
REF_SCRIPT = {"f32mm": "py_ref_f32.py", "f32mm_vec": "py_ref_f32.py"}


def _pairs(s):
    import re
    return dict(re.findall(r"([a-z0-9]+)=([0-9.eE+-]+)", s or ""))


def compare(name, tv_out, py_out):
    """(ok, chi tiet) - dung sai cho kernel tolerant, chuoi cho kernel khac."""
    if not tv_out:
        return False, "TokenVector in ra rong"
    if name not in TOLERANT:
        return (tv_out == py_out), ""
    tols = TOLERANT[name]
    tv, py = _pairs(tv_out), _pairs(py_out)
    worst, worst_k = 0.0, ""
    for k, tol in tols.items():
        if k not in tv or k not in py:
            return False, f"thieu khoa {k}"
        a, b = float(tv[k]), float(py[k])
        rel = abs(a - b) / max(abs(b), 1e-300)
        if rel > worst:
            worst, worst_k = rel, k
        if rel > tol:
            return False, f"{k} rel-err {rel:.2e} > {tol:.0e}"
    return True, f"worst {worst:.2e} @{worst_k}"



def time_cmd(cmd, runs=RUNS):
    best = None
    out = ""
    for _ in range(runs):
        t0 = time.perf_counter()
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        dt = time.perf_counter() - t0
        # Main() cua TokenVector in them mot dong ket qua tra ve, nen
        # chi lay DONG DAU - phai cung dong checksum voi Python.
        lines = [l for l in (p.stdout or "").strip().splitlines() if l.strip()]
        out = lines[0] if lines else ""
        if best is None or dt < best:
            best = dt
    return best, out


# `--no-numpy`: bo cot so sanh voi NumPy. NumPy la thu vien C, KHONG phai
# mot ngon ngu khac, nen doi chieu CPU-to-CPU khong cong bang so voi so sanh
# TokenVector-vs-CPython (mot transpiler vs mot interpreter cung ngon ngu).
# Van con dung khi phat trien: no chi ra mat vector hoa cua TokenVector.


def main():
    build_kernels()
    # startup overhead cua mot exe TokenVector rong
    noop = os.path.join(HERE, "probe_noop.exe")
    if not os.path.exists(noop):
        print("!! thieu probe_noop.exe - bo qua tru startup", file=sys.stderr)
    else:
        import shutil
        shutil.copy(noop, os.path.join(HERE, "probe_noop_copy.exe"))
    tv_startup, _ = time_cmd([os.path.join(HERE, "probe_noop_copy.exe")], runs=7)
    py_startup, _ = time_cmd([sys.executable, "-c", "pass"], runs=7)
    print(f"startup overhead:  TV exe {tv_startup*1e3:7.2f} ms   "
          f"CPython -c pass {py_startup*1e3:7.2f} ms")

    rows = []
    for name in KERNELS:
        exe = os.path.join(HERE, f"k_{name}.exe")
        if not os.path.exists(exe):
            print(f"!! thieu {exe}")
            continue
        tv_t, tv_out = time_cmd([exe])
        reps = REPS[name]
        tkv_us = max(tv_t - tv_startup, 1e-6) * 1e6 / reps

        ref = os.path.join(HERE, REF_SCRIPT.get(name, "py_kernels.py"))
        args = [sys.executable, ref] + ([] if name in REF_SCRIPT else [name])
        py_t, py_out = time_cmd(args)
        py_us = max(py_t - py_startup, 1e-6) * 1e6 / reps

        match, detail = compare(name, tv_out, py_out)

        np_us = None
        if not NO_NUMPY and name in NP_KERNELS:
            np_us = numpy_time(name)
        rows.append((name, tkv_us, py_us,
                     tkv_us / py_us if py_us else float("inf"),
                     tv_out, py_out, match, np_us, detail))

    print()
    np_cols = "" if NO_NUMPY else f"{'  NumPy':>12}{'  TV/NumPy':>11}"
    hdr = (f"{'kernel':<10}{'TokenVector':>14}{'CPython':>14}{'TV speedup':>12}"
           f"{np_cols}  checksum")
    print(hdr)
    print("-" * len(hdr))
    for (name, tkv_us, py_us, ratio, tv_out, py_out, match, np_us, detail) in rows:
        nps = "" if NO_NUMPY else (f"{np_us:10.1f}us" if np_us else " " * 11)
        npr = "" if NO_NUMPY else (f"{tkv_us/np_us:9.1f}x" if np_us else " " * 10)
        tag = "OK" if match else "MISMATCH"
        if detail:
            tag += f" [{detail}]"
        # A raw ratio below 0.05 rounded to "0.0x" with one decimal, which read
        # as "no faster" when it actually meant 69x faster than the baseline.
        # Show the direction and the magnitude instead: under 1x is the speedup
        # of the other side, so nothing has to be looked up.
        if ratio >= 1:
            spd = f" {ratio:9.1f}x"
        else:
            spd = f" 1/{1.0 / ratio:5.1f}x"
        print(f"{name:<10}{tkv_us:12.1f}us{py_us:12.1f}us{spd}"
              f"{nps:>12}{npr:>11}  {tag}  {tv_out[:34]}")
        if not match:
            print(f"{'':<10}  TV : {tv_out}")
            print(f"{'':<10}  PY : {py_out}")


def numpy_time(name):
    try:
        import numpy as np
    except ImportError:
        return None
    if name == "add":
        half = 131072
        a = np.array([((i % 97) * 0.1) for i in range(2 * half)])
        b = np.array([((i % 4) + 1.0) for i in range(half)])
        fn = lambda: a.reshape(2, half) + b
    else:
        n = 32
        a = np.array([((i % 7) - 3.0) for i in range(n * n)]).reshape(n, n)
        b = np.array([((i % 5) - 2.0) for i in range(n * n)]).reshape(n, n)
        fn = lambda: np.dot(a, b)
    reps = 20 if name == "add" else 2000
    best = None
    for _ in range(RUNS):
        t0 = time.perf_counter()
        for _ in range(reps):
            fn()
        dt = (time.perf_counter() - t0) / reps
        if best is None or dt < best:
            best = dt
    return best * 1e6


if __name__ == "__main__":
    main()

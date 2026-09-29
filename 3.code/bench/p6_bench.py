# -*- coding: utf-8 -*-
"""P6-4: do hieu qua cua bo TU DONG vector hoa (P6).

Khac voi `run.py` o cho: run.py so TokenVector voi CPython/NumPy con tren
CAC KERNEL DA VIET TAY. Doi voi P6, cau hoi la "compiler co bien dich vong
lap nay nhanh hon bao nhieu" - so sanh CHINH compiler voi chinh no, khong phai
so voi Python. Chay mot phep cong trong Python de lam moc thu phu khong them
gi vao hieu qua do, chi lam cham ban do.

VI DO THIET KE QUAN TRONG: hai ban `k_p6_vec.tkv` va `k_p6_scalar.tkv` giong
het nhau - cung du lieu, cung phep tinh, cung so lan lap - va chi khac o DIEU
KIEN vong lap: `while i < nb` (bien, P6 vector hoa) voi `while i < 262144`
(hang so, P3 tu choi). Khac biet thoi gian do ra cong **hieu qua cua P6**.

`p6_bench.py` tu kiem tra ca hai dieu kien do truoc khi in so:
  1. IL cua ban vector CO `stobj`/`_vstart`, ban scalar KHONG co. Neu compiler
     bat dau rut gon hang so thanh bien, hai ban se trung nhau va phep do
     khong con do gi.
  2. Hai ban cho cung checksum - trung nhau ve mat SO HOC.

Chay:  python .\\p6_bench.py
"""

import os
import re
import subprocess
import sys
import time

# Console Windows mac dinh cp1252, khong in duoc dau tieng Viet. Chuyen sang
# UTF-8 va bo qua ky tu khong hien thi duoc thay vi nem UnicodeEncodeError
# giua chung run.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
TKVC = os.path.normpath(os.path.join(HERE, "..", "dist", "tkvc.exe"))
TMP = os.path.join(os.environ.get("TEMP", HERE), "tkv_p6_bench")

RUNS = 9

# (N, reps) - chon de tong cong viec gan nhau (~16-26M phep) o moi dong, de
# thoi gian do duoc so sanh y nhau chu khong noi mot bien do kieu khac.
SIZES = [
    (4096, 4000),
    (16384, 1000),
    (65536, 400),
    (262144, 60),
]


def _die(msg):
    print("!! " + msg, file=sys.stderr)
    sys.exit(1)


def build(src_name, n, reps, tag):
    src = os.path.join(HERE, src_name)
    text = open(src, encoding="utf-8").read()
    # Bien doi kich thuoc. `while i < 262144:` la HANG SO trong ban scalar -
    # rut gon no thanh bien se lam hai ban trung nhau va phep do mat nghia.
    text = text.replace("n = 262144", "n = %d" % n)
    text = text.replace("reps = 40", "reps = %d" % reps)
    text = text.replace("while i < 262144:", "while i < %d:" % n)
    path = os.path.join(TMP, tag + ".tkv")
    exe = os.path.join(TMP, tag + ".exe")
    il = exe + ".il"
    for f in (path, exe, il):
        if os.path.exists(f):
            os.remove(f)
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(text)
    r = subprocess.run([TKVC, "build", path, "--entry", "main", "--out", exe,
                        "--emit-il", "--no-lint"], capture_output=True, cwd=HERE)
    if r.returncode != 0 or not os.path.exists(exe):
        sys.stderr.write(r.stdout.decode("utf-8", "replace"))
        sys.stderr.write(r.stderr.decode("utf-8", "replace"))
        _die("build that bai: " + tag)
    return exe, open(il, encoding="utf-8", errors="replace").read()


def run_once(exe):
    r = subprocess.run([exe], capture_output=True, cwd=HERE)
    return r.stdout.decode("utf-8", "replace").strip()


def median_time(exe):
    ts = []
    for _ in range(RUNS):
        s = time.perf_counter()
        subprocess.run([exe], capture_output=True, cwd=HERE)
        ts.append(time.perf_counter() - s)
    ts.sort()
    return ts[len(ts) // 2]


def startup():
    """Chi phi khoi dong mot exe rong - phai tru ra khi do phan tinh."""
    noop = os.path.join(HERE, "probe_noop.exe")
    if not os.path.exists(noop):
        return 0.0
    ts = []
    for _ in range(RUNS):
        s = time.perf_counter()
        subprocess.run([noop], capture_output=True, cwd=HERE)
        ts.append(time.perf_counter() - s)
    ts.sort()
    return ts[len(ts) // 2]


def main():
    if not os.path.exists(TKVC):
        _die("thieu compiler %s - chay .\\build_tkvc.ps1 truoc" % TKVC)
    os.makedirs(TMP, exist_ok=True)

    s0 = startup()
    print("startup exe rong : %6.2f ms   (tru khoi doan nay)" % (s0 * 1e3))
    print("moi lan chay lay trung vị cua %d lan" % RUNS)
    print()

    hdr = ("%-9s %-9s %-10s %11s %11s %9s %s"
           % ("N", "reps", "cong viec", "scalar", "tu dong", "tang toc", "checksum"))
    print(hdr)
    print("-" * len(hdr))

    ratios = []
    for n, reps in SIZES:
        ev, ilv = build("k_p6_vec.tkv", n, reps, "p6v_%d" % n)
        es, ils = build("k_p6_scalar.tkv", n, reps, "p6s_%d" % n)

        # Dieu kien 1: transform co that su khac nhau giua hai ban.
        if "stobj" not in ilv or "_vstart" not in ilv:
            _die("ban vector khong co vong vector (stobj/_vstart) - "
                 "P6 khong chay, phep do vo nghia")
        if "stobj" in ils or "_vstart" in ils:
            _die("ban scalar LAI bi vector hoa (co stobj/_vstart) - "
                 "dieu kien vong lap da khong con la hang so")

        # Dieu kien 2: hai ban cho cung ket qua so hoc.
        ov, os_ = run_once(ev), run_once(es)
        if ov != os_:
            _die("checksum KHAC NHAU: vector=%r scalar=%r" % (ov, os_))

        tc = max(median_time(ev) - s0, 1e-9)
        ts = max(median_time(es) - s0, 1e-9)
        ratios.append(ts / tc)
        print("%-9d %-9d %-10s %9.1fms %9.1fms %8.2fx %s"
              % (n, reps, "%.1fM" % (n * reps / 1e6), ts * 1e3, tc * 1e3,
                 ts / tc, ov.splitlines()[0]))

    print()
    print("tap 3 bo dem: 4096 -> 48 KB (vua L2) ... 262144 -> 3 MB (vuot L2)")
    print("tang toc tot nhat  : %.2fx" % max(ratios))
    print("tang toc kiem lai  : %.2fx" % ratios[-1])
    print()
    print("Ly do chua dat 4x (do bang lenh IL that, khong doan):")
    print("  vong vector cua ban vector co 42 lenh IL cho MOI 4 phan tu. Trong do")
    print("  20 lenh KHONG lam phep tinh nao - chi tinh dia chi byte cho 3 toan")
    print("  so (a, b, r): moi toan so ton 7 lenh vi chi so la TkvInt (int64 co")
    print("  kiem tra tran) nen phai conv.i4, conv.i8, mul.ovf, add, conv.i.")
    print("  ~10 lenh moi la viec that: 2 ldobj, 1 op_Addition, 1 stobj.")
    print("  => cong viec tinh dia chi dat gap hon 2 lan cong viec vector.")
    print("  Do la han chan san cua P6, khong phai loi.")
    print()
    print("Buoc toi: giu mot con tro byte tach rieng tang 16 moi vong lap, thay vi")
    print("tinh lai i*3 lan moi phan tu. Bien 'i' van phai dung cho dieu kien")
    print("thoat nen khong bo duoc, nhung co the thu h Narrow ve i32 trong khi")
    print("do - phai canh giac vi bien nguoi dung co the lon hon int32.")


if __name__ == "__main__":
    main()

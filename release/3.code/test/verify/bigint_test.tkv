# -*- coding: utf-8 -*-
"""Kieu 'int' = so nguyen VO HAN CHU SO nhu Python (moc 6 buoc 2, 2026-08-05).

Bat bien cua du an: mot file .tkv chay bang CPython va chinh no bien dich
ra .exe phai cho ket qua GIONG HET. Truoc ban va nay, bat bien do vo im
lang o phep tinh binh thuong nhat:

    fact(13)  CPython 6227020800           TokenVector 1932053504
    fact(20)  CPython 2432902008176640000  TokenVector -2102132736
    2**31     CPython 2147483648           TokenVector -2147483648  (AM)

Test nay doi chieu BA phia, khong phai hai:
  1. .exe da bien dich  (duong THAT su duoc kiem)
  2. chinh file .tkv chay duoi CPython (bat bien cua du an)
  3. gia tri toan hoc tu thu vien chuan Python (su that nen)

Phia 3 la ly do test nay khong the "uon theo loi": neu ca compiler lan
file .tkv cung sai mot kieu, math.factorial van to cao.
"""
import math
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli  # noqa: E402

TKV = ROOT / 'test' / 'sample_bigint.tkv'


def _cpython_run():
    """Nap chinh file .tkv duoi CPython - annotation la chuoi nen Python
    khong dien giai gi, than ham la Python thuan."""
    ns = {}
    exec(compile(TKV.read_text(encoding='utf-8'), str(TKV), 'exec'), ns)
    return ns['run']


CASES = [
    # (what, n, gia tri dung theo thu vien chuan Python)
    ('fact', 0, math.factorial(0)),
    ('fact', 12, math.factorial(12)),   # con vua i32? KHONG - 479001600 vua, ranh gioi
    ('fact', 13, math.factorial(13)),   # tran i32 - ca lam sai am tham truoc day
    ('fact', 20, math.factorial(20)),   # tran i64
    ('fact', 30, math.factorial(30)),
    ('fact', 50, math.factorial(50)),   # 65 chu so
    ('pow2', 30, 2 ** 30),
    ('pow2', 31, 2 ** 31),              # 2**31: truoc day ra SO AM
    ('pow2', 63, 2 ** 63),              # tran i64 o phep CONG (r + r)
    ('pow2', 100, 2 ** 100),
    ('pow2', 200, 2 ** 200),
    ('sum', 100, 100 * 101 // 2),
    ('sum', 1000, 1000 * 1001 // 2),
    ('minus', 30, 0),                   # a - b voi a,b deu la so lon
    ('cmp', 30, 1),                     # ==, >, < tren so lon
]


def main():
    exe = compile_tkv_cli(str(TKV), out_exe=str(ROOT / 'test' / '_bigint_test.exe'),
                          entry_name='run')
    py_run = _cpython_run()
    fails = []
    for what, n, expected in CASES:
        want = str(expected)
        got_py = str(py_run(what, str(n)))
        r = subprocess.run([str(exe), what, str(n)], capture_output=True, text=True)
        got_exe = r.stdout.strip()
        if got_exe != want:
            fails.append(f'{what}({n}): .exe cho {got_exe!r}, dung phai {want!r}'
                         + (f'  [stderr: {r.stderr.strip()[:160]}]' if r.stderr.strip() else ''))
        if got_py != want:
            fails.append(f'{what}({n}): .tkv duoi CPython cho {got_py!r}, dung phai {want!r}')
        if got_py != got_exe:
            fails.append(f'{what}({n}): HAI PHIA LECH NHAU - CPython {got_py!r} vs .exe {got_exe!r}')

    if fails:
        print('bigint_test: TRUOT')
        for f in fails:
            print('  -', f)
        return 1
    print(f'bigint_test: dat ({len(CASES)} ca, 3 phia doi chieu)')
    return 0


if __name__ == '__main__':
    sys.exit(main())

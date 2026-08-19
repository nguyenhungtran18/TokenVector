# -*- coding: utf-8 -*-
"""'//' '%' '**' va '-x' tren kieu 'int' (moc 6 lat 2, 2026-08-05).

Lat 1 lam '+' '-' '*' va so sanh. Lat nay lam bon phep con lai. Ba cho
de lech AM THAM, va test duoi day nham thang vao ca ba:

  1. DAU. CIL 'div'/'rem' VA BigInteger.Divide/Remainder deu cat ve 0;
     Python lam tron ve am vo cuc. Trung nhau khi hai toan hang cung dau
     -> ai chi test so duong se thay moi thu xanh muot.
       Python: -7 // 2 == -4,  -7 % 3 == 2,  7 % -3 == -2
       .NET  : -7 /  2 == -3,  -7 rem 3 == -1, 7 rem -3 == 1
  2. DO CHINH XAC CUA '**'. Duong i32/i64 dung Math::Pow (float64) va tra
     ve XAP XI: 3**40 ra ...929000 thay vi ...928801. Sai o chu so thu
     15, khong ai nhin bang mat ma thay.
  3. TRAN o hai bien: MIN_VALUE / -1 va -MIN_VALUE khong vua int64.

Doi chieu BA phia nhu bigint_test.py: .exe da bien dich, chinh file .tkv
chay duoi CPython, va gia tri viet thang bang bieu thuc Python o duoi.
Phia thu ba la ly do test nay khong the "uon theo loi".
"""
import math
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli  # noqa: E402

TKV = ROOT / 'test' / 'sample_bigint_divmod.tkv'


def _cpython_run():
    ns = {}
    exec(compile(TKV.read_text(encoding='utf-8'), str(TKV), 'exec'), ns)
    return ns['run']


_F25 = 15511210043330985984000000        # 25!
_F30 = 265252859812191058636308480000000  # 30!

CASES = [
    # '//' - bon to hop dau, gia tri dung do CHINH CPython tinh o day
    ('div', 0, 7 // 2),
    ('div', 1, -7 // 2),      # -4, KHONG phai -3
    ('div', 2, 7 // -2),      # -4
    ('div', 3, -7 // -2),     # 3
    # '%' - dau ket qua theo SO CHIA (nguoc voi .NET, theo so bi chia)
    ('mod', 0, 7 % 3),
    ('mod', 1, -7 % 3),       # 2, KHONG phai -1
    ('mod', 2, 7 % -3),       # -2
    ('mod', 3, -7 % -3),      # -1
    # '**' - chinh xac tuyet doi, khong phai xap xi float64
    ('pow', 0, 3 ** 40),
    ('pow', 1, 2 ** 100),     # vuot xa int64
    ('pow', 2, (-3) ** 41),   # co so am, so mu le -> ket qua am
    ('pow', 3, 10 ** 0),      # so mu 0
    # duong CHAM: toan hang la BigInteger that
    ('bigdiv', 25, math.factorial(25) // math.factorial(24)),
    ('bigdiv', 30, math.factorial(30) // math.factorial(29)),
    ('bigdivneg', 25, -math.factorial(25) // math.factorial(24)),
    ('bigdivneg', 30, -math.factorial(30) // math.factorial(29)),
    ('bigmod', 0, _F25 % 1000000007),
    ('bigmod', 1, -_F25 % 1000000007),
    ('bigmod', 2, _F25 % -1000000007),
    ('bigmod', 3, -_F25 % -1000000007),
    # '-x' tren ca hai duong
    ('neg', 0, -5),
    ('neg', 1, -_F30),
    ('neg', 2, _F30),
]


def main():
    exe = compile_tkv_cli(str(TKV),
                          out_exe=str(ROOT / 'test' / '_bigint_divmod_test.exe'),
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
            fails.append(f'{what}({n}): HAI PHIA LECH NHAU - '
                         f'CPython {got_py!r} vs .exe {got_exe!r}')

    if fails:
        print('bigint_divmod_test: TRUOT')
        for f in fails:
            print('  -', f)
        return 1
    print(f'bigint_divmod_test: dat ({len(CASES)} ca, 3 phia doi chieu)')
    return 0


if __name__ == '__main__':
    sys.exit(main())

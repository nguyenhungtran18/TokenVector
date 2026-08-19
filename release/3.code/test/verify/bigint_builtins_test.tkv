# -*- coding: utf-8 -*-
"""int()/abs()/min()/max()/sum() tren kieu 'int' (moc 6 lat 3, 2026-08-05).

Nam builtin nay la cho ma THAT cham vao kieu 'int' nhieu nhat sau bon
phep so hoc, va truoc ban va nay ca nam deu hong theo BA kieu khac nhau:

  1. sum/min/max BAO LOI ro rang ("chi ap dung cho list/set SO") - kieu
     'int' khong nam trong _NUMERIC_DTYPES. On ao, nhung van la be tac.
  2. abs() sinh 'call valuetype TkvInt [mscorlib]System.Math::Abs(...)'
     - mot overload KHONG TON TAI. ilasm van ra file .exe.
  3. int() nguy hiem nhat vi no AM THAM: no di Int32.Parse roi de
     _widen_if_needed nang ket qua int32 len 'int'. Nghia la
     int("99999999999999999999") NEM trong khi Python tra ve dung so -
     tuc la o dung cho kieu 'int' sinh ra de giai quyet, no van hong.

Doi chieu BA phia moi ca: gia tri toan hoc doc lap (math.factorial),
chinh file .tkv chay bang CPython, va .exe da bien dich."""
import math
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli  # noqa: E402

TKV = ROOT / 'test' / 'sample_int_builtins.tkv'

F = math.factorial


def _cpython_run():
    ns = {}
    exec(compile(TKV.read_text(encoding='utf-8'), str(TKV), 'exec'), ns)
    return ns['run']


CASES = [
    # sum(list[int]): vuot int64 tu n=21 tro di
    ('sum', '25', sum(F(i) for i in range(1, 26))),
    ('sum', '12', sum(F(i) for i in range(1, 13))),   # con vua i64
    ('sum', '1', 1),
    # sum() voi PHAN TU vua int64 nhung TONG thi khong: ca duy nhat di
    # vao duong nhanh cua TkvInt::Add roi tran o do. Thieu no thi moi ca
    # sum() deu co phan tu da la BigInteger san (AD_SLOW ngay tu dau) va
    # phep kiem tran cua duong nhanh KHONG he duoc chay - do chung bang
    # dot bien: bo han phep kiem do ma bo test van xanh.
    ('sumrep', '20', 5 * F(20)),      # 5 x 2432902008176640000 > 2^63
    ('sumrep', '10', 5 * F(10)),      # khong tran - duong nhanh sach
    # max/min tren list[int] - so sanh phai qua TkvInt::Cmp
    ('max', '25', F(25)),
    ('min', '25', 1),
    ('max', '12', F(12)),
    # abs(): duong am (phai negate) va duong duong (tra thang)
    ('absneg', '25', F(25)),
    ('absneg', '20', F(20)),          # 2432902008176640000 - VUA int64
    ('abspos', '25', F(25)),
    ('abspos', '1', 1),
    # int(str): CHINH la ca ma ban cu NEM
    ('parse', '99999999999999999999', 10 ** 20),
    ('parse', '-99999999999999999999', int('-99999999999999999999') + 1),
    ('parse', '42', 43),
    ('parse', ' 42 ', 43),            # Python bo qua khoang trang hai dau
    # int(float): CAT VE 0 ca hai chieu, va dung o do lon vuot int64
    ('parsefloat', '3.7', 3),
    ('parsefloat', '-3.7', -3),
    ('parsefloat', '1e30', int(1e30)),   # float64 1e30 KHONG phai 10**30
    # min(a,b)/max(a,b) 2 tham so - macro ternary, kiem ca duong so sanh
    ('minmax2', '25', 1),
    # any()/all() tren list[int]: xs = [fact(n), 0] -> any dung, all sai.
    # Ca 0 la BAT BUOC, no la ca duy nhat phan biet duoc IsZero that voi
    # mot ham luon tra 0.
    ('anyall', '25', 1),
    ('anyall', '3', 1),
    # CANH GAC khong-regress: duong i32 cu phai y nguyen
    ('i32', '5', 5 + 7 + 7 + 5 + 5 + 7),
]


def main():
    exe = compile_tkv_cli(str(TKV),
                          out_exe=str(ROOT / 'test' / '_int_builtins_test.exe'),
                          entry_name='run')
    py_run = _cpython_run()
    fails = []
    for what, n, expected in CASES:
        want = str(expected)
        got_py = str(py_run(what, n))
        r = subprocess.run([str(exe), what, n], capture_output=True, text=True)
        got_exe = r.stdout.strip()
        if got_py != want:
            fails.append(f'{what}({n!r}): .tkv duoi CPython cho {got_py!r}, '
                         f'dung phai {want!r}')
        if got_exe != want:
            fails.append(f'{what}({n!r}): .exe cho {got_exe!r}, dung phai {want!r}'
                         + (f'  [stderr: {r.stderr.strip()[:200]}]'
                            if r.stderr.strip() else ''))
        if got_py != got_exe:
            fails.append(f'{what}({n!r}): HAI PHIA LECH NHAU - '
                         f'CPython {got_py!r} vs .exe {got_exe!r}')

    # Canh gac: neu khong con ca nao vuot int64 thi bo test nay chi chung
    # minh "int nho chay duoc" va se van xanh khi duong BigInteger hong.
    if not any(abs(e) > 2 ** 63 for _w, _n, e in CASES):
        fails.append('bo ca khong con ca nao vuot int64 - test da mat rang')

    if fails:
        print('bigint_builtins_test: TRUOT')
        for f in fails:
            print('  -', f)
        return 1
    print(f'bigint_builtins_test: dat ({len(CASES)} ca, 3 phia doi chieu)')
    return 0


if __name__ == '__main__':
    sys.exit(main())

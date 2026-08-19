# -*- coding: utf-8 -*-
"""print() + MOT duong str() duy nhat cho so thuc (moc 7, 2026-08-05).

Hai thu duoc ghim o day:

  1. 'print' truoc ban va nay KHONG TON TAI. Mot file .tkv chay duoc bang
     CPython nhung khong bien dich duoc neu no in bat cu thu gi - tuc bat
     bien cot loi cua du an khong kiem chung duoc tren chinh cach quan
     sat pho bien nhat.

  2. str(float) phai khop repr cua Python TUNG KY TU. Duong cu dung
     ToString("R") cua .NET Framework, va "R" KHONG cho chuoi ngan nhat:
     123456789012345.6 ra "123456789012345.59". Nay di G15->G16->G17.
     Ba cho khac ve DINH DANG cung duoc ghim: nguong 10^15 (.NET) vs
     10^16 (Python), 'E' vs 'e', va inf/nan/-0.0.

Corpus sinh bang CACH CHAY CPython (khong phai bang loi khang dinh
CPython lam gi) - dung nguyen tac cua ke hoach giai doan 4."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli  # noqa: E402

TKV = ROOT / 'test' / 'sample_print_float.tkv'

# Cac ca BIEN: moi ca danh vao mot cho .NET va Python khac nhau.
VALUES = [
    '0.1', '0.5', '1.0', '2.675', '3.14159265358979',
    '0.30000000000000004',            # tong 0.1+0.2 - ca kinh dien cua "R"
    '123456789012345.6',              # "R" cho ...59, chuoi ngan nhat la ...6
    '1e15', '1.5e15', '9.99e15',      # nguong .NET (E) khac nguong Python
    '1e16', '1e17', '1e22', '1e100',  # dang khoa hoc: 'e' thuong, mu 2 chu so
    '1e-4', '1e-5', '1e-10',          # nguong am
    '0.0', '-1.5',
    '1e308',
    '2.2250738585072014e-308',
    'inf', '-inf', 'nan',
]


def _cpython_run():
    ns = {}
    exec(compile(TKV.read_text(encoding='utf-8'), str(TKV), 'exec'), ns)
    return ns


def main():
    ns = _cpython_run()
    exe = compile_tkv_cli(str(TKV), out_exe=str(ROOT / 'test' / '_print_float_test.exe'),
                          entry_name='run')
    fails = []
    for v in VALUES:
        for what in ('fmt', 'expr'):
            want = str(ns['run'](what, v))
            r = subprocess.run([str(exe), what, v], capture_output=True, text=True)
            got = r.stdout.strip()
            if got != want:
                fails.append(f'{what}({v!r}): .exe {got!r}, CPython {want!r}'
                             + (f'  [{r.stderr.strip()[:120]}]' if r.stderr.strip() else ''))
    # -0.0 KHONG di duong float("-0.0") duoc: Double.Parse cua .NET
    # Framework tra ve KHONG AM cho chuoi do (da sua o .NET Core 3.0).
    # Do la lech cua duong VAO, khong phai cua str() - nen -0.0 duoc tao
    # bang phep tinh trong chinh ngon ngu (0.0 * -1.0), va cho do str()
    # phai in '-0.0' nhu Python.
    for v in ('-1.0', '-2.5', '1.0'):
        want = str(ns['run']('negzero', v))
        r = subprocess.run([str(exe), 'negzero', v], capture_output=True, text=True)
        if r.stdout.strip() != want:
            fails.append(f'negzero({v}): .exe {r.stdout.strip()!r}, CPython {want!r}')

    # LECH DA BIET, ghim HAI CHIEU (xem giai doan 1.3 cua ke hoach): khi
    # chuoi ngan nhat co 17 chu so VA co hai ban 17 chu so cung doc lai
    # dung, G17 cua .NET lam tron ra xa 0 con Python chon ban GAN nhat.
    #   2000000000000000.25  ->  .NET '...0.3'   Python '...0.2'
    # Sua that su can port Grisu/Ryu (moc 15). Neu ca nay tu nhien khop,
    # test bao de doi trang thai - khong de no am tham bien mat.
    _gap_v = '1000000000000000.1'
    _gap_want = str(ns['run']('expr', _gap_v))
    _gap_got = subprocess.run([str(exe), 'expr', _gap_v],
                              capture_output=True, text=True).stdout.strip()
    if _gap_got == _gap_want:
        fails.append(f'LECH DA BIET expr({_gap_v}) nay da KHOP ({_gap_got!r}) - '
                     f'co ve da sua, hay cap nhat so lech va bo ghim nay')

    for n in ('0', '7', '-3', '1000000'):
        want = str(ns['run']('int', n))
        r = subprocess.run([str(exe), 'int', n], capture_output=True, text=True)
        if r.stdout.strip() != want:
            fails.append(f'int({n}): .exe {r.stdout.strip()!r}, CPython {want!r}')

    # print(): so dong VA noi dung phai khop CPython y het.
    exe_show = compile_tkv_cli(str(TKV), out_exe=str(ROOT / 'test' / '_print_show_test.exe'),
                               entry_name='show')
    import io
    import contextlib
    # Cac gia tri o day di qua bo doc tham so cua entry CLI (Main), von
    # dung Double.Parse cua .NET Framework - nen KHONG dung '-0.0'/'nan'
    # o day (xem ghi chu ve Parse o tren); chung da duoc phu qua 'negzero'
    # va qua duong str() ben tren roi.
    for v in ('0.1', '1e16', '1e-5', '-1.5'):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ns['show'](float(v))
        want = buf.getvalue().replace('\r\n', '\n')
        r = subprocess.run([str(exe_show), v], capture_output=True, text=True)
        # entry tra i32 -> dong cuoi la gia tri tra ve cua chinh ham
        got = r.stdout.replace('\r\n', '\n')
        got = got[:got.rfind('0\n')] if got.rstrip().endswith('0') else got
        if got != want:
            fails.append(f'print({v}): .exe {got!r}, CPython {want!r}')

    if fails:
        print('print_float_test: TRUOT')
        for f in fails:
            print('  -', f)
        return 1
    print(f'print_float_test: dat ({len(VALUES)} gia tri x 2 duong + 4 ca print)')
    return 0


if __name__ == '__main__':
    sys.exit(main())

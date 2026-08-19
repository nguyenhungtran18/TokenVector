# -*- coding: utf-8 -*-
"""'int' lam PHAN TU cua list/dict (moc 6 lat 2, 2026-08-05).

Duong list/dict di qua List`1/Dictionary`2, va chung tra cuu kieu phan
tu qua IL_SCALAR - da co tu lat 1. Cai THAT SU con thieu khong phai
bang kieu ma la hai dieu duoi day, ca hai deu la chuyen BINH THUONG chu
khong phai ca la, va ca hai deu chan dung viec dung 'int' trong ma that:

  1. Trong mot ham tra ve 'int', MOI bien khong chu thich la 'int' - KE
     CA bien dem vong lap. Nen 'xs[j]' voi j la bien dem la cach viet
     thuong nhat tren doi, va truoc ban va nay no bao loi "khong tu dong
     chuyen 'int' sang 'i32'". Nay chi so di qua TkvInt::ToI32, thu hep
     CO KIEM TRA (conv.ovf.i4 - khong vua thi NEM, khong cat).

  2. Ham nhan tham so 'i32' ma duoc goi voi mot 'int' VAN bao loi, va
     dieu do la DUNG: mot so vo han chu so khong the vao mot o int32.

Cac ca duoi day co gia tri toi 10^32 - vuot xa int64 - nen chung that su
di duong BigInteger BEN TRONG mot List/Dictionary, khong phai chi vua
i64 roi may man.
"""
import math
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli  # noqa: E402

TKV = ROOT / 'test' / 'sample_int_container.tkv'


def _cpython_run():
    ns = {}
    exec(compile(TKV.read_text(encoding='utf-8'), str(TKV), 'exec'), ns)
    return ns['run']


CASES = [
    # list: append + doc theo chi so (chi so LA mot bien 'int')
    ('list', 25, sum(math.factorial(i) for i in range(1, 26))),
    ('list', 30, sum(math.factorial(i) for i in range(1, 31))),
    ('list', 1, 1),
    # list: GHI theo chi so (stelem/set_Item)
    ('listset', 30, 2 * math.factorial(30)),
    ('listset', 12, 2 * math.factorial(12)),   # con vua i64 - duong nhanh
    # dict[str,int]: ghi, doc, va truyen ca dict lam THAM SO
    ('dict', 30, 1),
    ('dict', 50, 1),
    ('dictarg', 30, 2 * math.factorial(30)),
    ('dictarg', 50, 2 * math.factorial(50)),
]


def main():
    exe = compile_tkv_cli(str(TKV),
                          out_exe=str(ROOT / 'test' / '_int_container_test.exe'),
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
            fails.append(f'{what}({n}): .tkv duoi CPython cho {got_py!r}, '
                         f'dung phai {want!r}')
        if got_py != got_exe:
            fails.append(f'{what}({n}): HAI PHIA LECH NHAU - '
                         f'CPython {got_py!r} vs .exe {got_exe!r}')

    # Chi so KHONG VUA int32 phai NEM, khong duoc cat am tham. Hai ca,
    # danh vao HAI nhanh khac nhau cua TkvInt::ToI32:
    #   fact(20) = 2432902008176640000  -> big == null, duong 'conv.ovf.i4'
    #   fact(25) = 1.55e25              -> big != null, duong chan rieng
    # Thieu hai ca nay thi ToI32 khong co rang: doi 'conv.ovf.i4' thanh
    # 'conv.i4' hay bo han nhanh chan 'big' deu lot luoi (da do that).
    for k, why in ((20, 'vua int64, big == null'), (25, 'phai BigInteger')):
        r = subprocess.run([str(exe), 'badindex', str(k)],
                           capture_output=True, text=True)
        if r.returncode == 0:
            fails.append(f'badindex({k}) [{why}]: chi so {math.factorial(k)} '
                         f'khong vua int32, le ra phai NEM, nhung cho '
                         f'{r.stdout.strip()!r}')
    # Ca AC Y nhat, va la ca duy nhat phan biet duoc 'conv.ovf.i4' voi
    # 'conv.i4': chi so 2^32 co 32 BIT THAP BANG 0, nen cat di se ra
    # dung 0 - mot chi so HOP LE. Hai ca tren khong phan biet duoc vi
    # phan cat cua chung tinh co van nam ngoai pham vi list, nen chuong
    # trinh van nem (ArgumentOutOfRange) va test van xanh nham.
    r = subprocess.run([str(exe), 'badindexlow0', '32'],
                       capture_output=True, text=True)
    if r.returncode == 0:
        fails.append('badindexlow0(32): chi so 2^32 khong vua int32, le ra '
                     f'phai NEM; cat 32 bit thap se ra chi so 0 HOP LE va '
                     f'tra ve am tham {r.stdout.strip()!r}')
    # Canh gac: it nhat mot ca phai VUOT int64, neu khong bo test nay chi
    # chung minh 'int nho chay duoc' va se van xanh khi duong BigInteger
    # trong container hong hoan toan.
    if not any(abs(e) > 2 ** 63 for _w, _n, e in CASES):
        fails.append('bo ca khong con ca nao vuot int64 - test da mat rang')

    if fails:
        print('bigint_container_test: TRUOT')
        for f in fails:
            print('  -', f)
        return 1
    print(f'bigint_container_test: dat ({len(CASES)} ca + 3 ca phai nem, 3 phia doi chieu)')
    return 0


if __name__ == '__main__':
    sys.exit(main())

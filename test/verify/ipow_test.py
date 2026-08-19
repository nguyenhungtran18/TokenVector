# -*- coding: utf-8 -*-
"""'**' tren SO NGUYEN i32/i64 phai chinh xac tuyet doi (2026-08-05).

Truoc ban va nay, 'a ** b' voi a,b nguyen di System.Math::Pow, tuc
float64, tuc XAP XI - roi conv.i8 cat phan le. Do that tren ban chua sua:

    3**35   TokenVector 50031545098999704    CPython 50031545098999707
    3**38   TokenVector 1350851717672992000  CPython 1350851717672992089
    7**20   TokenVector 79792266297612000    CPython 79792266297612001
    2**62   KHOP

Luy thua cua 2 luon khop vi float64 bieu dien chung chinh xac - do la ly
do bug nay song sot: ai thu '2**n' se thay moi thu on. Bo ca duoi day co
CHU Y tranh cai bay do: khong ca nao co so 2 o duong nguyen.

Doi chieu ba phia nhu bigint_test.py. Phia thu ba (bieu thuc Python viet
thang) la ly do test khong the uon theo loi.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli  # noqa: E402

TKV = ROOT / 'test' / 'sample_ipow.tkv'


def _cpython_run():
    ns = {}
    exec(compile(TKV.read_text(encoding='utf-8'), str(TKV), 'exec'), ns)
    return ns['run']


CASES = [
    # i64 - cac ca da do THAT va thay lech tren ban chua sua
    ('i64', 3, 35, 3 ** 35),
    ('i64', 3, 38, 3 ** 38),
    ('i64', 7, 20, 7 ** 20),
    ('i64', 5, 25, 5 ** 25),
    ('i64', 6, 22, 6 ** 22),
    ('i64', 3, 0, 1),
    ('i64', 0, 0, 1),           # Python: 0**0 == 1
    ('i64', 0, 5, 0),
    ('i64', 1, 62, 1),
    ('i64', -3, 21, (-3) ** 21),   # co so am, so mu le
    ('i64', -3, 20, (-3) ** 20),   # co so am, so mu chan
    ('i64', 2, 62, 2 ** 62),       # ca DUY NHAT ban cu cung dung
    # i32
    ('i32', 3, 19, 3 ** 19),
    ('i32', 7, 11, 7 ** 11),
    ('i32', -7, 11, (-7) ** 11),
    # Duong f64 (pf trong sample_ipow.tkv) VAN duoc bien dich - do la
    # canh gac "khong dong vao nhanh thuc". KHONG doi chieu gia tri o day:
    # dinh dang str() cua so thuc con lech Python ('1024' vs '1024.0') va
    # do la moc 7, khong phai loi cua '**'. Dat o day se bien test nay
    # thanh test cua moc 7 va no se do vi ly do khong lien quan.
]


def main():
    exe = compile_tkv_cli(str(TKV), out_exe=str(ROOT / 'test' / '_ipow_test.exe'),
                          entry_name='run')
    py_run = _cpython_run()
    fails = []
    for what, a, b, expected in CASES:
        want = str(expected)
        got_py = str(py_run(what, str(a), str(b)))
        r = subprocess.run([str(exe), what, str(a), str(b)],
                           capture_output=True, text=True)
        got_exe = r.stdout.strip()
        if got_exe != want:
            fails.append(f'{what} {a}**{b}: .exe cho {got_exe!r}, dung phai {want!r}'
                         + (f'  [stderr: {r.stderr.strip()[:160]}]' if r.stderr.strip() else ''))
        if got_py != want:
            fails.append(f'{what} {a}**{b}: .tkv duoi CPython cho {got_py!r}, '
                         f'dung phai {want!r}')
        if got_py != got_exe:
            fails.append(f'{what} {a}**{b}: HAI PHIA LECH NHAU - '
                         f'CPython {got_py!r} vs .exe {got_exe!r}')

    # Tran phai ON AO, khong duoc quan vong lang le (buoc 1 moc 6).
    r = subprocess.run([str(exe), 'i32', '7', '20'], capture_output=True, text=True)
    if r.returncode == 0:
        fails.append("i32 7**20 (tran i32) le ra phai NEM, nhung chay tron tru "
                     f"va cho {r.stdout.strip()!r}")
    # Tran i64 cung phai ON AO. Ca nay do dot bien chi ra: bo no thi doi
    # 'mul.ovf' thanh 'mul' trong TkvIPow lot luoi hoan toan (i32 van bi
    # conv.ovf.i4 chan, nhung i64 thi khong con gi chan).
    # 3**45 = 2954312706550833698643, vuot 2^63.
    r = subprocess.run([str(exe), 'i64', '3', '45'], capture_output=True, text=True)
    if r.returncode == 0:
        fails.append("i64 3**45 (tran i64) le ra phai NEM, nhung chay tron tru "
                     f"va cho {r.stdout.strip()!r}")
    # So mu am: Python tra float, TokenVector phai bao loi chu khong tra 0.
    r = subprocess.run([str(exe), 'i64', '2', '-1'], capture_output=True, text=True)
    if r.returncode == 0:
        fails.append("i64 2**-1 (Python tra 0.5) le ra phai NEM, nhung cho "
                     f"{r.stdout.strip()!r}")

    if fails:
        print('ipow_test: TRUOT')
        for f in fails:
            print('  -', f)
        return 1
    print(f'ipow_test: dat ({len(CASES)} ca + 3 ca phai nem, 3 phia doi chieu)')
    return 0


if __name__ == '__main__':
    sys.exit(main())

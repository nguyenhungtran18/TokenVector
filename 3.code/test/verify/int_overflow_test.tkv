# -*- coding: utf-8 -*-
"""Tran so nguyen phai BAO LOI, khong duoc quan vong lang le (2026-08-04).

Python co so nguyen vo han chu so; TokenVector chi co i32/i64. Truoc ban va,
'add'/'sub'/'mul' cua CIL quan vong IM LANG - do duoc:

    fact(13)  CPython 6227020800           TokenVector 1932053504
    fact(20)  CPython 2432902008176640000  TokenVector -2102132736
    2**31     CPython 2147483648           TokenVector -2147483648   (AM!)

`13!` la mot phep tinh het suc binh thuong. Khong loi, khong exception, chi
la con so sai - dung lop hong nguy hiem nhat.

CAP NHAT 2026-08-05 (moc 6 lat 4 - hang so nguyen mac dinh la 'int'):
ban goc ghim hai dieu, trong do dieu thu hai la 'vuot tam i32 phai NEM
OverflowException', kem loi hen ngay trong docstring: "day CHUA phai ngang
bang Python (...) se bien mat khi doi bieu dien sang BigInteger. Luc do sua
test nay: cac ca 'phai nem' tro thanh 'phai bang CPython'."

Ngay do la hom nay. MOI ca gio deu ghim CUNG MOT dieu, va la dieu manh hon:
ket qua phai KHOP CPython tung chu so, o MOI do lon. fact(20), 2**62,
2147483647+1 khong con la 'lech da biet' nua - chung phai dung."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_int_overflow.tkv'
py = runpy.run_path(str(SRC))

# (entry, doi so) - khong con cot 'co vuot tam i32 khong': moi ca deu
# phai khop CPython. Ca vuot i64 (fact 25/30) la ca MOI, chung chung minh
# duong BigInteger that su chay chu khong phai chi 'i64 rong hon i32'.
CASES = [
    ('fact', '12'), ('fact', '13'), ('fact', '20'),
    ('fact', '25'), ('fact', '30'),
    ('pow2', '30'), ('pow2', '31'), ('pow2', '62'),
    ('pow2', '64'), ('pow2', '100'),
    ('add_big', '0'), ('add_big', '1'),
]


def main():
    bad = []
    built = {}
    for entry, arg in CASES:
        if entry not in built:
            exe = HERE / ('sample_int_overflow_%s.exe' % entry)
            compile_tkv_cli(SRC, exe, entry_name=entry)
            built[entry] = exe
        exe = built[entry]
        want = str(py[entry](int(arg)))
        r = subprocess.run([str(exe), arg], capture_output=True, text=True,
                           errors='replace')
        got = r.stdout.strip()
        if r.returncode != 0 or got != want:
            bad.append((entry, arg, want,
                        '%r (rc=%s) %s' % (got, r.returncode,
                                            r.stderr.strip()[:120])))

    print("So mau: %d" % len(CASES))
    print("Dat: %d/%d" % (len(CASES) - len(bad), len(CASES)))
    if bad:
        print("SAI LECH:")
        for entry, arg, want, got in bad:
            print("  %s(%s) mong doi=%s duoc=%s" % (entry, arg, want, got))
        return 1
    # Canh gac: phai co ca vuot int64, neu khong bo ca chi chung minh
    # 'i64 rong hon i32' chu khong chung minh duong BigInteger.
    if not any(abs(int(py[e](int(a)))) > 2 ** 63 for e, a in CASES):
        print("bo ca khong con ca nao vuot int64 - test da mat rang")
        return 1
    print("PASS: khop CPython tung chu so o MOI do lon, ke ca vuot int64")
    return 0


if __name__ == '__main__':
    sys.exit(main())

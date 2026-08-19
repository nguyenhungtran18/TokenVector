# -*- coding: utf-8 -*-
"""Doi chieu THAT hai bay parity da lam hong cong cu that (2026-08-04).

BAY 1 - tien xu ly f-string khop nham ben trong mot chuoi thuong: chuoi
`"def"` ket thuc bang chu 'f', nen `f"` xuat hien o cho noi hai chuoi
(`w == "def" or w == "class"`). Bo tien xu ly viet lai thanh
`"de(" ... ")class"` - dieu kien LUON sai, KHONG bao gi. Hau qua that:
bang dinh nghia cua typegraph rong sach, 0 canh `calls`. Hai muc khac
trong PARITY_GAPS (`else` long, goi ham trong noi chuoi) hoa ra la CUNG
mot nguyen nhan nay, bi ghi nham thanh ba loi rieng.

BAY 2 - `.maxstack` la hang so 8, nen goi ham tu 9 tham so tro len sinh
IL khong hop le: ilasm van dich, CLR nem InvalidProgramException luc chay.

Trong tai la CPython chay chinh file .tkv (no la Python hop le)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_parity_traps.tkv'
py = runpy.run_path(str(SRC))

CASES = [
    ('kw_or', [('def',), ('class',), ('khac',), ('',)]),
    ('kw_chain', [('class',), ('def',), ('x',), ('',)]),
    ('ends_f', [('elif',), ('self',), ('if',), ('none',)]),
    ('real_fstring', [('An', 3), ('Binh', 0)]),
    ('call9', [(1,), (10,)]),
    ('call12', [(2,), (7,)]),
]


def main():
    total = 0
    bad = []
    for entry, arg_sets in CASES:
        exe = HERE / ('sample_parity_traps_%s.exe' % entry)
        compile_tkv_cli(SRC, exe, entry_name=entry)
        for args in arg_sets:
            total += 1
            want = py[entry](*args)
            r = subprocess.run([str(exe)] + [str(a) for a in args],
                                capture_output=True, text=True, errors='replace')
            got = r.stdout.rstrip('\r\n')
            if r.returncode != 0 or got != str(want):
                bad.append((entry, args, str(want), got, r.returncode,
                            r.stderr.strip()[:120]))

    print("So mau doi chieu voi CPython: %d" % total)
    print("Khop: %d/%d" % (total - len(bad), total))
    if bad:
        print("SAI LECH:")
        for b in bad:
            print("  entry=%s args=%s mong doi=%r duoc=%r rc=%s %s" % b)
        return 1
    print("PASS: chuoi ket thuc bang 'f' khong con bi doc nham la f-string, "
          "f-string that van chay, ham 9 va 12 tham so chay dung")
    return 0


if __name__ == '__main__':
    sys.exit(main())

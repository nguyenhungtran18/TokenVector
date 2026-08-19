# -*- coding: utf-8 -*-
"""Doi chieu THAT: `.maxstack` cua GENERATOR (2026-08-04).

Ban va A2 (muc 10 trong PARITY_GAPS) chi sua `gen_il_function`, nhung
generator di duong sinh ma KHAC (`gen_il_generator_function`), nen hai cho
van giu hang so 8 va van sinh IL khong hop le - ilasm dich duoc, CLR nem
InvalidProgramException LUC CHAY, khong noi gi ve maxstack:

  1. WRAPPER day 1 `ldarg.s` cho MOI tham so roi `newobj` -> generator tu
     9 THAM SO tro len tran stack.
  2. Than `MoveNext()` chua ma nguoi dung tuy y -> mot loi goi 9 doi so
     ben trong generator cung tran.

Da do trong tai truoc khi sua: ca hai deu nem InvalidProgramException,
trong khi CPython chay chinh file .tkv do cho 45 va 135.

Trong tai la CPython chay chinh `sample_generator_wide.tkv` (no la Python
hop le, va `yield` co nghia y het)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_generator_wide.tkv'
py = runpy.run_path(str(SRC))

ENTRIES = ['demo_wide', 'demo_calls9']


def main():
    bad = []
    for entry in ENTRIES:
        exe = HERE / ('sample_generator_wide_%s.exe' % entry)
        compile_tkv_cli(SRC, exe, entry_name=entry)
        want = py[entry]()
        r = subprocess.run([str(exe)], capture_output=True, text=True,
                           errors='replace')
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(want):
            bad.append((entry, str(want), got, r.returncode,
                        r.stderr.strip()[:160]))

    print("So mau doi chieu voi CPython: %d" % len(ENTRIES))
    print("Khop: %d/%d" % (len(ENTRIES) - len(bad), len(ENTRIES)))
    if bad:
        print("SAI LECH:")
        for b in bad:
            print("  entry=%s mong doi=%r duoc=%r rc=%s %s" % b)
        return 1
    print("PASS: generator 9 tham so va loi goi 9 doi so trong than "
          "generator deu chay dung")
    return 0


if __name__ == '__main__':
    sys.exit(main())

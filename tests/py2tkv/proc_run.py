# -*- coding: utf-8 -*-
"""Chay tien trinh ngoai: ham `run` cua module con -> `proc_ra`.

TokenVector khong co module `subprocess`; kha nang DAY duoc xoa bang builtin
`proc_ra(exe, args, tep_ra)` - tra ve MA THOAT, ghi stdout+stderr vao tep_ra.
Do do ma thoat la chinh bien nhan, con dau ra doc bang `read_file`."""
import subprocess


def main() -> int:
    r = subprocess.run(["cmd.exe", "/c", "echo", "hi"], capture_output=True, text=True)
    if r.returncode != 0:
        print("that bai")
        return 1
    out = r.stdout
    if len(out) > 0:
        print("OK")
    return 0
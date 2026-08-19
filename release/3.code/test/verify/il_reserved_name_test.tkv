# -*- coding: utf-8 -*-
"""Ten bien/tham so trung TU KHOA ILASM (2026-08-03, Giai doan 2).

BUG THAT: viet reduce_i32(lst, f, init) - dung y dinh nghia
functools.reduce cua Python - thi ilasm.exe bao "syntax error at token
'init'" va KHONG assemble duoc, chi vi 'init' la tu khoa ILASM
('.locals init'). Danh sach den _IL_RESERVED_WORDS trong il_core.py
KHONG co 'init' (docstring o do da tu ghi "chua chac day du 100%").

Sua bang cach BOC MOI ten trong dau nhay don khi sinh IL (_il_ident) -
chan ca lop loi thay vi them 1 tu vao danh sach den. Test nay dung
'init' lam ca dai dien + kiem ket qua tinh toan van dung."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
exe_path = HERE / 'sample_reserved_ilname.exe'
compile_tkv_cli(HERE / 'sample_reserved_ilname.tkv', exe_path, entry_name='main')
r = subprocess.run([str(exe_path)], capture_output=True, text=True)
got = r.stdout.strip()
expected = str(10 + 1 + 2 + 3 + 4)   # reduce_i32([1,2,3,4], add2, init=10)
print(f"reduce_i32 voi tham so ten 'init' -> {got!r} (ky vong {expected!r})")
if r.returncode != 0 or got != expected:
    print(f'SAI LECH: rc={r.returncode} stderr={r.stderr[:300]}')
    sys.exit(1)
print("Ten trung tu khoa ILASM ('init'): PASS - bien dich va chay dung.")

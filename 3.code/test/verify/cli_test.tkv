# -*- coding: utf-8 -*-
"""Kiem chung THAT CLI tu dong (tkv build / compile_tkv_cli / build_generic_main):
4 ham vo huong (i32/i32, f32/f32, str/str, va 2 ham do AlphaAI sinh) - build
qua CHINH `tkv.py build`, chay .exe, doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent

cases = [
    # (tkv_file, entry_name, py_func_name, [(args_tuple, ), ...])
    ('sample_cli_smoke.tkv', None, 'add_i32',
     [(3, 4), (0, 0), (-5, 10), (100, -100)]),
    ('sample_cli_smoke2.tkv', 'scale_f32', 'scale_f32',
     [(3.5, 2.0), (0.0, 5.0), (-2.5, 4.0), (1.0, 1.0)]),
    ('sample_cli_smoke2.tkv', 'greet_cli', 'greet_cli',
     [('Hung',), ('TokenVector',), ('',)]),
    ('sample_cli_avg.tkv', None, 'avg_of_range',
     [(4,), (0,), (-3,), (1,), (10,)]),
    ('sample_cli_clamp.tkv', None, 'clamp_i32',
     [(5, 0, 10), (-5, 0, 10), (15, 0, 10), (0, 0, 0)]),
]

total = 0
mismatches = []
for tkv_file, entry, py_func_name, arg_sets in cases:
    src = HERE / tkv_file
    exe_path = HERE / f"{src.stem}_{entry or 'auto'}_clitest.exe"
    compile_tkv_cli(src, exe_path, entry_name=entry)
    py_ns = runpy.run_path(str(src))
    py_func = py_ns[py_func_name]
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((tkv_file, entry, args, expected, None, r.stdout, r.stderr))
            continue
        got_raw = r.stdout
        if isinstance(expected, str):
            # CHI bo dau xuong dong Console.WriteLine them vao, KHONG dung
            # .strip() (bug that tim thay: .strip() an luon dau CACH cuoi
            # chuoi hop le, vd "Xin chao, " + "" - lam sai lech gia).
            got_raw = got_raw.rstrip('\r\n')
            ok = got_raw == expected
        elif isinstance(expected, float):
            ok = abs(float(got_raw) - expected) < 1e-3
        else:
            ok = int(got_raw) == expected
        if not ok:
            mismatches.append((tkv_file, entry, args, expected, got_raw, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("CLI TU DONG: PASS - tkv build sinh Main() tu dong (i32/f32/str param+return, "
      "gom ca 2 ham AlphaAI sinh) khop CPython that 100%.")

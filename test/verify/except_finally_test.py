# -*- coding: utf-8 -*-
"""Kiem chung THAT 'except <Loai>:' + 'finally:' vua them - dung CLI tu
dong (compile_tkv_cli) de build tung ham, doi chieu voi CPython that.
Rieng finally: kiem tra THEM ca file phu (qua append_file that su chay)
de xac nhan finally THAT SU chay (khong chi ket qua tra ve dung)."""
import runpy
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_except_finally.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

total = 0
mismatches = []


def run_scalar_case(entry, py_func, args):
    global total
    exe_path = HERE / f'sample_except_finally_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for arg_set in args:
        total += 1
        expected = int(py_func(*arg_set))
        r = subprocess.run([str(exe_path)] + [str(a) for a in arg_set],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, arg_set, expected, None, r.stdout, r.stderr))
            continue
        got = int(r.stdout.strip())
        if got != expected:
            mismatches.append((entry, arg_set, expected, got, r.stdout, r.stderr))


run_scalar_case('safe_div_multi', py_ns['safe_div_multi'],
                 [(10, 2), (9, 3), (0, 5), (7, 0), (-9, 0)])
run_scalar_case('dict_get_or_default', py_ns['dict_get_or_default'],
                 [(5, 2), (5, 0), (5, 4), (5, 5), (0, 0), (5, 99)])

with tempfile.TemporaryDirectory() as tmpdir:
    tmp = Path(tmpdir)

    # div_with_finally: KHONG co 'except' - chia cho 0 se lan truyen tiep
    # (finally van chay, nhung khong bat loi) roi CRASH ca 2 phia (Python
    # that va .exe) - CHI test cac ca KHONG loi o day.
    entry = 'div_with_finally'
    exe_path = HERE / f'sample_except_finally_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    py_func = py_ns[entry]
    for a, b in [(10, 2), (9, 3), (0, 5)]:
        total += 1
        py_counter = str(tmp / f'{entry}_py_{a}_{b}.txt')
        exe_counter = str(tmp / f'{entry}_exe_{a}_{b}.txt')
        expected = int(py_func(a, b, py_counter))
        r = subprocess.run([str(exe_path), str(a), str(b), exe_counter],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, (a, b), expected, None, r.stdout, r.stderr))
            continue
        got = int(r.stdout.strip())
        exe_counter_content = Path(exe_counter).read_text(encoding='utf-8') if Path(exe_counter).exists() else None
        if got != expected or exe_counter_content != 'x':
            mismatches.append((entry, (a, b), expected, got,
                                f'exe_counter={exe_counter_content!r}', r.stderr))

    # Rieng b=0: KHONG co except nen loi phai LAN TRUYEN tiep (khong bi
    # bat) - ca 2 phia PHAI crash, nhung finally VAN phai chay (file phu
    # van duoc ghi) truoc khi crash - xac nhan dung ngu nghia finally that.
    total += 1
    py_crashed = False
    try:
        py_func(7, 0, str(tmp / 'div_with_finally_py_crash.txt'))
    except ZeroDivisionError:
        py_crashed = True
    exe_crash_counter = str(tmp / 'div_with_finally_exe_crash.txt')
    r = subprocess.run([str(exe_path), '7', '0', exe_crash_counter], capture_output=True, text=True)
    exe_crashed = r.returncode != 0
    exe_counter_content = Path(exe_crash_counter).read_text(encoding='utf-8') if Path(exe_crash_counter).exists() else None
    if not (py_crashed and exe_crashed and exe_counter_content == 'x'):
        mismatches.append(('div_with_finally(no-catch, b=0)', (7, 0), 'crash+finally-ran',
                            f'py_crashed={py_crashed} exe_crashed={exe_crashed} '
                            f'exe_counter={exe_counter_content!r}', r.stderr))

    # div_with_except_and_finally: CO bat ZeroDivisionError, nen b=0 la
    # ca hop le (khong crash) - test day du 3 truong hop.
    entry = 'div_with_except_and_finally'
    exe_path = HERE / f'sample_except_finally_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    py_func = py_ns[entry]
    for a, b in [(10, 2), (9, 3), (7, 0)]:
        total += 1
        py_counter = str(tmp / f'{entry}_py_{a}_{b}.txt')
        exe_counter = str(tmp / f'{entry}_exe_{a}_{b}.txt')
        expected = int(py_func(a, b, py_counter))
        r = subprocess.run([str(exe_path), str(a), str(b), exe_counter],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, (a, b), expected, None, r.stdout, r.stderr))
            continue
        got = int(r.stdout.strip())
        exe_counter_content = Path(exe_counter).read_text(encoding='utf-8') if Path(exe_counter).exists() else None
        if got != expected or exe_counter_content != 'x':
            mismatches.append((entry, (a, b), expected, got,
                                f'exe_counter={exe_counter_content!r}', r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXCEPT-TYPED/FINALLY SUPPORT: PASS - except <Loai>: va finally: bien dich THAT "
      "va dung 100% (finally da xac nhan CHAY THAT qua file phu).")

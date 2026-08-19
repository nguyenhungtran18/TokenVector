# -*- coding: utf-8 -*-
"""Kiem chung THAT 11 ham do Gemini sinh THU CONG qua chat (khong qua API
Groq, dung khi Groq TPD het quota 2026-07-28) - bien dich qua tkv_compile
that + doi chieu CPython that, dung nguyen tac 'khong tin mu code AI'."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_manual_chat_11.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('unique_char_count', py_ns['unique_char_count'],
     [('hello world',), ('aaaa',), ('',), ('abcabc',)]),
    ('list_max', py_ns['list_max'],
     [(1, 2, 3), (5, 5, 5), (-1, -5, -3), (0, 0, 1)]),
    ('list_count_even', py_ns['list_count_even'],
     [(10,), (1,), (0,), (7,)]),
    ('dict_sum_values', py_ns['dict_sum_values'],
     [(1, 2, 3), (0, 0, 0), (-5, 10, 2)]),
    ('dict_has_key_report', py_ns['dict_has_key_report'],
     [(5, 1), (5, 0), (0, 1)]),
    ('list_of_squares_sum', py_ns['list_of_squares_sum'],
     [(5,), (1,), (0,), (10,)]),
    ('gcd_like_mod', py_ns['gcd_like_mod'],
     [(48, 18), (17, 5), (100, 25), (7, 0)]),
    ('clamp_report', py_ns['clamp_report'],
     [(5, 0, 10), (-3, 0, 10), (15, 0, 10)]),
    ('safe_index_report', py_ns['safe_index_report'],
     [(5, 2), (5, -1), (5, 10), (0, 0)]),
    ('count_not_equal', py_ns['count_not_equal'],
     [(3, 10), (0, 5), (100, 5)]),
    ('running_total_capped', py_ns['running_total_capped'],
     [(10, 20), (10, 3), (5, 1000), (0, 5)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_manual_chat_11_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(expected):
            mismatches.append((entry, args, expected, got, r.returncode, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("MANUAL-CHAT-11 SUPPORT: PASS - 11 ham Gemini sinh thu cong bien dich THAT va dung 100%.")

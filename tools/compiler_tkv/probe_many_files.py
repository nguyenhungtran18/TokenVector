"""Chay lexer TokenVector tren nhieu file .tkv that va tom tat.

HAI NHOM file - phan biet rat quan trong:

* `TOKENVECTOR` - file nguon THAT TokenVector. Lexer phai khop CPython 100%.
* `PYTHON` - `tkv_compile.tkv`, `tkv.tkv`, `tokenvector_compile.tkv`... nhung
  noi dung la PYTHON (xem CLAUDE.md "What the Compiler Actually Is"). Chung
  dung nhay don `'` va escape day du, ma TokenVector KHONG ho tro (nguon
  TokenVector chi co nhay kep don). Lexer tach chung KHONG khop CPython la
  **DUNG** - va chinh su lech do la bang chung cho thay lexer phan biet duoc
  hai ngon ngu. Do do nhom nay chi thong bao, khong tinh vao ket qua.

Chay: python tools\\compiler_tkv\\probe_many_files.py
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PROBE = os.path.join(HERE, 'probe_real_file.py')

# Nguon TokenVector THAT - phai khop.
TOKENVECTOR = [
    'tests/counter_test.tkv',
    'tests/iter_next_test.tkv',
    'tests/record_container_field_test.tkv',
    'tests/negative/iter_in_expression.tkv',
    'tests/multi_assign_test.tkv',
    'tests/string_format_test.tkv',
    'tests/record_lt_test.tkv',
    'projects/tour.tkv',
    'projects/tkvcalc.tkv',
    'tools/tkv_guide.tkv',
    'tools/lint_fixtures/bad.tkv',
]

# File Python-mang-lot-.tkv - lech la DUNG, chi de quan sat.
PYTHON = [
    'tkv.tkv',
    'tokenvector_compile.tkv',
    'compiler/il_codegen.tkv',
]


def run(rel):
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        return None, 'KHONG TON TAI'
    r = subprocess.run([sys.executable, PROBE, p], capture_output=True,
                       text=True, encoding='utf-8', errors='replace')
    nums = [l for l in r.stdout.split('\n') if 'token' in l and ':' in l]
    counts = ' | '.join(x.strip() for x in nums[:2])
    return r.returncode, counts


def main():
    ok = bad = skip = 0
    print('--- nguon TokenVector THAT (phai khop 100%) ---')
    for t in TOKENVECTOR:
        rc, counts = run(t)
        if rc is None:
            print('  BO QUA %s' % os.path.basename(t))
            skip += 1
            continue
        if rc == 0:
            ok += 1
            print('  KHOP   %-38s %s' % (os.path.basename(t), counts))
        else:
            bad += 1
            print('  HONG   %-38s %s' % (os.path.basename(t), counts))

    print('')
    print('--- file Python (lech la DUNG - TokenVector khong co nhay don) ---')
    for t in PYTHON:
        rc, counts = run(t)
        if rc is None:
            continue
        print('  %-6s %-38s %s' % ('KHOP' if rc == 0 else 'KHAC', os.path.basename(t), counts))

    print('')
    print('=== lexer tren nguon TokenVector: %d khop / %d hong ===' % (ok, bad))
    return 0 if bad == 0 else 1


if __name__ == '__main__':
    sys.exit(main())

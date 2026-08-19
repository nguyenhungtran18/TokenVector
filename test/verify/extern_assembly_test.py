# -*- coding: utf-8 -*-
"""Kiem chung THAT co che mo rong '__tkv_extern_assembly__' (Wave 3,
2026-07-29, "package ecosystem" - xem project-tokenvector-wave2-status
memory) - xml_encode_name() dung assembly System.Xml (KHONG co san mac
dinh, phai khai bao qua pragma). Ket qua doi chieu voi hanh vi THAT cua
System.Xml.XmlConvert.EncodeName (da tu chay qua csc.exe spike truoc khi
viet - khong doan mo): dau cach -> '_x0020_'."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_extern_assembly.tkv'
exe_path = HERE / 'sample_extern_assembly_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='encode')

cases = [('hello world', 'hello_x0020_world'), ('abc', 'abc'), ('', '')]
total = 0
mismatches = []
for s, expected in cases:
    total += 1
    r = subprocess.run([str(exe_path), s], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((s, expected, None, r.stdout, r.stderr))
        continue
    got = r.stdout.strip()
    if got != expected:
        mismatches.append((s, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop: {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXTERN_ASSEMBLY (__tkv_extern_assembly__ = 'System.Xml'): PASS - dung 100%.")

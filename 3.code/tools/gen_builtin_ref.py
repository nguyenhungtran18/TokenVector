# -*- coding: utf-8 -*-
"""Sinh danh muc HAM cua compiler tu chinh ma nguon - de KIEM TRA TRUOC khi
them moi, thay vi doan va ghi de file dang co (2026-09-30: da vo tinh ghi de
`bytes_type.tkv` vi tuong la file moi).

Chay lai sau khi them/bot ham:
    python tools\\gen_builtin_ref.py
Ket qua ghi ra docs/BUILTIN_REFERENCE.md
"""
import io
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FEAT = os.path.join(ROOT, 'compiler', 'il_features')
OUT = os.path.join(ROOT, 'docs', 'BUILTIN_REFERENCE.md')

# (nhan hieu, regex, nhom)
PATTERNS = [
    ('builtin', re.compile(r"register_expr_builtin\(\s*'([A-Za-z_][\w]*)'"), 'HAM BUILTIN (GOI DUOC TRUC TIEP)'),
    ('method', re.compile(r"register_expr_method\(\s*'([\w]*)'\s*,\s*'([\w]*)'"), None),
    ('method2', re.compile(r"register_expr_method\('([\w]*)',\s*'([\w]*)'"), None),
    ('line', re.compile(r"register_line_parser\(\s*'([\w]*)'"), 'DANG CAU LENH (MACRO CAP DONG)'),
    ('assign', re.compile(r"register_assign_rhs_parser\(\s*'([\w]*)'"), 'DANG PHAI PHAI CUA PHE GAN'),
    ('stmt', re.compile(r"register_stmt_codegen\(\s*'([\w]*)'"), 'KIEU CAU LENH (SINH IL)'),
    ('macro', re.compile(r"register_macro_expander\(\s*'([\w]*)'"), 'MACRO VIET TAY'),
    ('dunder', re.compile(r"register_dunder_method\(\s*'([\w]*)'"), 'DUNDER CUA RECORD'),
]

# File nao dang TON TAI trong compiler - kiem tra file nay truoc khi tao file moi
FILES = []


def collect():
    buckets = {}
    for kind, rx, group in PATTERNS:
        for fn in sorted(os.listdir(FEAT)):
            if not fn.endswith('.tkv'):
                continue
            path = os.path.join(FEAT, fn)
            if kind == 'file':
                continue
            text = io.open(path, encoding='utf-8').read()
            found = []
            for m in rx.finditer(text):
                found.append(m.groups())
            if not found:
                continue
            key = group or 'METHOD THEO KHU VUC'
            for g in found:
                nm = g[-1]
                buckets.setdefault(key, set()).add(nm)
    return buckets


def main():
    for fn in sorted(os.listdir(FEAT)):
        if fn.endswith('.tkv'):
            FILES.append((fn, os.path.getsize(os.path.join(FEAT, fn))))
    b = collect()
    lines = []
    lines.append('# DANH MUC HAM CUA COMPILER')
    lines.append('')
    lines.append('> **Tu sinh** tu ma nguon boi `tools/gen_builtin_ref.py` - KHONG sua tay.')
    lines.append('> Sinh lai sau khi them/bot ham: `python tools\\gen_builtin_ref.py`')
    lines.append('')
    lines.append('**Dung muc dich:** truoc khi THEM MOT HAM, doi MOT KIUE hay tao file')
    lines.append('mo trong `compiler/il_features/`, kiem danh muc nay va kiem tra file')
    lines.append('da ton tai chua. Da co mot lan: tao `bytes_type.tkv` de bo sung ham')
    lines.append('`bytes()` nhung file do DA TON TAI va la module that cua compiler -')
    lines.append('ghi de lam hong ca buoc bien dich.')
    lines.append('')
    total = 0
    for key in sorted(b):
        names = sorted(b[key])
        total += len(names)
        lines.append(f'## {key} ({len(names)})')
        lines.append('')
        for i in range(0, len(names), 8):
            lines.append('`%s` ' % names[i] + ' '.join('`%s`' % n for n in names[i + 1:i + 8]))
        lines.append('')
    lines.append(f'**Tong so ten da dang ky: {total}**')
    lines.append('')
    lines.append('## File trong `compiler/il_features/`')
    lines.append('')
    lines.append('| File | Kich thuoc |')
    lines.append('|---|---|')
    for fn, sz in FILES:
        lines.append(f'| `{fn}` | {sz:,} |'.replace(',', '.'))
    lines.append('')
    io.open(OUT, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
    print('da sinh %s (%d ten, %d file)' % (OUT, total, len(FILES)))


main()

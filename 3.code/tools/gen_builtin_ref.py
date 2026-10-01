# -*- coding: utf-8 -*-
"""Sinh danh muc HAM cua compiler tu chinh ma nguon - de KIEM TRA TRUOC khi
them moi, thay vi doan va ghi de file dang co (2026-09-30: da vo tinh ghi de
`bytes_type.tkv` vi tuong la file moi).

Chay lai sau khi them/bot ham:
    python tools\\gen_builtin_ref.py
Ket qua ghi ra docs/BUILTIN_REFERENCE.md
"""
import ast
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
    ('method2', re.compile(r"register_expr_method\('([\w]*)',\s*'([\w]*)'"), None),    ('line', re.compile(r"register_line_parser\(\s*'([\w]*)'"), 'DANG CAU LENH (MACRO CAP DONG)'),
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
                if kind in ('method', 'method2') and len(g) >= 2:
                    # GHI CO OWNER (vi du `str.upper`) - ghi ten tran lam
                    # `upper` khong cho biet no cua kieu nao, va `count`/
                    # `copy`/`join` trung ten giua nhieu kieu.
                    nm = f'{g[0]}.{g[-1]}'
                else:
                    nm = g[-1]
                buckets.setdefault(key, set()).add(nm)
    return buckets


def collect_str_methods():
    """Method chuoi KHONG di qua `register_expr_method` ma nam trong dict
    `STR_METHODS` / `STR_METHODS_EXTRA` / `STR_METHODS_EXTRA2`, duoc dispatch
    qua fallback `if ... method_name in _STR_METHODS` (record_feature.tkv).
    Ban sinh danh muc TRUOC do bo sot toan bo 13 method nay, va con do lai
    method cua list/dict/set theo ten tran - nen `append` cua list va
    `upper` cua chuoi deu khong hien thi. Doc bang `ast` vi 3 file .tkv la
    Python that; regex se bo sot cac muc viet xuong dong."""
    out = set()
    for fn in sorted(os.listdir(FEAT)):
        if not fn.startswith('string_methods_batch') or not fn.endswith('.tkv'):
            continue
        path = os.path.join(FEAT, fn)
        try:
            tree = ast.parse(io.open(path, encoding='utf-8').read())
        except SyntaxError:
            continue
        for node in ast.walk(tree):
            if not isinstance(node, ast.Assign) or not isinstance(node.value, ast.Dict):
                continue
            for tgt in node.targets:
                nm = getattr(tgt, 'id', None) or getattr(tgt, 'attr', None)
                if not nm or 'STR_METHOD' not in nm:
                    continue
                for k in node.value.keys:
                    if isinstance(k, ast.Constant) and isinstance(k.value, str):
                        out.add('str.' + k.value)
    return out


def collect_listlike_methods():
    """Method container nam trong dict (LIST_METHODS/DICT_METHODS/...) -
    cung duoc dispatch qua fallback, khong qua `register_expr_method`."""
    out = set()
    for fn in sorted(os.listdir(FEAT)):
        if not fn.endswith('.tkv'):
            continue
        path = os.path.join(FEAT, fn)
        if fn not in ('list_type.tkv', 'dict_type.tkv', 'set_type.tkv',
                      'tuple_type.tkv', 'list_methods_batch2.tkv',
                      'list_methods_batch3.tkv', 'set_methods_batch2.tkv'):
            continue
        try:
            tree = ast.parse(io.open(path, encoding='utf-8').read())
        except SyntaxError:
            continue
        for node in ast.walk(tree):
            if not isinstance(node, ast.Assign) or not isinstance(node.value, ast.Dict):
                continue
            for tgt in node.targets:
                nm = getattr(tgt, 'id', None) or getattr(tgt, 'attr', None)
                if not nm or not nm.endswith('METHODS'):
                    continue
                for k in node.value.keys:
                    if isinstance(k, ast.Constant) and isinstance(k.value, str):
                        out.add(k.value)
    return out


def main():
    for fn in sorted(os.listdir(FEAT)):
        if fn.endswith('.tkv'):
            FILES.append((fn, os.path.getsize(os.path.join(FEAT, fn))))
    b = collect()
    str_methods = collect_str_methods()
    if str_methods:
        b.setdefault('METHOD CHUOI (str.) - qua dict STR_METHODS', set()).update(str_methods)
    listed = collect_listlike_methods()
    if listed:
        b.setdefault('METHOD CONTAINER (ten, dung chung nhieu kieu)', set()).update(listed)
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
    lines.append('**CANH BAO - co ten KHONG nghia la co dung duoc.** Muc nay lay tu')
    lines.append('`register_*`, no chi chung MINH dang co entry dang ky, KHONG')
    lines.append('chung tinh nang chay duoc den cuoi. Bang chung lien quan (2026-09-30):')
    lines.append('`datetime` CO dang ky day du nhung KHONG cung nghia voi Python -')
    lines.append('`datetime()` tra UtcNow va bo qua hoan toan tham so, nen tu rat lau')
    lines.append('`datetime(2026, 9, 30)` bien dich xanh roi tra ve HOM NAY (da sua')
    lines.append('thanh loi bien dich). Nguoc lai, nhieu ham KHONG nam trong day da')
    lines.append('chay dung (vi du `with open(...)` o `control_flow.tkv`, va')
    lines.append('`sorted()`).')
    lines.append('=> Hai chieu deu sai. Hay PROBE thuc roi tin ket qua, va khi')
    lines.append('probe BAT BIEN DUNG thi phai kiem danh muc nay truoc kem ket')
    lines.append('luan "ham do chua co" - rat nhieu lan toi sai theo huong nguoc.')
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

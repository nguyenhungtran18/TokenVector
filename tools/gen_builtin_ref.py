# -*- coding: utf-8 -*-
"""Sinh khoi DANH MUC cua `docs/REFERENCE.md` - tu ma nguon boi `register_*`.

**HOI 2026-10-02: viet vao MOT file, xoa cac file trung.** Truoc day tay lieng
sinh ra `docs/BUILTIN_REFERENCE.md` - 3 file cung noi 1 thu, mau thuan nhau.
Nay chi ghi vao **khoi co dau hieu** trong `REFERENCE.md`:

    python tools\\gen_builtin_ref.py           # viet lai khoi danh muc
    python tools\\gen_builtin_ref.py --check    # FAIL neu tai lieu CHUA ghi
                                                #   mot ten da dang ky

**BAI HOC (dung quen):** 2026-09-30 tao `bytes_type.tkv` de them ham `bytes()`,
khong kiem danh muc nen file da TON TAI bi ghi de - lam hong ca buoc bien dich.
Bai nay GHI VAO MOT KHOI, nen khong con duong nao de ghi de phan viet tay. Neu
thay MARKER, script FAIL chu khong ghi - xem `write_block()`.
"""
import ast
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# 2026-10-12 (tach repo): `compiler/` da sang submodule `compiler_py/`. Danh
# muc nay mo ta compiler TOKENVECTOR, nen phai doc
# `compiler_bootstrap/compiler/il_features` - cung nguon voi
# `dang_ky_gate.py` (doc qua `compiler_src/ds_gop.txt`). Doc `compiler_py/`
# se tao danh muc cua compiler bootstrap Python, dung sai muc dich.
FEAT = os.path.join(ROOT, 'compiler_bootstrap', 'compiler', 'il_features')
OUT = os.path.join(ROOT, 'docs', 'REFERENCE.md')

BEGIN = '<!-- BEGIN GENERATED: danh muc ten + danh sach file -->'
END = '<!-- END GENERATED -->'

# (nhan hieu, regex, nhom)
# 2026-10-12: moi nhanh `(?:reg\s*,\s*)?` cho phep kiem CA HAI chu ky goi:
#   compiler Python      register_expr_builtin('ten', ...)
#   compiler TokenVector register_expr_builtin(reg, 'ten', ...)   <- them 'reg'
# Thieu no, regex chi thay 1/402 ten cua compiler TokenVector va bao "danh muc
# rong" - cam giac nguoc lai ngay sau khi tach repo.
PATTERNS = [
    ('builtin', re.compile(r"register_expr_builtin\(\s*(?:reg\s*,\s*)?'([A-Za-z_][\w]*)'"), 'HAM BUILTIN (GOI DUOC TRUC TIEP)'),
    ('method', re.compile(r"register_expr_method\(\s*(?:reg\s*,\s*)?'([\w]*)'\s*,\s*'([\w]*)'"), None),
    ('method2', re.compile(r"register_expr_method\(\s*'([\w]*)',\s*'([\w]*)'"), None),
    ('line', re.compile(r"register_line_parser\(\s*(?:reg\s*,\s*)?'([\w]*)'"), 'DANG CAU LENH (MACRO CAP DONG)'),
    ('assign', re.compile(r"register_assign_rhs_parser\(\s*(?:reg\s*,\s*)?'([\w]*)'"), 'DANG PHAI PHAI CUA PHE GAN'),
    ('stmt', re.compile(r"register_stmt_codegen\(\s*(?:reg\s*,\s*)?'([\w]*)'"), 'KIEU CAU LENH (SINH IL)'),
    ('macro', re.compile(r"register_macro_expander\(\s*(?:reg\s*,\s*)?'([\w]*)'"), 'MACRO VIET TAY'),
    ('dunder', re.compile(r"register_dunder_method\(\s*(?:reg\s*,\s*)?'([\w]*)'"), 'DUNDER CUA RECORD'),
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


def all_registered():
    """tap ten 'nguoi dung cham vao' theo 4 nhom, + tat ca ten (de check)."""
    b = collect()
    str_methods = collect_str_methods()
    if str_methods:
        b.setdefault('METHOD CHUOI (str.) - qua dict STR_METHODS', set()).update(str_methods)
    listed = collect_listlike_methods()
    if listed:
        b.setdefault('METHOD CONTAINER (ten, dung chung nhieu kieu)', set()).update(listed)
    return b


# Nhom nao `REFERENCE.md` phai giai thich TUNG ten (muc 2 + muc 3 + muc 4).
# Con lai la khoa noi bo cua trinh bien dich - muc 1/§6 mo ta theo HO.
DOC_FACING = ('HAM BUILTIN (GOI DUOC TRUC TIEP)', 'METHOD CHUOI (str.) - qua dict STR_METHODS',
              'METHOD THEO KHU VUC', 'METHOD CONTAINER (ten, dung chung nhieu kieu)',
              'DANG PHAI PHAI CUA PHE GAN')


def write_block(block):
    """Ghi `block` vao giua 2 MARKER cua REFERENCE.md.

    FAIL (khong ghi) neu thieu marker - thay vi ghi de ca tai lieu, dung
    chinh thu do tai liệu ma no vua sinh ra chinh cho no."""
    if not os.path.exists(OUT):
        sys.stderr.write('THIEU %s\n' % OUT)
        return 2
    text = io.open(OUT, encoding='utf-8').read()
    if BEGIN not in text or END not in text:
        sys.stderr.write(
            'KHONG THAY MARKER trong %s.\n'
            '  Can dong: %s\n  va dong: %s\n'
            'Script KHONG ghi de tai lieu - hay them marker roi chay lai.\n'
            % (OUT, BEGIN, END))
        return 2
    head = text[:text.index(BEGIN) + len(BEGIN)]
    tail = text[text.index(END):]
    io.open(OUT, 'w', encoding='utf-8', newline='\n').write(
        head + '\n' + block.rstrip() + '\n' + tail)
    return 0


def check_coverage(b):
    """FAIL neu `REFERENCE.md` chua ghi mot ten da dang ky nao."""
    text = io.open(OUT, encoding='utf-8').read()
    # Phan viet tay = ngoai khoi GENERATED (danh muc sinh chua "giai thich" gi)
    hand = text[:text.index(BEGIN)] + text[text.index(END):]
    seen = set(re.findall(r'`([A-Za-z_]\w*(?:\.[a-z_]+)?)`', hand))
    need = set()
    for key in DOC_FACING:
        need |= b.get(key, set())
    missing = sorted(need - seen)
    if missing:
        sys.stderr.write('REFERENCE.md CHUA GHI %d ten da dang ky:\n' % len(missing))
        for n in missing:
            sys.stderr.write('  - %s\n' % n)
        return 1
    print('REFERENCE.md: %d/%d ten da duoc ghi.' % (len(need), len(need)))
    return 0


def main():
    for fn in sorted(os.listdir(FEAT)):
        if fn.endswith('.tkv'):
            FILES.append((fn, os.path.getsize(os.path.join(FEAT, fn))))
    b = all_registered()
    if '--check' in sys.argv:
        return check_coverage(b)
    lines = []
    lines.append('### Danh mục tên đã đăng ký')
    lines.append('')
    lines.append('**Dùng để:** trước khi **thêm một hàm**, **đổi một kiểu** hay tạo file')
    lines.append('mới trong `compiler/il_features/`, kiểm danh mục này và kiểm tra file đã')
    lines.append('tồn tại chưa. Đã có một lần: tạo `bytes_type.tkv` để bổ sung hàm')
    lines.append('`bytes()` nhưng file đó **đã tồn tại** và là module thật của compiler —')
    lines.append('ghi đè làm hỏng cả bước biên dịch.')
    lines.append('')
    lines.append('**CẢNH BÁO — có tên không nghĩa là có dùng được.** Mục này lấy từ')
    lines.append('`register_*`, nó chỉ chứng minh *có entry đăng ký*, KHÔNG chứng minh')
    lines.append('*tính năng chạy được đến cuối*. Hãy **probe thật** rồi tin kết quả.')
    lines.append('')
    total = 0
    for key in sorted(b):
        names = sorted(b[key])
        total += len(names)
        lines.append(f'**{key} ({len(names)})**')
        lines.append('')
        for i in range(0, len(names), 8):
            lines.append('`%s` ' % names[i] + ' '.join('`%s`' % n for n in names[i + 1:i + 8]))
        lines.append('')
    lines.append(f'**Tổng số tên đã đăng ký: {total}**')
    lines.append('')
    lines.append('### File trong `compiler/il_features/`')
    lines.append('')
    lines.append('| File | Kích thước |')
    lines.append('|---|---|')
    for fn, sz in FILES:
        lines.append(f'| `{fn}` | {sz:,} |'.replace(',', '.'))
    lines.append('')
    rc = write_block('\n'.join(lines))
    if rc:
        return rc
    print('da sinh khoi danh muc trong %s (%d ten, %d file)' % (OUT, total, len(FILES)))
    return 0


if __name__ == '__main__':
    # Guard bat buoc: file nay duoc `import` boi `cmp_python_builtins.py` de lay
    # danh muc tu ma nguon. Khong co guard, `sys.exit(main())` o cap module se
    # KET THUC TIEN TRINH khi ai do import - loi rat kho quang bao (da gap).
    sys.exit(main())

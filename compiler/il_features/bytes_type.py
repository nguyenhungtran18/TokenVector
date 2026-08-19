# -*- coding: utf-8 -*-
"""Kieu 'bytes' (muc 6.8, 4/4, 2026-08-13) - literal b"..." ASCII, BAT
BIEN. Tai dung 100% ha tang List<uint8> cua 'bytearray' (bytearray_type.py,
commit 3773217) cho ca kieu IL LAN doc (index/len/for-in) - CHI khac o
2 diem: (1) tao ra bang cach unroll N gia tri hang so biet truoc luc
gan bien MOI (khong '.append()' runtime), (2) '.append()'/mutate BI CHAN
hoan toan (SyntaxError) vi Python that 'bytes' bat bien.

Dieu tra Step 1 (2026-08-13) phat hien: KHONG co san 1 ham unescape
str_lit rieng biet o phia Python de tai dung - 'str_lit' (STR token cua
il_core.py) duoc GIU NGUYEN CA DAU NGOAC va cac escape (vd '\\n') ngay
tu tokenizer, chuyen THANG cho 'ldstr' trong IL (xem
il_features/string_feature.py's compile_str_lit: 'ldstr {node[1]}') -
IL ldstr chap nhan cu phap escape gan giong C tren chinh chuoi tho do,
nen phia Python KHONG BAO GIO thuc su giai ma escape thanh gia tri
ky tu that. Vi bytes literal can GIA TRI BYTE THAT (ord() cua tung ky
tu) de unroll thanh hang so IL luc compile-time (khac ldstr - ldstr
giao het viec giai ma escape cho runtime .NET), KHONG the tai dung
'nguyen ham' nay - file nay tu viet 1 unescape TOI THIEU (chi cac escape
pho bien: \\\\ \\" \\n \\t \\r \\0 \\xHH), dung PHAM VI cua task (chi
b"..." literal ASCII gan truc tiep bien moi).

LECH SO VOI KE HOACH (plan 2026-08-13-bytes.md): plan de xuat mo rong
'declare_scalar' (il_codegen.py, dong ~2734) voi 1 nhanh 'bytes_lit'.
Dieu tra THAT cho thay 'declare_scalar' CHI la fallback cuoi cung cua
duong gan bien (_lp_assign trong il_codegen.py) - moi container literal
(list_literal, bytearray()) di theo duong RIENG qua ASSIGN_RHS_PARSERS/
FIRST_PASS_WALK/STMT_CODEGEN (dang ky boi list_type.py/bytearray_type.py),
KHONG BAO GIO cham toi declare_scalar. File nay di THEO DUNG kien truc
THAT (giong het bytearray_type.py) thay vi them nhanh vao declare_scalar
- gan bien moi 'data = b"AB"' duoc bat boi try_rhs_bytes_literal (dang
ky vao ASSIGN_RHS_PARSERS), KHONG BAO GIO roi toi assign_scalar/
declare_scalar."""

_SIMPLE_ESCAPES = {
    '\\': '\\',
    '"': '"',
    'n': '\n',
    't': '\t',
    'r': '\r',
    '0': '\0',
}


def parse_bytes_literal(raw: str) -> list:
    """raw: chuoi tho TU TOKENIZER, dang 'b"...."' (con nguyen tien to 'b'
    + 2 dau ngoac kep). Tra ve list[int] - moi phan tu la ord() cua 1 ky
    tu SAU KHI giai ma escape toi thieu, kiem tra ASCII (0-127)."""
    if not (raw.startswith('b"') and raw.endswith('"') and len(raw) >= 3):
        raise SyntaxError(f"il_codegen: bytes literal khong hop le: {raw!r}")
    body = raw[2:-1]
    values = []
    i = 0
    n = len(body)
    while i < n:
        ch = body[i]
        if ch == '\\' and i + 1 < n:
            nxt = body[i + 1]
            if nxt == 'x' and i + 3 < n:
                hex_digits = body[i + 2:i + 4]
                try:
                    hex_val = int(hex_digits, 16)
                except ValueError:
                    raise SyntaxError(
                        f"il_codegen: bytes literal co escape \\x khong hop le: {raw!r}")
                if hex_val > 127:
                    raise SyntaxError(
                        f"il_codegen: bytes literal chi ho tro ASCII (0-127) - "
                        f"escape \\x{hex_digits} = {hex_val} vuot pham vi trong {raw!r}")
                values.append(hex_val)
                i += 4
                continue
            if nxt in _SIMPLE_ESCAPES:
                values.append(ord(_SIMPLE_ESCAPES[nxt]))
                i += 2
                continue
            # Escape khong nhan dien - giu nguyen ky tu SAU dau '\' (giong
            # Python that khi gap escape khong hop le trong bytes literal
            # thi giu ca 2 ky tu, nhung o day CHI chap nhan ASCII nen chi
            # can gia tri ky tu do).
            nxt_code = ord(nxt)
            if nxt_code > 127:
                raise SyntaxError(
                    f"il_codegen: bytes literal chi ho tro ASCII (0-127) - "
                    f"gap ky tu {nxt!r} (ma {nxt_code}) trong {raw!r}")
            values.append(nxt_code)
            i += 2
            continue
        code = ord(ch)
        if code > 127:
            raise SyntaxError(
                f"il_codegen: bytes literal chi ho tro ASCII (0-127) - "
                f"gap ky tu {ch!r} (ma {code}) trong {raw!r}")
        values.append(code)
        i += 1
    return values


import re

from il_core import parse_expr
from il_dispatch import (
    register_assign_rhs_parser, register_line_parser,
    register_stmt_codegen, register_first_pass_walk,
)
from il_features.bytearray_type import il_bytearray_type


_BYTES_LIT_RE = re.compile(r'^b"(?:[^"\\]|\\.)*"\s*$')
_BYTES_APPEND_RE = re.compile(r'^(\w+)\.append\((.+)\)\s*$')


def try_rhs_bytes_literal(rhs, name, known_shapes):
    """ASSIGN_RHS_PARSERS entry: 'data = b"AB"' - literal ASCII gan TRUC
    TIEP vao bien MOI (khong constructor bytes(x)/noi '+', ngoai pham vi
    task theo dung Global Constraints cua plan). Dung PARSER THAT
    (parse_expr, tag 'bytes_lit' vua them vao il_core.py's
    _parse_factor_primary), giong het cach try_rhs_list_literal lam voi
    'list_literal'."""
    rhs_s = rhs.strip()
    if not _BYTES_LIT_RE.match(rhs_s):
        return None
    node = parse_expr(rhs_s)
    if node[0] != 'bytes_lit':
        return None
    known_shapes[name] = 'bytes'
    values = parse_bytes_literal(node[1])
    return {'kind': 'assign_bytes_literal', 'name': name, 'values': values}


def try_parse_bytes_append_blocked(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: chan '.append()' tren bien 'bytes' NGAY tai
    parser - PHAI dang ky TRUOC list_append/bytearray_append (thu tu dang
    ky trong LINE_PARSERS quyet dinh thu tu thu, giong het cach
    bytearray_type.py's try_parse_bytearray_append phai dang ky truoc de
    khong bi list.append 'cuop' - o day NGUOC LAI: bytes phai tu CHAN
    truoc khi list_append/bytearray_append kip khop, vi 'bytes' la bat
    bien, KHAC bytearray van cho .append() binh thuong)."""
    m = _BYTES_APPEND_RE.match(line)
    if not m or known_shapes.get(m.group(1)) != 'bytes':
        return None
    raise SyntaxError(
        f"il_codegen: '{m.group(1)}' la kieu 'bytes' (bat bien, tao tu literal "
        f"b\"...\") - KHONG the .append()/mutate. Dung 'bytearray' neu can thay doi duoc.")


def codegen_assign_bytes_literal(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'data = b"AB"' - unroll N gia tri hang so BIET
    TRUOC luc compile-time thanh N lan 'dup'+'ldc.i4'+'conv.u1'+'Add(!0)'
    (KHONG vong lap runtime - so phan tu da co san luc bien dich), theo
    mau codegen_assign_bytearray_new + codegen_bytearray_append cua
    bytearray_type.py nhung GHEP THANG khong qua stmt trung gian."""
    body.append(f'    newobj instance void {il_bytearray_type()}::.ctor()')
    for value in stmt['values']:
        body.append('    dup')
        body.append(f'    ldc.i4 {value}')
        body.append('    conv.u1')
        body.append(f'    callvirt instance void {il_bytearray_type()}::Add(!0)')
    ctx['store_var'](stmt['name'], scope, body)


def fpw_assign_bytes_literal(stmt, ctx):
    """FIRST_PASS_WALK: khai bao local List<uint8> voi shape='bytes'
    (KHAC 'bytearray' - il_type_str/_expr_index/len() se can nhan them
    'bytes' o cac diem doc, xem il_codegen.py; '.append()' thi KHONG
    bao gio toi duoc codegen vi da bi chan o parser, try_parse_bytes_append_blocked)."""
    ctx['declare_named'](stmt['name'], ctx['TypeAnn']('i32', 'bytes'))


register_assign_rhs_parser('bytes_literal', try_rhs_bytes_literal)
register_line_parser('bytes_append_blocked', try_parse_bytes_append_blocked)
register_stmt_codegen('assign_bytes_literal', codegen_assign_bytes_literal)
register_first_pass_walk('assign_bytes_literal', fpw_assign_bytes_literal)

# -*- coding: utf-8 -*-
"""'"...%s..." % (a, b)' / '"...%s..." % x' (Phase 1.2, 2026-08-11) -
macro TEXT-LEVEL, CUNG co che voi f-string/.format() (xem fstring.py,
string_format.py): viet lai THANH bieu thuc noi chuoi truoc khi dong
duoc parse binh thuong.

GIOI HAN DA BIET (co chu dich, hep hon .format() vi toan tu '%' KHONG co
dau '(' ro rang danh dau diem KET THUC ve phia PHAI nhu '.format(...)' -
kho xac dinh bien toan-cuc-cua-bieu-thuc an toan o muc van ban):
- Ve phai '%' CHI nhan 2 dang: 1 tuple ngoac don '(a, b, ...)' (dung lai
  _split_top_level_args cua string_format.py), HOAC 1 IDENT DON (1 bien
  don, khong bieu thuc phuc tap vd 'a+b' hay 'obj.field') - giong dung
  gioi han '{ident}' don cua fstring.py, tranh doan sai bien phai cua
  bieu thuc dai hon (vd '"%s" % x + "!"' - chi 'x' duoc coi la toan hang,
  '+ "!"' o NGOAI, giu nguyen ngu nghia).
- Conversion code ho tro: '%s' (str(arg)), '%d' (str(arg) - so nguyen da
  tu dinh dang dung qua str()), '%f'/'%.Nf' (fmt_float(arg, N), N mac
  dinh 6 giong Python neu khong ghi ro, giong '%f' mac dinh 6 chu so
  thap phan). KHONG ho tro '%r'/'%x'/'%o'/day du align/padding cua
  printf-style day du - dong khong khop se BI BO QUA (giu nguyen '%' de
  parser sau bao loi ro rang, khong am tham sinh sai).
- '%%' trong chuoi -> ky tu '%' literal (escape chuan cua Python)."""
import re

from il_dispatch import register_macro_expander
from il_features.string_format import _split_top_level_args

_PERCENT_RE = re.compile(r'%%|%(\.(\d+))?([sdf])')
_IDENT_CH = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_')


def _percent_content_to_concat_expr(content: str, pct_args) -> str:
    """'content' la noi dung ben trong dau nhay (chua '%s'/'%%'/...),
    'pct_args' la danh sach bieu thuc (dang chuoi) lay tu ve phai '%'.
    Tra ve bieu thuc noi chuoi tuong duong."""
    parts = []
    idx = 0
    pos = 0
    for m in _PERCENT_RE.finditer(content):
        literal = content[pos:m.start()]
        if literal:
            parts.append(f'"{literal}"')
        pos = m.end()
        if m.group(0) == '%%':
            parts.append('"%"')
            continue
        if idx >= len(pct_args):
            raise SyntaxError(
                f"il_codegen: '%' string-formatting thieu tham so cho placeholder thu {idx + 1} "
                f"(chi truyen {len(pct_args)} tham so)")
        arg_expr = pct_args[idx]
        idx += 1
        conv = m.group(3)
        if conv == 'f':
            precision = m.group(2) or '6'
            parts.append(f'fmt_float({arg_expr}, {precision})')
        else:
            parts.append(f'str({arg_expr})')
    tail = content[pos:]
    if tail:
        parts.append(f'"{tail}"')
    if not parts:
        return '""'
    return '(' + ' + '.join(parts) + ')'


def _capture_percent_rhs(line: str, i: int):
    """'i' tro ngay SAU ky tu '%' (da bo qua khoang trang). Tra ve
    (danh_sach_bieu_thuc, chi_so_ket_thuc) neu nhan dang duoc 1 trong 2
    dang ho tro (tuple ngoac don hoac 1 ident don), None neu khong (macro
    bo qua dong, khong dam doan)."""
    n = len(line)
    if i < n and line[i] == '(':
        depth = 0
        quote = None
        j = i
        while j < n:
            ch = line[j]
            if quote:
                if ch == quote:
                    quote = None
            elif ch in ('"', "'"):
                quote = ch
            elif ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    args_str = line[i + 1:j]
                    return _split_top_level_args(args_str), j + 1
            j += 1
        return None
    j = i
    while j < n and line[j] in _IDENT_CH:
        j += 1
    if j == i:
        return None
    ident = line[i:j]
    if not ident[0].isalpha() and ident[0] != '_':
        return None
    return [ident], j


def try_expand_percent_format(line: str):
    """MACRO_EXPANDERS entry - tim '"literal" % (args_hoac_1_bien)' va
    thay THE bang bieu thuc noi chuoi. Quet CO TRANG THAI CHUOI (giong
    fstring.py/string_format.py); tra None neu dong khong co pattern
    nay (giu nguyen, khong dam doan khi cu phap ve phai qua phuc tap)."""
    if '%' not in line or '"' not in line:
        return None
    out = []
    i = 0
    n = len(line)
    changed = False
    while i < n:
        ch = line[i]
        if line.startswith('"""', i) or line.startswith("'''", i):
            out.append(line[i:i + 3])
            i += 3
            continue
        if ch == '"':
            end = line.find('"', i + 1)
            if end < 0:
                out.append(line[i:])
                break
            content = line[i + 1:end]
            j = end + 1
            while j < n and line[j] == ' ':
                j += 1
            if j < n and line[j] == '%' and not line.startswith('%=', j) and not line.startswith('%%', j):
                k = j + 1
                while k < n and line[k] == ' ':
                    k += 1
                captured = _capture_percent_rhs(line, k)
                if captured is not None:
                    pct_args, rhs_end = captured
                    out.append(_percent_content_to_concat_expr(content, pct_args))
                    i = rhs_end
                    changed = True
                    continue
            out.append(line[i:end + 1])
            i = end + 1
            continue
        if ch == "'":
            end = line.find("'", i + 1)
            if end < 0:
                out.append(line[i:])
                break
            out.append(line[i:end + 1])
            i = end + 1
            continue
        out.append(ch)
        i += 1
    if not changed:
        return None
    return ''.join(out)


register_macro_expander('string_percent_format', try_expand_percent_format)

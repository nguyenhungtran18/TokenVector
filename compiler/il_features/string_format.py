# -*- coding: utf-8 -*-
"""'"...".format(a, b, ...)' (Phase 1.1, 2026-08-11) - macro TEXT-LEVEL,
CUNG co che voi f-string (xem fstring.py): viet lai THANH bieu thuc noi
chuoi '(" ... " + str(a) + " ... ")' TRUOC khi dong duoc parse binh
thuong, dung chung MACRO_EXPANDERS/_expand_macros (chay lap toi diem co
dinh) - khong can tag AST rieng, khong can runtime string-parsing.

GIOI HAN DA BIET (co chu dich, giong tinh than gioi han cua fstring.py):
- CHI nhan dang '"literal".format(...)' - chuoi literal PHAI dung TRUC
  TIEP truoc '.format(' (khong ho tro 's.format(...)' voi 's' la 1 bien
  giu san chuoi format, vi macro chay o muc VAN BAN TRUOC first-pass suy
  kieu, khong biet noi dung chuoi cua 1 bien tai thoi diem nay).
- Placeholder ho tro: '{}' (tu dong danh so tang dan), '{N}' (chi so
  tuong minh, cho phep "index reorder" - dung lai chi so nhieu lan/dao
  thu tu), '{N:.Mf}'/'{:.Mf}' (spec so thap phan co dinh, viet lai thanh
  fmt_float(arg, M) NEU arg la 1 BIEN don, nguoc lai fmt_float bao loi
  ro rang - gioi han sinh tu chinh fmt_float(), xem string_feature.py),
  '{name}' + '.format(name=value)' (keyword args, batch 5.5b muc 3,
  2026-08-13 - '=' KHONG theo sau boi '=' khac de tranh khop nham
  '=='/'>='/'<='/'!=', positional+keyword tron lan duoc). KHONG ho tro
  spec khac ('.Nf' la spec DUY NHAT co san qua fmt_float(), vd
  '{:>10}'/'{:,}' se KHONG duoc nhan dang, macro se BO QUA dong do - giu
  nguyen '.format(' de parser sau bao loi ro rang "khong nhan dang duoc
  method 'format'" thay vi am tham sinh sai)."""
import re

from il_dispatch import register_macro_expander

_PLACEHOLDER_RE = re.compile(r'\{(\w*)(:\.(\d+)f)?\}')

_KWARG_RE = re.compile(r'^(\w+)\s*=(?!=)(.*)$', re.DOTALL)


def _split_top_level_args(s: str):
    """Tach 's' (noi dung ben trong '(...)') thanh (positional, kwargs)
    theo dau phay O MUC NGOAI CUNG - bo qua dau phay nam trong ngoac/
    chuoi con long ben trong (vd 'f(a, b)' hay '"a, b"' la 1 tham so,
    khong phai 2). Rong -> ([], {}) (ham .format() khong tham so).
    Moi phan tach duoc PHAN LOAI positional/keyword bang _KWARG_RE
    ('name=value', dau '=' KHONG theo sau boi '=' khac - tranh kop nham
    '=='/'>='/'<='/'!=' ben trong bieu thuc doi so) - batch 5.5b muc 3,
    2026-08-13."""
    s = s.strip()
    if not s:
        return [], {}
    raw_parts = []
    depth = 0
    quote = None
    start = 0
    i = 0
    n = len(s)
    while i < n:
        ch = s[i]
        if quote:
            if ch == quote:
                quote = None
        elif ch in ('"', "'"):
            quote = ch
        elif ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
        elif ch == ',' and depth == 0:
            raw_parts.append(s[start:i].strip())
            start = i + 1
        i += 1
    raw_parts.append(s[start:].strip())

    positional = []
    kwargs = {}
    for part in raw_parts:
        m = _KWARG_RE.match(part)
        if m:
            kwargs[m.group(1)] = m.group(2).strip()
        else:
            positional.append(part)
    return positional, kwargs


def _find_matching_paren(line: str, open_idx: int):
    """'open_idx' tro vao dau '(' ngay sau '.format' - tra ve chi so cua
    ')' KHOP (bo qua dau ngoac/nhay nam trong chuoi con) hoac None neu
    khong tim thay (dong bi cat cut/loi cu phap - de nguyen, khong sinh
    sai)."""
    depth = 0
    quote = None
    i = open_idx
    n = len(line)
    while i < n:
        ch = line[i]
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
                return i
        i += 1
    return None


def _format_content_to_concat_expr(content: str, format_args, kwargs) -> str:
    """'content' la noi dung BEN TRONG dau nhay cua chuoi format (khong
    kem dau nhay), 'format_args' la danh sach bieu thuc POSITIONAL,
    'kwargs' la dict TEN -> bieu thuc KEYWORD (batch 5.5b muc 3,
    2026-08-13). Tra ve bieu thuc noi chuoi tuong duong, CUNG khuon voi
    fstring.py's _fstring_to_concat_expr."""
    pieces = _PLACEHOLDER_RE.split(content)
    parts = []
    auto_idx = 0
    i = 0
    while i < len(pieces):
        literal = pieces[i]
        if literal:
            parts.append(f'"{literal}"')
        if i + 1 >= len(pieces):
            break
        idx_str, _full_spec, precision = pieces[i + 1], pieces[i + 2], pieces[i + 3]
        if idx_str == '':
            arg_expr = format_args[auto_idx] if auto_idx < len(format_args) else None
            if arg_expr is None:
                raise SyntaxError(
                    f"il_codegen: .format() thieu tham so cho placeholder tu dong "
                    f"chi so {auto_idx} (chi truyen {len(format_args)} tham so positional)")
            auto_idx += 1
        else:
            try:
                idx = int(idx_str)
            except ValueError:
                if idx_str not in kwargs:
                    raise SyntaxError(
                        f"il_codegen: .format() thieu tham so keyword '{idx_str}'")
                arg_expr = kwargs[idx_str]
            else:
                if idx >= len(format_args):
                    raise SyntaxError(
                        f"il_codegen: .format() thieu tham so cho placeholder chi so {idx} "
                        f"(chi truyen {len(format_args)} tham so positional)")
                arg_expr = format_args[idx]
        if precision is not None:
            parts.append(f'fmt_float({arg_expr}, {precision})')
        else:
            parts.append(f'str({arg_expr})')
        i += 4
    if not parts:
        return '""'
    return '(' + ' + '.join(parts) + ')'


def try_expand_format(line: str):
    """MACRO_EXPANDERS entry - tim '"literal".format(args)' (co the
    nhieu lan tren CUNG 1 dong) va thay THE bang bieu thuc noi chuoi.
    Quet CO TRANG THAI CHUOI (giong fstring.py) de khong nham chuoi ben
    trong 1 chuoi khac; tra None neu dong khong co pattern nay."""
    if '.format(' not in line:
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
            if line.startswith('.format(', end + 1):
                open_idx = end + 1 + len('.format')
                close_idx = _find_matching_paren(line, open_idx)
                if close_idx is not None:
                    args_str = line[open_idx + 1:close_idx]
                    format_args, format_kwargs = _split_top_level_args(args_str)
                    out.append(_format_content_to_concat_expr(content, format_args, format_kwargs))
                    i = close_idx + 1
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


register_macro_expander('string_format', try_expand_format)

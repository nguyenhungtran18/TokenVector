# -*- coding: utf-8 -*-
"""Hoist bieu thuc ra bien tam (2026-08-03, dot 2).

Rat nhieu duong xu ly cua compiler CHI nhan 1 TEN BIEN o vi tri doi
tuong nhan / doi so (vi chung tra cuu scope[ten] truc tiep): 'sorted(xs)',
'sep.join(xs)', 'lst.append(...)', 'lst.pop()', 'd.get(k, v)'... Nguoi
viet code that thi viet 'sorted(d.keys())' hoac 'b.items.append(x)'.

Thay vi nhan doi tung duong do, o day dat 1 BIEN TAM ngay TRUOC dong
dang xet roi thay bieu thuc bang ten bien tam:

    b.items.append(x)        ->  __hoist0 = b.items
                                 __hoist0.append(x)
    keys = sorted(d.keys())  ->  __hoist1 = d.keys()
                                 keys = sorted(__hoist1)

Dung duoc vi list/dict/chuoi/record deu la KIEU THAM CHIEU trong .NET:
bien tam tro toi CUNG doi tuong, mutate qua no la mutate that. Day cung
la ky thuat da dung cho 'self.<field container>' (xem
_hoist_container_fields trong il_codegen.py).

Macro nay chay o tang VAN BAN (giong cac macro khac) va PHAI duoc thu
TRUOC cac macro sinh ra cu phap moi."""
import re

from il_dispatch import register_macro_expander

_counter = [0]

# '<ten>.<ten>.<method>(' - doi tuong nhan la 1 THUOC TINH, khong phai
# ten bien don. Khong bat 'self.x.y(' (self.<field container> da duoc
# hoist rieng) va khong bat khi truoc do con dau '.' (chuoi dai hon).
_ATTR_RECV_RE = re.compile(r'(?<![\w.])(\w+)\.(\w+)\.(\w+)\(')

# '<ten>.<ten>[' - chi so tren 1 THUOC TINH (doc hoac gan).
_ATTR_INDEX_RE = re.compile(r'(?<![\w.])(\w+)\.(\w+)\[')

# 'sorted(<bieu thuc>)' - CHI hoist khi doi so KHONG phai 1 ten don.
_WRAPPER_CALLS = ('sorted', 'sum', 'max', 'min', 'any', 'all', 'len', 'json_dumps')

_SIMPLE_NAME_RE = re.compile(r'^\w+$')

# 'a.shape[0]' la CU PHAP RIENG (kich thuoc mang, biet luc bien dich) -
# hoist no ra bien tam se pha cu phap. Khong dung cho field nguoi dung.
_NO_HOIST_FIELDS = ('shape',)


def _mask_strings_and_comments(line):
    """Thay the tat ca string literal ('...' hoac "...") va comment (#...)
    bang placeholder an '__STR_LIT_N__' de regex hoisting khong bao gio
    quet trung va lam hong chuoi ky tu (Moc 13, 2026-08-08)."""
    placeholders = []
    comment_pos = -1
    in_quote = None
    for i, ch in enumerate(line):
        if in_quote:
            if ch == '\\':
                pass
            elif ch == in_quote:
                in_quote = None
        else:
            if ch in ('"', "'"):
                in_quote = ch
            elif ch == '#':
                comment_pos = i
                break

    code_part = line[:comment_pos] if comment_pos >= 0 else line
    comment_part = line[comment_pos:] if comment_pos >= 0 else ""

    result = []
    i = 0
    while i < len(code_part):
        ch = code_part[i]
        if ch in ('"', "'"):
            quote = ch
            start = i
            i += 1
            while i < len(code_part):
                if code_part[i] == '\\':
                    i += 2
                    continue
                if code_part[i] == quote:
                    i += 1
                    break
                i += 1
            lit = code_part[start:i]
            idx = len(placeholders)
            ph = f"__STR_LIT_{idx}__"
            placeholders.append((ph, lit))
            result.append(ph)
        else:
            result.append(ch)
            i += 1

    masked_line = "".join(result) + comment_part
    return masked_line, placeholders


def _unmask_strings(text, placeholders):
    for ph, lit in reversed(placeholders):
        text = text.replace(ph, lit)
    return text


def _find_close(text, open_idx):
    """Chi so cua ')' khop voi '(' o open_idx (bo qua ngoac trong chuoi)."""
    depth = 0
    quote = None
    i = open_idx
    while i < len(text):
        ch = text[i]
        if quote is not None:
            if ch == '\\':
                i += 2
                continue
            if ch == quote:
                quote = None
        elif ch in ('"', "'"):
            quote = ch
        elif ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def _next_name():
    n = _counter[0]
    _counter[0] += 1
    return f'__hoist{n}'


def _hoist_attr_receiver(stripped):
    """'b.items.append(x)' -> ('__hoistN = b.items', 'b.items' -> ten moi).
    Tra ve (prologue, dong_moi) hoac None."""
    m = _ATTR_RECV_RE.search(stripped)
    if not m:
        return None
    obj, field, _method = m.groups()
    if field in _NO_HOIST_FIELDS:
        return None
    tmp = _next_name()
    target = f'{obj}.{field}'
    new_line = stripped.replace(target + '.', tmp + '.', 1)
    return f'{tmp} = {target}', new_line


def _hoist_attr_index(stripped):
    """'b.scores["x"] = 1.5' / 'v = b.scores[k]' -> dat bi danh cho
    'b.scores' truoc. Gan CHI SO tren 1 thuoc tinh khong co duong rieng
    (chi 'ten_bien[i] = v' moi co)."""
    m = _ATTR_INDEX_RE.search(stripped)
    if not m:
        return None
    obj, field = m.groups()
    if field in _NO_HOIST_FIELDS:
        return None
    tmp = _next_name()
    target = f'{obj}.{field}'
    new_line = stripped.replace(target + '[', tmp + '[', 1)
    return f'{tmp} = {target}', new_line


def _hoist_wrapper_arg(stripped):
    """'sorted(d.keys())' -> ('__hoistN = d.keys()', 'sorted(__hoistN)')."""
    for fname in _WRAPPER_CALLS:
        pat = re.compile(r'(?<![\w.])' + fname + r'\(')
        m = pat.search(stripped)
        if not m:
            continue
        open_idx = m.end() - 1
        close_idx = _find_close(stripped, open_idx)
        if close_idx < 0:
            continue
        arg = stripped[open_idx + 1:close_idx].strip()
        if not arg or _SIMPLE_NAME_RE.match(arg) or ',' in arg:
            continue
        if '.' not in arg and '(' not in arg:
            continue
        tmp = _next_name()
        new_line = stripped[:open_idx + 1] + tmp + stripped[close_idx:]
        return f'{tmp} = {arg}', new_line
    return None


def try_expand_expr_hoist(line):
    """MACRO_EXPANDERS entry - tra ve van ban da mo rong (2 dong) hoac None."""
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        return None
    if stripped.startswith('def ') or stripped.startswith('class '):
        return None
    if stripped.startswith(('"""', "'''")):
        return None
    is_block = re.match(r'^(if|while|elif|with|else|try|except|finally)\b', stripped)
    if is_block:
        return None
    indent = ' ' * (len(line) - len(line.lstrip(' ')))
    masked_line, placeholders = _mask_strings_and_comments(stripped)
    for fn in (_hoist_attr_receiver, _hoist_attr_index, _hoist_wrapper_arg):
        got = fn(masked_line)
        if got:
            prologue, new_line = got
            prologue = _unmask_strings(prologue, placeholders)
            new_line = _unmask_strings(new_line, placeholders)
            return f'{indent}{prologue}\n{indent}{new_line}'
    return None


register_macro_expander('expr_hoist', try_expand_expr_hoist)


# 'x is None' / 'x is not None' (2026-08-03, dot 1) - so sanh THAM CHIEU
# voi tham chieu rong. Doi thang sang '==' / '!=' voi None: tren kieu
# THAM CHIEU, 'ceq' cua CIL chinh la so sanh tham chieu, dung ngu nghia
# 'is' cua Python cho truong hop None (truong hop duy nhat DSL nay can).
_IS_NOT_NONE_RE = re.compile(r'\bis\s+not\s+None\b')
_IS_NONE_RE = re.compile(r'\bis\s+None\b')


def try_expand_is_none(line):
    """MACRO_EXPANDERS entry - chay duoc tren MOI dong (ke ca dong mo
    khoi 'if'/'while'), khac hoist bieu thuc."""
    if 'is' not in line:
        return None
    out = _IS_NOT_NONE_RE.sub('!= None', line)
    out = _IS_NONE_RE.sub('== None', out)
    return out if out != line else None


register_macro_expander('is_none', try_expand_is_none)

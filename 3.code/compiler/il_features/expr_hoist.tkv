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
_WRAPPER_CALLS = ('sorted', 'sum', 'max', 'min', 'any', 'all', 'len')

_SIMPLE_NAME_RE = re.compile(r'^\w+$')

# 'a.shape[0]' la CU PHAP RIENG (kich thuoc mang, biet luc bien dich) -
# hoist no ra bien tam se pha cu phap. Khong dung cho field nguoi dung.
_NO_HOIST_FIELDS = ('shape',)


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
    # 'self.<field>' KHONG bi loai tru: field CONTAINER cua self da duoc
    # doi ten thanh '__self_<field>' TRUOC khi macro chay (xem
    # _hoist_container_fields), nen 'self.x' con lai o day la field vo
    # huong hoac field kieu record - hoist duoc binh thuong.
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
        # Chi hoist khi doi so la 1 LOI GOI / thuoc tinh (co '.' hoac '(')
        # - bieu thuc so hoc thi cac duong hien co da xu ly duoc.
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
    # Dong mo khoi ('for'/'if'/'while'/'with'/'elif') KHONG hoist duoc theo
    # cach nay: bien tam phai dat TRUOC dong, nhung voi 'while' thi no chi
    # duoc tinh 1 lan - sai ngu nghia. Chi cho 'for ... in ...:' vi ve phai
    # cua 'for' cung chi duoc tinh 1 lan trong Python.
    is_block = re.match(r'^(if|while|elif|with|else|try|except|finally)\b', stripped)
    if is_block:
        return None
    indent = ' ' * (len(line) - len(line.lstrip(' ')))
    for fn in (_hoist_attr_receiver, _hoist_attr_index, _hoist_wrapper_arg):
        got = fn(stripped)
        if got:
            prologue, new_line = got
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

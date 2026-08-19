# -*- coding: utf-8 -*-
"""enumerate()/zip() trong for-loop (Wave 2, 2026-07-29) - CA HAI deu la
macro TEXT-LEVEL (khong CIL/loop moi), desugar ve dang 'for i in
range(...):' + index da co san, giong for_in_list o control_flow.py.
Gemini-drafted (enumerate + khung zip), Claude hoan thien phan zip():
Gemini dung dan TU CHOI doan len() vi khong xac dinh duoc DSL co ham
'min()' built-in hay khong (thuc te KHONG CO min()/max() trong
_MATH_FUNCS cua il_codegen.py) - thay vi them 1 ham built-in moi ngoai
pham vi, dung LAI cu phap ternary 'cond ? a : b' DA CO SAN (xem
il_core.py's parse_ternary) de tinh min(len(a), len(b)) ngay trong
bound-expression cua range(), khong can sinh CIL/local moi."""
import re

from il_dispatch import register_macro_expander

# =============================================================================
# 1. ENUMERATE: for i, x in enumerate(lst):
# =============================================================================
_FOR_ENUMERATE_RE = re.compile(r'^for\s+(\w+)\s*,\s*(\w+)\s+in\s+enumerate\((\w+)\)\s*:\s*$')


def try_expand_for_enumerate(line):
    stripped = line.strip()
    m = _FOR_ENUMERATE_RE.match(stripped)
    if not m:
        return None
    idx_name, elem_name, container = m.groups()
    ind = ' ' * (len(line) - len(line.lstrip(' ')))
    # 'i' la ten bien THAT nguoi dung dat (khac for_in_list phai tu sinh
    # ten an) - dung THANG, khong can bo dem.
    return f'{ind}for {idx_name} in range(len({container})):\n{ind}    {elem_name} = {container}[{idx_name}]'


# =============================================================================
# 2. ZIP: for a, b, ... in zip(lst1, lst2, ...): - N-ary (Phase 2.1,
# 2026-08-11: mo rong tu CHI 2 list len N list bat ky >= 2, van CUNG kien
# truc for-header macro nhu ban dau, khong doi). GIOI HAN VAN GIU (khong
# doi tu ban dau): CHI dang trong header 'for ... in zip(...):' voi cac
# ten bien/list la IDENT tran - CHUA ho tro 'zip(...)' o VI TRI BIEU THUC
# doc lap (vd 'lst_cap = list(zip(a, b))') vi can 1 kieu list-cua-tuple
# moi (chua co trong DSL, xem tuple_type.py - chi ho tro tuple SCALAR
# tra ve/gan, khong phai PHAN TU cua list) - de lai cho phien sau, can
# thiet ke kieu du lieu rieng, khong phai mo rong macro nay.
# =============================================================================
_FOR_ZIP_RE = re.compile(r'^for\s+([\w\s,]+?)\s+in\s+zip\(([\w\s,]+?)\)\s*:\s*$')
_me_zip_counter = [0]


def _min_len_expr(lists):
    """min(len(l) for l in lists) qua ternary long nhau (khong dung ham
    'min()' built-in - khong co san cho > 2 doi so, xem docstring dau
    file). Vd 3 list -> '(len(a) < (len(b) < len(c) ? len(b) : len(c))
    ? len(a) : (len(b) < len(c) ? len(b) : len(c)))'."""
    if len(lists) == 1:
        return f'len({lists[0]})'
    rest = _min_len_expr(lists[1:])
    head = f'len({lists[0]})'
    return f'({head} < ({rest}) ? {head} : ({rest}))'


def try_expand_for_zip(line):
    stripped = line.strip()
    m = _FOR_ZIP_RE.match(stripped)
    if not m:
        return None
    var_names = [v.strip() for v in m.group(1).split(',')]
    list_names = [l.strip() for l in m.group(2).split(',')]
    if len(var_names) != len(list_names) or len(list_names) < 2:
        return None
    ind = ' ' * (len(line) - len(line.lstrip(' ')))
    n = _me_zip_counter[0]
    _me_zip_counter[0] += 1
    idx = f'__iterzip{n}_idx'
    bound = _min_len_expr(list_names)
    body_lines = ''.join(
        f'{ind}    {var} = {lst}[{idx}]\n' for var, lst in zip(var_names, list_names))
    return f'{ind}for {idx} in range({bound}):\n{body_lines}'.rstrip('\n')


# =============================================================================
# 3. CHAIN: for x in chain(lst1, lst2, ...): (Phase 5.3 tiep, 2026-08-12)
# N-ary, dung LAI ternary long nhau (giong _min_len_expr cua zip) de anh
# xa 1 chi so ao __chainN_i sang dung list/vi tri that - khong sinh
# CIL/local moi, chi la 1 'for i in range(tong_do_dai): x = <ternary>'.
# =============================================================================
_FOR_CHAIN_RE = re.compile(r'^for\s+(\w+)\s+in\s+chain\(([\w\s,]+?)\)\s*:\s*$')
_me_chain_counter = [0]


def _chain_elem_expr(lists, offset_expr):
    """Ternary long nhau: offset < len(lists[0]) ? lists[0][offset] :
    <de quy voi phan con lai, offset da tru do dai list truoc>. SUA
    2026-08-12 (bug that phat hien qua test 3-list): dieu kien SO SANH
    phai dung offset_expr DA DICH cua CAP DO HIEN TAI, khong phai idx
    goc ban dau - vi du voi 3 list [a,b,c], o cap do xet 'b' dieu kien
    dung la '(idx - len(a)) < len(b)', KHONG PHAI 'idx < len(b)' (truoc
    day dung idx goc, sai hoan toan tu list thu 3 tro di - gay
    ArgumentOutOfRangeException THAT luc chay, khong chi ly thuyet)."""
    if len(lists) == 1:
        return f'{lists[0]}[{offset_expr}]'
    head = lists[0]
    rest = _chain_elem_expr(lists[1:], f'({offset_expr} - len({head}))')
    return f'({offset_expr} < len({head}) ? {head}[{offset_expr}] : {rest})'


def try_expand_for_chain(line):
    stripped = line.strip()
    m = _FOR_CHAIN_RE.match(stripped)
    if not m:
        return None
    var_name = m.group(1).strip()
    list_names = [l.strip() for l in m.group(2).split(',')]
    if len(list_names) < 2:
        return None
    ind = ' ' * (len(line) - len(line.lstrip(' ')))
    n = _me_chain_counter[0]
    _me_chain_counter[0] += 1
    idx = f'__chain{n}_idx'
    total_len = ' + '.join(f'len({l})' for l in list_names)
    elem_expr = _chain_elem_expr(list_names, idx)
    return f'{ind}for {idx} in range({total_len}):\n{ind}    {var_name} = {elem_expr}'


# PRODUCT ('for x, y in product(a, b):') - THU nhung BO (Phase 5.3 tiep,
# 2026-08-12): co che macro TEXT-LEVEL nay chi thay THE 1 dong (dong
# 'for' bi khop) - than vong lap GOC (cac dong sau, da o san trong
# body_lines voi indent CU) khong duoc DICH CHUYEN sau khi macro chen
# them 1 vong 'for' long nhau moi. Voi chain/zip/enumerate dieu nay OK
# (chi 1 vong moi, than goc tro thanh SIBLING dung cap), nhung product()
# can 2 vong long nhau THAT - than goc se lot ra NGOAI vong trong thay vi
# nam trong no (sai ngu nghia, xac nhan qua phan tich cau truc truoc khi
# viet code, KHONG can thu nghiem that de biet no sai). Giai phap dung
# (dich chuyen indent cac dong sau) can sua _expand_macros_once, ngoai
# pham vi 1 macro don le - ĐE LAI cho phien sau. Nguoi dung viet 2 vong
# 'for' long nhau THAT (da ho tro san, khong can macro) thay the:
#   for i in range(len(a)):
#       x = a[i]
#       for j in range(len(b)):
#           y = b[j]
#           ...


# =============================================================================
# DANG KY MACRO
# =============================================================================
register_macro_expander('for_enumerate', try_expand_for_enumerate)
register_macro_expander('for_zip', try_expand_for_zip)
register_macro_expander('for_chain', try_expand_for_chain)

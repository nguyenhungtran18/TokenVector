# -*- coding: utf-8 -*-
"""List/dict/set comprehension - macro TEXT-LEVEL, khong sinh codegen
moi (chi khai trien thanh for-loop+append/idx_assign/add da co san, xem
list_type.py/dict_type.py/set_type.py). Tach rieng file theo tinh nang
(Phase 1 buoc 4, 2026-07-28) - hoan toan tu than (khong phu thuoc
_Scope/CIL/parse_expr), nen KHONG can quy uoc dependency-injection qua
`ctx` nhu cac buoc truoc."""
import re

from il_dispatch import register_macro_expander

_LIST_COMP_OUTER_RE = re.compile(r'^(\w+)\s*=\s*\[(.+)\]\s*$')
_DICT_COMP_OUTER_RE = re.compile(r'^(\w+)\s*=\s*\{(.+)\}\s*$')


def parse_comprehension_inner(inner):
    """Tach 'EXPR for VAR[, VAR2] in ITERABLE [if COND]' (dung chung cho
    ca list va dict comprehension - dict truyen ca 'KEXPR: VEXPR' lam
    EXPR, tach rieng o noi goi). Dung tim tu khoa 'for'/'in'/'if' DAU
    TIEN (khong dung regex 1 khoi vi EXPR/ITERABLE co the chua dau
    ngoac vuong long nhau, giong bai hoc tu bug 'd[lst[i]]' truoc do) -
    tra ve None neu khong phai dang comprehension (khong co 'for')."""
    m = re.search(r'\bfor\b', inner)
    if not m:
        return None
    head, rest = inner[:m.start()].strip(), inner[m.end():].strip()
    m2 = re.search(r'\bin\b', rest)
    if not m2:
        return None
    var_part, tail = rest[:m2.start()].strip(), rest[m2.end():].strip()
    m3 = re.search(r'\bif\b', tail)
    if m3:
        iterable, cond = tail[:m3.start()].strip(), tail[m3.end():].strip()
    else:
        iterable, cond = tail, None
    return {'expr': head, 'var_part': var_part, 'iterable': iterable, 'cond': cond}


def try_expand_list_comp(line):
    """MACRO_EXPANDERS entry: list comprehension - CHI la duong tat cu
    phap cho for-loop+append DA CO SAN (khong sinh codegen moi) - giong
    tinh than 'for x in lst:'. Ket qua co the con dang 'for x in lst:'
    (macro CHUA mo rong o VONG NAY) - _expand_macros (ham bao trong
    il_codegen.py) lap toi diem co dinh nen se duoc mo rong o vong sau."""
    stripped = line.strip()
    ind = ' ' * (len(line) - len(line.lstrip(' ')))
    m = _LIST_COMP_OUTER_RE.match(stripped)
    if not m:
        return None
    name, inner = m.groups()
    parsed = parse_comprehension_inner(inner)
    if not (parsed and ',' not in parsed['var_part']):
        return None
    expr, var, iterable, cond = (parsed['expr'], parsed['var_part'],
                                  parsed['iterable'], parsed['cond'])
    lines_out = [f'{ind}{name} = []', f'{ind}for {var} in {iterable}:']
    if cond:
        lines_out.append(f'{ind}    if {cond}:')
        lines_out.append(f'{ind}        {name}.append({expr})')
    else:
        lines_out.append(f'{ind}    {name}.append({expr})')
    return '\n'.join(lines_out)


def try_expand_dict_or_set_comp(line):
    """MACRO_EXPANDERS entry: dict/set comprehension - CUNG 1 cu phap
    ngoai '{...}', phan biet dict-comp ('{k: v for ...}') vs set-comp
    ('{expr for ...}') bang su co mat ':'. LUU Y gioi han: bieu thuc
    ba-ngoi ('cond ? a : b') cung chua ':', nen kiem tra THEM '?' KHONG
    co mat truoc khi ket luan la dict-comp (set-comp dung ternary se van
    roi dung nhanh set, vi co '?'). Heuristic van ban nay MONG MANH (co
    the nham trong truong hop bat thuong) - GIU NGUYEN, khong sua trong
    pham vi refactor nay."""
    stripped = line.strip()
    ind = ' ' * (len(line) - len(line.lstrip(' ')))
    m = _DICT_COMP_OUTER_RE.match(stripped)
    if not m:
        return None
    name, inner = m.groups()
    parsed = parse_comprehension_inner(inner)
    if parsed and ':' in parsed['expr'] and '?' not in parsed['expr']:
        kexpr, vexpr = parsed['expr'].split(':', 1)
        kexpr, vexpr = kexpr.strip(), vexpr.strip()
        var_part, iterable, cond = parsed['var_part'], parsed['iterable'], parsed['cond']
        lines_out = [f'{ind}{name} = {{}}', f'{ind}for {var_part} in {iterable}:']
        if cond:
            lines_out.append(f'{ind}    if {cond}:')
            lines_out.append(f'{ind}        {name}[{kexpr}] = {vexpr}')
        else:
            lines_out.append(f'{ind}    {name}[{kexpr}] = {vexpr}')
        return '\n'.join(lines_out)
    if parsed and ',' not in parsed['var_part']:
        expr, var, iterable, cond = (parsed['expr'], parsed['var_part'],
                                      parsed['iterable'], parsed['cond'])
        lines_out = [f'{ind}{name} = set()', f'{ind}for {var} in {iterable}:']
        if cond:
            lines_out.append(f'{ind}    if {cond}:')
            lines_out.append(f'{ind}        {name}.add({expr})')
        else:
            lines_out.append(f'{ind}    {name}.add({expr})')
        return '\n'.join(lines_out)
    return None


# Dang ky vao il_dispatch NGAY LUC MODULE NAP.
register_macro_expander('list_comp', try_expand_list_comp)
register_macro_expander('dict_or_set_comp', try_expand_dict_or_set_comp)

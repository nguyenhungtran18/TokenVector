# -*- coding: utf-8 -*-
"""Slicing 'a[i:j]' cho list VA string (2026-07-29, Wave 1 Nhom A - P0).
Cu phap parse tag 'slice' o il_core.py (dung CHUNG cho ca 2 truong hop,
khong co syntax rieng - phan biet luc CODEGEN qua shape/dtype cua bien
nguon, giong cach _expr_index re nhanh list/dict/string/mang).

PHAM VI CO CHU DICH (gioi han da biet, khong phai thieu cong suc): CHI ho
tro slice o vi tri RHS TRUC TIEP cua 1 phep gan don ('sub = lst[i:j]' /
'sub = s[i:j]') - KHONG ho tro long trong bieu thuc khac (vd
'foo(lst[i:j])', 'lst[i:j][0]'). Ly do: local AN giu gia tri 'start'
(tinh 1 lan, dung 2 lan - lam tham so dau cua GetRange()/Substring() VA
lam so hang tru khi tinh 'count') chi duoc cap phat o 2 diem vao BIET
TRUOC (_fpw_assign_scalar cho truong hop string, fpw_assign_list_slice o
day cho truong hop list) - dung slice o noi khac se bi loi ro rang luc
compile (thieu local AN), khong bao gio sinh sai ma khong bao.

Chi so AM (Python 'lst[-2:]'): CHI ho tro HANG SO tai compile-time (vd
'lst[-2:]'/'s[:-1]'), giong emit_index_value's gioi han cho 'lst[-1]' -
doi thanh Count/Length - N. Bieu thuc am DONG ('lst[-i:]') VAN chua ho
tro - .NET GetRange()/Substring() se nem ArgumentOutOfRangeException LUC
CHAY neu dung (khong kiem tra rieng luc compile)."""
import re

from il_core import parse_expr
from il_dispatch import (
    register_assign_rhs_parser, register_expr_codegen,
    register_first_pass_walk, register_stmt_codegen,
)
from il_features.list_type import il_list_type

_SLICE_RHS_RE = re.compile(r'^(\w+)\[[^\[\]]*:[^\[\]]*\]$')


def try_rhs_list_slice(rhs, name, known_shapes):
    """ASSIGN_RHS_PARSERS entry: 'sub = lst[i:j]' KHI 'lst' DA BIET la
    list (known_shapes, seed tu tham so HOAC tu 'lst = []' truoc do trong
    CUNG ham). Khong khop (tra None) khi nguon KHONG phai list - roi
    xuong fallback 'assign_scalar' chung (truong hop string, _infer_dtype's
    nhanh 'slice' xu ly, xem il_codegen.py)."""
    m = _SLICE_RHS_RE.match(rhs.strip())
    if not m or known_shapes.get(m.group(1)) != 'list':
        return None
    node = parse_expr(rhs)
    if node[0] != 'slice':
        return None
    known_shapes[name] = 'list'
    return {'kind': 'assign_list_slice', 'name': name, 'slice_node': node}


def compile_slice(node, scope, out, dtype, ctx):
    """EXPR_CODEGEN entry cho tag 'slice' - dung CHUNG list/string.
    (Moc 11, 2026-08-08: Ho tro kep bien & chi so AM DONG tai runtime chuan Python)"""
    src_name, start_node, stop_node = node[1], node[2], node[3]
    _, _, src_ta = scope[src_name]
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']

    if src_ta.shape == 'list':
        list_type = il_list_type(src_ta.dtype, (ctx or {}).get('records'))
        count_call = f'callvirt instance int32 {list_type}::get_Count()'
        slice_call = (
            f'callvirt instance class [mscorlib]System.Collections.Generic.List`1<!0> '
            f'{list_type}::GetRange(int32, int32)')
    elif src_ta.dtype == 'str' and src_ta.shape is None:
        count_call = 'callvirt instance int32 [mscorlib]System.String::get_Length()'
        slice_call = 'callvirt instance string [mscorlib]System.String::Substring(int32, int32)'
    else:
        raise SyntaxError(
            f"il_codegen: '{src_name}[i:j]' chi ho tro tren list hoac string, "
            f"'{src_name}' co shape={src_ta.shape!r} dtype={src_ta.dtype!r}")

    _, start_idx, _ = scope[f'__slice{id(node)}_start']
    _, stop_idx, _ = scope[f'__slice{id(node)}_stop']
    _, count_idx, _ = scope[f'__slice{id(node)}_count']

    def _emit_bound_clamped(bnode, is_stop):
        if bnode is None:
            if is_stop:
                load_var_ref(src_name, scope, out)
                out.append(f'    {count_call}')
            else:
                out.append('    ldc.i4.0')
            return

        ctx['label_counter'][0] += 1
        cnt = ctx['label_counter'][0]
        lbl_neg_done = f"{ctx.get('prefix', 'expr')}_slc_neg_{cnt}"
        lbl_clamp_done = f"{ctx.get('prefix', 'expr')}_slc_clamp_{cnt}"

        compile_expr(bnode, scope, out, 'i32', ctx)
        out.append('    dup')
        out.append('    ldc.i4.0')
        out.append(f'    bge.s {lbl_neg_done}')
        load_var_ref(src_name, scope, out)
        out.append(f'    {count_call}')
        out.append('    add')
        out.append('    dup')
        out.append('    ldc.i4.0')
        out.append(f'    bge.s {lbl_neg_done}')
        out.append('    pop')
        out.append('    ldc.i4.0')
        out.append(f'  {lbl_neg_done}:')
        out.append('    dup')
        load_var_ref(src_name, scope, out)
        out.append(f'    {count_call}')
        out.append(f'    ble.s {lbl_clamp_done}')
        out.append('    pop')
        load_var_ref(src_name, scope, out)
        out.append(f'    {count_call}')
        out.append(f'  {lbl_clamp_done}:')

    _emit_bound_clamped(start_node, is_stop=False)
    out.append(f'    stloc.s {start_idx}')

    _emit_bound_clamped(stop_node, is_stop=True)
    out.append(f'    stloc.s {stop_idx}')

    ctx['label_counter'][0] += 1
    cnt_lbl = ctx['label_counter'][0]
    lbl_count_done = f"{ctx.get('prefix', 'expr')}_slc_cnt_{cnt_lbl}"

    out.append(f'    ldloc.s {stop_idx}')
    out.append(f'    ldloc.s {start_idx}')
    out.append('    sub')
    out.append('    dup')
    out.append('    ldc.i4.0')
    out.append(f'    bge.s {lbl_count_done}')
    out.append('    pop')
    out.append('    ldc.i4.0')
    out.append(f'  {lbl_count_done}:')
    out.append(f'    stloc.s {count_idx}')

    load_var_ref(src_name, scope, out)
    out.append(f'    ldloc.s {start_idx}')
    out.append(f'    ldloc.s {count_idx}')
    out.append(f'    {slice_call}')


def fpw_assign_list_slice(stmt, ctx):
    src_name = stmt['slice_node'][1]
    _, _, src_ta = ctx['infer_scope'][src_name]
    ta = ctx['TypeAnn'](src_ta.dtype, 'list')
    ctx['declare_named'](stmt['name'], ta)
    ctx['declare_named'](f'__slice{id(stmt["slice_node"])}_start', ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__slice{id(stmt["slice_node"])}_stop', ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__slice{id(stmt["slice_node"])}_count', ctx['TypeAnn']('i32', None))
    start_node, stop_node = stmt['slice_node'][2], stmt['slice_node'][3]
    if start_node is not None:
        ctx['collect_ternary_temps'](start_node)
    if stop_node is not None:
        ctx['collect_ternary_temps'](stop_node)


def codegen_assign_list_slice(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _, _, ta = scope[stmt['name']]
    ctx['compile_expr'](stmt['slice_node'], scope, body, ta.dtype, ctx)
    ctx['store_var'](stmt['name'], scope, body)


register_assign_rhs_parser('list_slice', try_rhs_list_slice)
register_expr_codegen('slice', compile_slice)
register_first_pass_walk('assign_list_slice', fpw_assign_list_slice)
register_stmt_codegen('assign_list_slice', codegen_assign_list_slice)

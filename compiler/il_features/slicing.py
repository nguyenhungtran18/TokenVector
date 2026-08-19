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

    THU TU STACK: tinh 'start' TRUOC, luu vao local AN (can dung 2 lan);
    nap nguon, nap start (lam tham so 1), tinh 'stop' (mac dinh =
    get_Count()/get_Length() cua nguon neu vang mat), nap lai start tu
    local, 'sub' de duoc count=stop-start - dung THU TU nay (KHONG phai
    'start-stop') vi IL 'sub' tinh (gia_tri_duoi - gia_tri_tren) tren 2
    phan tu DINH stack, da xac minh THAT qua ilasm.exe compile+run doi
    chieu ket qua voi Python that (xem STATUS.md)."""
    src_name, start_node, stop_node = node[1], node[2], node[3]
    _, _, src_ta = scope[src_name]
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']

    if src_ta.shape == 'list':
        list_type = ctx['il_type_str'](src_ta, (ctx or {}).get('records'))
        count_call = f'callvirt instance int32 {list_type}::get_Count()'
        # QUAN TRONG (giong get_Item's '!0'): return type cua GetRange()
        # duoc dinh nghia TREN generic type MO (List`1<!0>), KHONG phai
        # kieu da thay the (vd List`1<int32>) - metadata phai ghi dung
        # nhu vay, bug that phat hien qua ilasm.exe chay (MissingMethodException).
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

    def _emit_bound(bnode, default_is_count):
        # Chi so am HANG SO tai compile-time (vd -2) -> Count/Length - N,
        # giong emit_index_value cua il_core.py (chi so don, khong
        # slice) - xem gioi han o docstring dau file.
        if bnode is None:
            if default_is_count:
                load_var_ref(src_name, scope, out)
                out.append(f'    {count_call}')
            else:
                out.append('    ldc.i4.0')
            return
        n = ctx['neg_literal_int'](bnode)
        if n is not None:
            load_var_ref(src_name, scope, out)
            out.append(f'    {count_call}')
            out.append(f'    ldc.i4 {n}')
            out.append('    sub')
            return
        compile_expr(bnode, scope, out, 'i32', ctx)

    _emit_bound(start_node, default_is_count=False)
    out.append(f'    stloc.s {start_idx}')

    load_var_ref(src_name, scope, out)
    out.append(f'    ldloc.s {start_idx}')
    _emit_bound(stop_node, default_is_count=True)
    out.append(f'    ldloc.s {start_idx}')
    out.append('    sub')
    out.append(f'    {slice_call}')


def fpw_assign_list_slice(stmt, ctx):
    src_name = stmt['slice_node'][1]
    _, _, src_ta = ctx['infer_scope'][src_name]
    ta = ctx['TypeAnn'](src_ta.dtype, 'list')
    ctx['declare_named'](stmt['name'], ta)
    ctx['declare_named'](f'__slice{id(stmt["slice_node"])}_start', ctx['TypeAnn']('i32', None))
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

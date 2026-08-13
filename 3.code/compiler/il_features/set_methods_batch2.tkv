# -*- coding: utf-8 -*-
"""set.remove(x)/set.discard(x) + set.union/intersection/difference
(2026-07-29, Huong A stdlib mo rong - nhom rieng thu 8, mo rong tren
set_type.py da co san (chi co set()/.add()/'in') KHONG SUA file do, giong
tinh than list_methods_batch2/batch3, string_methods_batch2/batch3 -
nhom moi = file rieng.

Da xac minh truoc khi viet (PowerShell reflection tren
HashSet`1[int].GetMethods()): Remove(T) tra bool, UnionWith/IntersectWith/
ExceptWith(IEnumerable<T>) deu CO THAT.

remove()/discard() (2026-08-13, batch 5.5b muc cuoi): CA HAI cung goi
Remove(T) (tra bool). discard() BO QUA ket qua (hanh vi im lang giong
Python that). remove() KIEM TRA ket qua - neu False (phan tu khong co
trong set) nem KeyNotFoundException, khop voi 'except KeyError:' co san
trong DSL (xem _EXC_TYPE_MAP trong control_flow.py).

union/intersection/difference: tra ve 1 SET MOI (KHONG sua 2 set nguon) -
tao ban sao tu set thu 1 (HashSet<T>::.ctor(IEnumerable<T>), giong ky
thuat list_copy.py) ROI goi UnionWith/IntersectWith/ExceptWith voi set
thu 2 - CA 2 phai CUNG dtype phan tu.

TU 2026-08-03 (Giai doan 0.2 nhom 6): 3 method nay dang ky qua
register_expr_method nen chay duoc o MOI vi tri bieu thuc, KHONG con gioi
han "chi RHS truc tiep 1 phep gan"; duong ASSIGN_RHS_PARSERS/
FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN. Can 1 BIEN AN (co che nhom 3,
EXPR_METHOD_TEMPS) vi ban cu GHI THANG ket qua vao bien dich roi NAP LAI
de goi UnionWith - dang do khong the la 1 bieu thuc; nay ban sao nam
trong bien an, goi UnionWith tren no, roi 'ldloc' o cuoi de tra gia tri.
Kieu tra ve = DUNG kieu cua set thu 1 (ham phan giai, co che nhom 5)."""
import re

from il_dispatch import (
    register_line_parser, register_stmt_codegen, register_first_pass_walk,
    register_expr_method,
)
from il_features.set_type import il_set_type

_SET_REMOVE_RE = re.compile(r'^(\w+)\.remove\((.+)\)\s*$')
_SET_DISCARD_RE = re.compile(r'^(\w+)\.discard\((.+)\)\s*$')
_SET_COMBINE_METHOD = {
    'union': 'UnionWith',
    'intersection': 'IntersectWith',
    'difference': 'ExceptWith',
}


def _make_set_remove_parser(re_pattern, kind):
    """CHI khoi dong khi known_shapes DA XAC NHAN la 'set' (nguoc lai voi
    list.remove() o list_type.py - regex giong het nhau, phai loai tru
    lan nhau ca 2 chieu de tranh nuot nham cua nhau, xem ghi chu sua
    trong list_type.py's try_parse_list_remove cung ngay)."""
    from il_core import parse_expr

    def fn(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
        m = re_pattern.match(line)
        if not m or known_shapes.get(m.group(1)) not in ('set', 'frozenset'):
            return None
        name, arg_expr = m.groups()
        return {'kind': kind, 'name': name, 'value_node': parse_expr(arg_expr)}, pos + 1
    return fn


def _codegen_set_remove_like(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """set.discard(x): giu nguyen hanh vi cu (Remove(T) roi pop, khong
    kiem tra ket qua). set.remove(x) (batch 5.5b, muc cuoi, 2026-08-13):
    kiem tra bool tra ve tu Remove(T) - neu False (phan tu KHONG co
    trong set), nem KeyNotFoundException (gan nghia nhat voi KeyError
    cua Python - .NET khong co exception ten 'KeyError'). Khong tu viet
    message chua gia tri thieu - chap nhan sai khac nho ve loai/noi dung
    exception, giong tien le sample()/RFind da chap nhan truoc do."""
    _, _, ta = scope[stmt['name']]
    if ta.shape == 'frozenset':
        method = 'remove' if stmt['kind'] == 'set_remove' else 'discard'
        raise SyntaxError(
            f"il_codegen: '{stmt['name']}' la frozenset (bat bien) - khong the .{method}()")
    ctx['load_var_ref'](stmt['name'], scope, body)
    ctx['compile_expr'](stmt['value_node'], scope, body, ta.dtype, ctx)
    body.append(f'    callvirt instance bool {il_set_type(ta.dtype, ctx.get("records"))}::Remove(!0)')
    if stmt['kind'] == 'set_discard':
        body.append('    pop')
    else:
        ctx['label_counter'][0] += 1
        n = ctx['label_counter'][0]
        ok_lbl = f"{ctx['prefix']}_setrm{n}_ok"
        body.append(f'    brtrue {ok_lbl}')
        body.append('    newobj instance void [mscorlib]System.Collections.Generic.KeyNotFoundException::.ctor()')
        body.append('    throw')
        body.append(f'  {ok_lbl}:')


def _fpw_set_remove_like(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['value_node'])


def _temps_set_combine(node, ctx):
    """FIRST PASS: 1 bien AN giu SET KET QUA (ban sao cua set thu 1), khoa
    = id(node) - xem stdlib_string_count.py cho quy uoc khoa."""
    try:
        _, _, a_ta = ctx['infer_scope'][node[1]]
    except KeyError:
        return
    ctx['declare_named'](f'__setcomb{id(node)}_res', a_ta)


def _compile_set_combine(node, scope, out, dtype, ctx, op):
    a_name, args = node[1], node[3]
    if len(args) != 1 or args[0][0] != 'var':
        raise SyntaxError(
            f"il_codegen: set.{op}() can DUNG 1 tham so la 1 BIEN set (vd "
            f"'a.{op}(b)') - bieu thuc long nhau chua ho tro")
    b_name = args[0][1]
    _, _, a_ta = scope[a_name]
    _, _, b_ta = scope[b_name]
    if b_ta.shape != 'set' or b_ta.dtype != a_ta.dtype:
        raise SyntaxError(
            f"il_codegen: '{a_name}.{op}({b_name})' can '{b_name}' la set cung "
            f"dtype ({a_ta.dtype!r})")
    _, res_idx, _ = scope[f'__setcomb{id(node)}_res']
    set_type = il_set_type(a_ta.dtype, ctx.get('records'))

    # res = new HashSet<T>(a)  (ban sao - KHONG sua 2 set nguon)
    ctx['load_var_ref'](a_name, scope, out)
    out.append(
        f'    newobj instance void {set_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    stloc.s {res_idx}')
    # res.UnionWith(b) / IntersectWith / ExceptWith
    out.append(f'    ldloc.s {res_idx}')
    ctx['load_var_ref'](b_name, scope, out)
    out.append(
        f'    callvirt instance void {set_type}::{_SET_COMBINE_METHOD[op]}(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    ldloc.s {res_idx}')


register_line_parser('set_remove', _make_set_remove_parser(_SET_REMOVE_RE, 'set_remove'))
register_line_parser('set_discard', _make_set_remove_parser(_SET_DISCARD_RE, 'set_discard'))
register_stmt_codegen('set_remove', _codegen_set_remove_like)
register_stmt_codegen('set_discard', _codegen_set_remove_like)
register_first_pass_walk('set_remove', _fpw_set_remove_like)
register_first_pass_walk('set_discard', _fpw_set_remove_like)

for _op in _SET_COMBINE_METHOD:
    register_expr_method(
        'set', _op,
        (lambda op: lambda node, scope, out, dtype, ctx:
            _compile_set_combine(node, scope, out, dtype, ctx, op))(_op),
        temps_fn=_temps_set_combine,
        # Kieu tra ve = DUNG kieu cua set thu 1 (co che nhom 5).
        return_ta_fn=lambda a_ta: a_ta,
        result_shape='set')

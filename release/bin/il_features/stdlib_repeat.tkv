# -*- coding: utf-8 -*-
"""List/string repeat ('lst * n', Python that; 'repeat_str(s, n)' cho
string vi ly do duoi day) - Wave 3 quick-win cuoi cung (2026-07-29),
hoan tat nhom A con thieu (list/string multiplication).

'lst * n' (list): dung ASSIGN_RHS_PARSERS, GATE BAT BUOC qua
known_shapes.get(name)=='list' (giong het list.count()) - KHONG the
dung regex '^(\\w+)\\s*\\*\\s*(.+)$' don thuan vi se khop CA phep nhan
so hoc binh thuong 'x = a * b' (RAT PHO BIEN) - known_shapes CHI danh
dau ten da khai bao 'lst = []', bien so/scalar KHONG BAO GIO xuat hien
trong known_shapes nen gate nay AN TOAN, khong bao gio nham voi nhan so
hoc thuong.

'repeat_str(s, n)' (string): KHONG dung duoc cu phap 's * n' voi CUNG
ly do - string la scalar (assign_scalar chung, KHONG co known_shapes
danh dau nhu list) nen KHONG THE gate an toan qua parse-time regex (se
nham voi nhan so hoc) - dung 1 ham FLAT rieng, ten khong trung, an
toan 100% (giong json_dumps/list.count, khong the long trong bieu
thuc khac, CHI RHS truc tiep 1 phep gan don)."""
import re

from il_core import parse_expr
from il_dispatch import register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen
from il_features.list_type import il_list_type

_LIST_REPEAT_RE = re.compile(r'^(\w+)\s*\*\s*(.+)$')
_REPEAT_STR_RE = re.compile(r'^repeat_str\((\w+),\s*(.+)\)$')


def try_rhs_list_repeat(rhs, name, known_shapes):
    m = _LIST_REPEAT_RE.match(rhs.strip())
    if not m or known_shapes.get(m.group(1)) != 'list':
        return None
    known_shapes[name] = 'list'
    return {'kind': 'assign_list_repeat', 'name': name, 'list_name': m.group(1),
            'count_node': parse_expr(m.group(2))}


def try_rhs_repeat_str(rhs, name, known_shapes):
    m = _REPEAT_STR_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_repeat_str', 'name': name, 'str_name': m.group(1),
            'count_node': parse_expr(m.group(2))}


def fpw_assign_list_repeat(stmt, ctx):
    _, _, list_ta = ctx['infer_scope'][stmt['list_name']]
    ctx['declare_named'](stmt['name'], list_ta)
    ctx['declare_named'](f'__rep{id(stmt)}_idx', ctx['TypeAnn']('i32', None))
    ctx['collect_ternary_temps'](stmt['count_node'])


def fpw_assign_repeat_str(stmt, ctx):
    _, _, str_ta = ctx['infer_scope'][stmt['str_name']]
    if str_ta.dtype != 'str' or str_ta.shape is not None:
        raise SyntaxError(f"il_codegen: repeat_str(...) can '{stmt['str_name']}' la string")
    ctx['declare_named'](stmt['name'], ctx['TypeAnn']('str', None))
    ctx['declare_named'](f'__rep{id(stmt)}_idx', ctx['TypeAnn']('i32', None))
    ctx['collect_ternary_temps'](stmt['count_node'])


def codegen_assign_list_repeat(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    list_ta = scope[stmt['list_name']][2]
    list_type = ctx['il_type_str'](list_ta, ctx.get('records'))
    load_var_ref, store_var, compile_expr = ctx['load_var_ref'], ctx['store_var'], ctx['compile_expr']
    _, idx_idx, _ = scope[f'__rep{id(stmt)}_idx']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_rep{n}_start"
    end_lbl = f"{ctx['prefix']}_rep{n}_end"

    body.append(f'    newobj instance void {list_type}::.ctor()')
    store_var(stmt['name'], scope, body)
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {idx_idx}')

    body.append(f'  {start_lbl}:')
    body.append(f'    ldloc.s {idx_idx}')
    compile_expr(stmt['count_node'], scope, body, 'i32', ctx)
    body.append(f'    bge {end_lbl}')
    load_var_ref(stmt['name'], scope, body)
    load_var_ref(stmt['list_name'], scope, body)
    body.append(
        f'    callvirt instance void {list_type}::AddRange(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'    br {start_lbl}')
    body.append(f'  {end_lbl}:')


def codegen_assign_repeat_str(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    load_var_ref, store_var, compile_expr = ctx['load_var_ref'], ctx['store_var'], ctx['compile_expr']
    _, idx_idx, _ = scope[f'__rep{id(stmt)}_idx']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_reps{n}_start"
    end_lbl = f"{ctx['prefix']}_reps{n}_end"

    body.append('    ldstr ""')
    store_var(stmt['name'], scope, body)
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {idx_idx}')

    body.append(f'  {start_lbl}:')
    body.append(f'    ldloc.s {idx_idx}')
    compile_expr(stmt['count_node'], scope, body, 'i32', ctx)
    body.append(f'    bge {end_lbl}')
    load_var_ref(stmt['name'], scope, body)
    load_var_ref(stmt['str_name'], scope, body)
    body.append('    call string [mscorlib]System.String::Concat(string, string)')
    store_var(stmt['name'], scope, body)
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'    br {start_lbl}')
    body.append(f'  {end_lbl}:')


register_assign_rhs_parser('list_repeat', try_rhs_list_repeat)
register_assign_rhs_parser('repeat_str', try_rhs_repeat_str)
register_first_pass_walk('assign_list_repeat', fpw_assign_list_repeat)
register_first_pass_walk('assign_repeat_str', fpw_assign_repeat_str)
register_stmt_codegen('assign_list_repeat', codegen_assign_list_repeat)
register_stmt_codegen('assign_repeat_str', codegen_assign_repeat_str)

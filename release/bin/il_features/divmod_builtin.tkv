# -*- coding: utf-8 -*-
"""divmod(a, b) -> (i32,i32)/(i64,i64) tuy dtype cua 'a' (batch 5.5b muc
cuoi, 2026-08-13). Viet lai logic floor-adjust cua operators.py's
_emit_int_floor_div_or_mod (DA CHUNG MINH DUNG qua toan tu '//'/'%') -
KHONG tai dung truc tiep duoc vi divmod la node 'call' (khong phai
'binop'), nen khong di qua co che _walk_intdiv_nodes/'__idiv{id(node)}'
(khoa theo id() cua node 'binop'). Dung temps_fn= (giong path_splitext/
sample) thay the.

GIOI HAN DA BIET: chi ho tro i32/i64 (f32/f64 bao loi ro rang - Python
divmod() tren so thuc dung ngu nghia khac, ngoai pham vi). Tham so DAU
phai la 1 BIEN don da khai bao (giong sample/choice/shuffle) - dtype suy
THANG tu do. b=0 de CIL tu nem DivideByZeroException (khong tu viet
message rieng, chap nhan khac ZeroDivisionError cua Python that)."""
from typed_dsl_parser import TypeAnn
from il_features.tuple_type import il_tupleN_type
from il_dispatch import register_expr_builtin

_SUPPORTED_DTYPES = ('i32', 'i64')


def _divmod_dtype(args, scope):
    """Suy dtype cua divmod(a,b) tu bien 'a' - tra None neu khong suy
    duoc (khong phai loi NGAY, de caller tu quyet dinh raise ro rang)."""
    if len(args) != 2 or args[0][0] != 'var':
        return None
    try:
        return scope[args[0][1]][2].dtype
    except KeyError:
        return None


def _divmod_return_ta_fn(args, scope):
    d = _divmod_dtype(args, scope)
    if d is None or d not in _SUPPORTED_DTYPES:
        return None
    return TypeAnn(d, 'tuple', tuple_dtypes=[d, d])


def _divmod_temps(node, ctx):
    args = node[2]
    if len(args) != 2:
        return
    d = _divmod_dtype(args, ctx['infer_scope']) or 'i32'
    TypeAnn_ = ctx['TypeAnn']
    for suf in ('a', 'b', 'q', 'r'):
        ctx['declare_named'](f'__dm{id(args)}_{suf}', TypeAnn_(d, None))


def compile_divmod(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: divmod(a, b) chi nhan dung 2 tham so")
    d = _divmod_dtype(args, scope)
    if d is None:
        raise SyntaxError(
            "il_codegen: divmod(a, b) - 'a' phai la 1 BIEN da khai bao kieu "
            "i32/i64 (dtype suy tu 'a')")
    if d not in _SUPPORTED_DTYPES:
        raise SyntaxError(
            f"il_codegen: divmod(a, b) chi ho tro i32/i64, khong ho tro '{d}'")
    compile_expr = ctx['compile_expr']
    a_idx = scope[f'__dm{id(args)}_a'][1]
    b_idx = scope[f'__dm{id(args)}_b'][1]
    q_idx = scope[f'__dm{id(args)}_q'][1]
    r_idx = scope[f'__dm{id(args)}_r'][1]

    zero = '    ldc.i4.0' if d == 'i32' else '    ldc.i8 0'
    one = '    ldc.i4.1' if d == 'i32' else '    ldc.i8 1'

    compile_expr(args[0], scope, out, d, ctx)
    out.append(f'    stloc.s {a_idx}')
    compile_expr(args[1], scope, out, d, ctx)
    out.append(f'    stloc.s {b_idx}')
    out.append(f'    ldloc.s {a_idx}')
    out.append(f'    ldloc.s {b_idx}')
    out.append('    div')
    out.append(f'    stloc.s {q_idx}')
    out.append(f'    ldloc.s {a_idx}')
    out.append(f'    ldloc.s {b_idx}')
    out.append('    rem')
    out.append(f'    stloc.s {r_idx}')

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx.get('prefix', 'dm')
    done_lbl = f'{prefix}_dm{n}_done'

    out.append(f'    ldloc.s {r_idx}')
    out.append(zero)
    out.append(f'    beq {done_lbl}')
    out.append(f'    ldloc.s {a_idx}')
    out.append(f'    ldloc.s {b_idx}')
    out.append('    xor')
    out.append(zero)
    out.append(f'    bge {done_lbl}')
    out.append(f'    ldloc.s {q_idx}')
    out.append(one)
    out.append('    sub')
    out.append(f'    stloc.s {q_idx}')
    out.append(f'    ldloc.s {r_idx}')
    out.append(f'    ldloc.s {b_idx}')
    out.append('    add')
    out.append(f'    stloc.s {r_idx}')
    out.append(f'  {done_lbl}:')

    out.append(f'    ldloc.s {q_idx}')
    out.append(f'    ldloc.s {r_idx}')
    tuple_type = il_tupleN_type([d, d])
    out.append(f'    newobj instance void {tuple_type}::.ctor(!0, !1)')


register_expr_builtin('divmod', compile_divmod, None,
                       temps_fn=_divmod_temps,
                       return_ta_fn=_divmod_return_ta_fn)

# -*- coding: utf-8 -*-
"""enumerate(x)/zip(a, b) o VI TRI BIEU THUC doc lap (Phase 5.3, 2026-08-12)
- khac ban macro CHI-trong-for-header o stdlib_itertools.py (dang ky
rieng, khong xung dot - macro do van chay TRUOC, tren VAN BAN dong, chi
khop dung dang 'for i, x in enumerate(lst):'; hai ham nay chi kich hoat
khi 'enumerate(...)'/'zip(...)' xuat hien o VI TRI BIEU THUC that, vd
'res: "list[(i32,str)]" = enumerate(xs)').

Gioi han co y thuc (giong most_common(c,n) o counter_type.py - tien le
DUY NHAT co san cho 'list cua tuple' o vi tri bieu thuc): BAT BUOC khai
bao kieu tuong minh 'ten: "list[(K,V)]" = enumerate(xs)/zip(a,b)' (xem
il_codegen.py's _lp_typed_local_decl) - khong suy dtype tu ve phai duoc
(can biet dtype PHAN TU cua list nguon, tuong tu ly do return_dtype_fn
cua most_common tra ve None). Phan tu CHI vo huong (khong long nhau
list/dict khac trong tuple, giong han che chung cua tuple_type.py).
zip() CHI 2-ary (khac ban macro N-ary trong for-header) - gioi han rieng
chu y thuc de giu don gian, dung lai dung 1 model min(len(a),len(b))
qua ternary da co san."""
from il_features.list_type import il_list_type
from il_features.tuple_type import il_tupleN_type
from il_dispatch import register_expr_builtin


_SAFE_ELEM_DTYPES = frozenset({'i32', 'i64', 'f32', 'f64', 'str'})


def _elem_ta_of(name, infer_scope):
    _, _, ta = infer_scope[name]
    if ta.shape != 'list' or ta.elem_ta is not None:
        raise SyntaxError(
            f"il_codegen: '{name}' phai la 1 list PHAN TU VO HUONG (list[dtype]) - "
            f"khong ho tro list long nhau lam nguon cho enumerate()/zip()")
    if ta.dtype not in _SAFE_ELEM_DTYPES:
        # 'int' (so nguyen vo han chu so, struct TkvInt) BI CHAN o day co
        # y thuc (Phase 5.3, 2026-08-12): field cua ValueTuple sinh boi
        # enumerate()/zip() PHAI khop CHINH XAC layout IL voi kieu bien
        # dich khai bao tuong minh o ben goi ('pairs: "list[(i32,str)]"')
        # - list mac dinh KHONG annotation ('xs = [1,2,3]') suy dtype la
        # 'int' (TkvInt struct) theo quy uoc rieng, khac 'i32' (int32
        # tho) - tron 2 kieu nay gay type-confusion THAT trong IL sinh ra
        # (da xac nhan bang thu nghiem, khong chi ly thuyet). Yeu cau
        # nguon phai la list kieu co dinh (vd tham so ham 'xs: "list[i32]"')
        # thay vi list literal khong annotation.
        raise SyntaxError(
            f"il_codegen: enumerate()/zip() o vi tri bieu thuc chi ho tro list nguon kieu co dinh "
            f"{sorted(_SAFE_ELEM_DTYPES)} - '{name}' co dtype '{ta.dtype}' (vd list literal khong "
            f"annotation mac dinh suy 'int' vo han chu so, khong khop layout IL voi tuple ket qua) - "
            f"khai bao '{name}' qua 1 tham so ham kieu 'list[i32]'/... thay vao do")
    return ta.dtype


def _temps_enumerate(node, ctx):
    args = node[2]
    if len(args) != 1 or args[0][0] != 'var':
        return
    infer_scope = ctx['infer_scope']
    try:
        elem_dtype = _elem_ta_of(args[0][1], infer_scope)
    except KeyError:
        return
    TypeAnn = ctx['TypeAnn']
    key = id(args)
    ctx['declare_named'](f'__enum{key}_i', TypeAnn('i32', None))
    ctx['declare_named'](f'__enum{key}_res', TypeAnn('i32', 'list',
                          elem_ta=TypeAnn(elem_dtype, 'tuple', tuple_dtypes=['i32', elem_dtype])))


def push_enumerate(args, scope, out, dtype, ctx):
    if len(args) != 1 or args[0][0] != 'var':
        raise SyntaxError("il_codegen: enumerate(x) o vi tri bieu thuc chi nhan DUNG 1 BIEN list")
    x_name = args[0][1]
    _, _, x_ta = scope[x_name]
    if x_ta.shape != 'list' or x_ta.elem_ta is not None:
        raise SyntaxError(f"il_codegen: enumerate({x_name}) - '{x_name}' phai la list phan tu vo huong")
    _elem_ta_of(x_name, scope)
    key = id(args)
    _, i_idx, _ = scope[f'__enum{key}_i']
    _, res_idx, res_ta = scope[f'__enum{key}_res']

    x_list_type = il_list_type(x_ta.dtype, ctx.get('records'))
    tuple_type = il_tupleN_type(['i32', x_ta.dtype])
    res_list_type = f'class [mscorlib]System.Collections.Generic.List`1<{tuple_type}>'

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    loop_start = f"{ctx['prefix']}_enum{n}_start"
    loop_end = f"{ctx['prefix']}_enum{n}_end"

    out.append(f'    newobj instance void {res_list_type}::.ctor()')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'  {loop_start}:')
    out.append(f'    ldloc.s {i_idx}')
    ctx['load_var_ref'](x_name, scope, out)
    out.append(f'    callvirt instance int32 {x_list_type}::get_Count()')
    out.append(f'    bge {loop_end}')
    out.append(f'    ldloc.s {res_idx}')
    out.append(f'    ldloc.s {i_idx}')
    ctx['load_var_ref'](x_name, scope, out)
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {x_list_type}::get_Item(int32)')
    out.append(f'    newobj instance void {tuple_type}::.ctor(!0, !1)')
    out.append(f'    callvirt instance void {res_list_type}::Add(!0)')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {loop_start}')
    out.append(f'  {loop_end}:')
    out.append(f'    ldloc.s {res_idx}')


def _temps_zip(node, ctx):
    args = node[2]
    if len(args) != 2 or args[0][0] != 'var' or args[1][0] != 'var':
        return
    infer_scope = ctx['infer_scope']
    try:
        a_dtype = _elem_ta_of(args[0][1], infer_scope)
        b_dtype = _elem_ta_of(args[1][1], infer_scope)
    except KeyError:
        return
    TypeAnn = ctx['TypeAnn']
    key = id(args)
    ctx['declare_named'](f'__zip{key}_i', TypeAnn('i32', None))
    ctx['declare_named'](f'__zip{key}_bound', TypeAnn('i32', None))
    ctx['declare_named'](f'__zip{key}_res', TypeAnn(a_dtype, 'list',
                          elem_ta=TypeAnn(b_dtype, 'tuple', tuple_dtypes=[a_dtype, b_dtype])))


def push_zip(args, scope, out, dtype, ctx):
    if len(args) != 2 or args[0][0] != 'var' or args[1][0] != 'var':
        raise SyntaxError("il_codegen: zip(a, b) o vi tri bieu thuc chi nhan DUNG 2 BIEN list")
    a_name, b_name = args[0][1], args[1][1]
    _, _, a_ta = scope[a_name]
    _, _, b_ta = scope[b_name]
    if a_ta.shape != 'list' or a_ta.elem_ta is not None or \
            b_ta.shape != 'list' or b_ta.elem_ta is not None:
        raise SyntaxError(f"il_codegen: zip({a_name}, {b_name}) - ca 2 phai la list phan tu vo huong")
    _elem_ta_of(a_name, scope)
    _elem_ta_of(b_name, scope)
    key = id(args)
    _, i_idx, _ = scope[f'__zip{key}_i']
    _, bound_idx, _ = scope[f'__zip{key}_bound']
    _, res_idx, _ = scope[f'__zip{key}_res']

    a_list_type = il_list_type(a_ta.dtype, ctx.get('records'))
    b_list_type = il_list_type(b_ta.dtype, ctx.get('records'))
    tuple_type = il_tupleN_type([a_ta.dtype, b_ta.dtype])
    res_list_type = f'class [mscorlib]System.Collections.Generic.List`1<{tuple_type}>'

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    loop_start = f"{ctx['prefix']}_zip{n}_start"
    loop_end = f"{ctx['prefix']}_zip{n}_end"
    a_le_b = f"{ctx['prefix']}_zip{n}_a_le_b"
    bound_done = f"{ctx['prefix']}_zip{n}_bound_done"

    # bound = min(len(a), len(b)).
    ctx['load_var_ref'](a_name, scope, out)
    out.append(f'    callvirt instance int32 {a_list_type}::get_Count()')
    ctx['load_var_ref'](b_name, scope, out)
    out.append(f'    callvirt instance int32 {b_list_type}::get_Count()')
    out.append(f'    bgt {a_le_b}')
    ctx['load_var_ref'](a_name, scope, out)
    out.append(f'    callvirt instance int32 {a_list_type}::get_Count()')
    out.append(f'    br {bound_done}')
    out.append(f'  {a_le_b}:')
    ctx['load_var_ref'](b_name, scope, out)
    out.append(f'    callvirt instance int32 {b_list_type}::get_Count()')
    out.append(f'  {bound_done}:')
    out.append(f'    stloc.s {bound_idx}')

    out.append(f'    newobj instance void {res_list_type}::.ctor()')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'  {loop_start}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {bound_idx}')
    out.append(f'    bge {loop_end}')
    out.append(f'    ldloc.s {res_idx}')
    ctx['load_var_ref'](a_name, scope, out)
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {a_list_type}::get_Item(int32)')
    ctx['load_var_ref'](b_name, scope, out)
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {b_list_type}::get_Item(int32)')
    out.append(f'    newobj instance void {tuple_type}::.ctor(!0, !1)')
    out.append(f'    callvirt instance void {res_list_type}::Add(!0)')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {loop_start}')
    out.append(f'  {loop_end}:')
    out.append(f'    ldloc.s {res_idx}')


register_expr_builtin('enumerate', push_enumerate, None, return_shape='list', temps_fn=_temps_enumerate)
register_expr_builtin('zip', push_zip, None, return_shape='list', temps_fn=_temps_zip)

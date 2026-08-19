# -*- coding: utf-8 -*-
"""map()/filter()/functools-style reduce() (Phase 3.3, 2026-08-11) - dung
tren ha tang "first-class function value" moi (bien kieu 'func' khai bao
tuong minh qua 'g: "func(...)->..." = lambda ...'/'= ten_ham', xem
_lp_typed_local_decl/_compile_funcref_arg trong il_codegen.py).

Pham vi CO Y THUC thu hep (giong nguyen tac da dung cho random/re/format o
phien truoc): tham so ham 'f' CHI nhan TEN 1 ham top-level HOAC 1 bien da
khai bao kieu 'func' - KHONG nhan lambda truc tiep tai cho, vi lambda tu
than KHONG mang kieu (kieu tham so/tra ve cua no CHI suy duoc tu 1 TypeAnn
'muc tieu' da biet truoc, xem docstring _compile_lambda_funcref) va o day
KHONG co 1 'func(...)->...' nao duoc khai bao san de lam muc tieu do - nguoi
dung PHAI gan lambda vao 1 bien co kieu truoc ('g: "func(i32)->i32" =
lambda x: x*2' roi 'map(g, xs)'), dung y het tinh than "immediate-use" cu
cua Wave 3 nhung ap dung o 1 lop khac. Tham so 'lst' CHI nhan 1 BIEN list
don (khong bieu thuc long nhau) - giong het gioi han cua sum/min/max/sorted
(_agg_arg_ta trong stdlib_aggregates.py), cung 1 ly do (doc TypeAnn tu
scope can 1 TEN, khong phai 1 gia tri tam)."""

from il_dispatch import register_expr_builtin
from il_features.list_type import il_list_type


def _resolve_func_ta(f_node, scope, func_table, fname):
    """Tra TypeAnn(shape='func') day du cua tham so ham 'f' - CHI nhan 1
    TEN (bien kieu 'func' da khai bao HOAC 1 ham top-level trong
    func_table). 'scope' o day co the la infer_scope (first-pass) hoac
    _Scope (codegen) - ca hai deu tra (kind, idx, TypeAnn) khi tra theo
    ten (xem _agg_arg_ta's ghi chu tuong tu)."""
    if f_node[0] != 'var':
        raise SyntaxError(
            f"il_codegen: {fname}() tham so ham 'f' CHI nhan TEN 1 bien kieu 'func' da "
            f"khai bao (vd 'g: \"func(i32)->i32\" = lambda x: x*2' roi '{fname}(g, xs)') "
            f"hoac TEN 1 ham top-level trong chuong trinh - KHONG nhan lambda truc tiep "
            f"tai cho (lambda tu than khong mang kieu) cung khong nhan bieu thuc khac")
    name = f_node[1]
    # BUG THAT sua 2026-08-12 (phat hien qua 'lst.sort(key=<ten ham
    # top-level TRUC TIEP>)' - truoc day CHUA co noi goi nao dung nhanh
    # "ten ham top-level" nay qua _Scope THAT (codegen pass 2), chi qua
    # infer_scope (first-pass) - 2 scope nay KHAC nhau khi tra 1 ten
    # KHONG ton tai: infer_scope (_DtypeOnlyScope) nem KeyError (bat duoc
    # o day), con _Scope THAT nem SyntaxError (KHONG bat duoc truoc day,
    # crash thang thay vi roi xuong nhanh func_table ben duoi). Bat CA
    # HAI loai loi (khong dung 'in' - _DtypeOnlyScope khong co
    # __contains__, se rơi vao __getitem__ fallback nem KeyError khong
    # kiem soat).
    try:
        ta = scope[name][2]
    except (KeyError, SyntaxError):
        ta = None
    if ta is not None:
        if ta.shape != 'func':
            raise SyntaxError(
                f"il_codegen: {fname}({name}, ...) - '{name}' khong phai bien kieu 'func' "
                f"(dang co shape={ta.shape!r})")
        return ta
    if name in func_table:
        callee = func_table[name]
        if callee.return_type is None:
            raise SyntaxError(
                f"il_codegen: {fname}({name}, ...) - ham '{name}' khong co return type "
                f"(ham void), khong the dung lam tham so ham")
        return type(callee.return_type)(
            callee.return_type.dtype, 'func',
            func_params=[p.type_ann.dtype for p in callee.params])
    raise SyntaxError(
        f"il_codegen: {fname}({name}, ...) - '{name}' khong phai bien kieu 'func' da khai "
        f"bao, cung khong phai 1 ham da dinh nghia trong chuong trinh")


def _list_arg_ta(arg_node, scope, fname, argpos):
    if arg_node[0] != 'var':
        raise SyntaxError(
            f"il_codegen: {fname}() tham so {argpos} can DUNG 1 BIEN list (bieu thuc long "
            f"nhau chua ho tro, gan ra 1 bien truoc)")
    name = arg_node[1]
    try:
        ta = scope[name][2]
    except KeyError:
        raise SyntaxError(f"il_codegen: {fname}(...) - '{name}' chua duoc khai bao")
    if ta.shape != 'list':
        raise SyntaxError(
            f"il_codegen: {fname}(...) - '{name}' can la list (dang co shape={ta.shape!r})")
    return name, ta


# ---------------------------------------------------------------------
# map(f, xs) -> list[f.dtype]
# ---------------------------------------------------------------------

def _map_result_dtype(args, scope):
    # EXPR_BUILTIN_DTYPE_FN chi nhan (args, scope) - KHONG co func_table
    # (xem _infer_dtype/_expr_call trong il_codegen.py, cung gioi han nhu
    # _agg_elem_dtype). Vi vay o day CHI giai quyet duoc 'f' dang la 1 bien
    # kieu 'func' DA CO SAN trong scope - 'f' la TEN 1 ham top-level (khong
    # nam trong scope) se tra None (best-effort, giong cac nhanh suy dtype
    # khac trong codebase khi thieu 1 phan ngu canh) - KHONG anh huong toi
    # push_map (codegen that su, co ctx day du gom ca func_table).
    if len(args) != 2:
        return None
    try:
        f_ta = _resolve_func_ta(args[0], scope, {}, 'map')
        _, lst_ta = _list_arg_ta(args[1], scope, 'map', 2)
    except SyntaxError:
        return None
    if list(f_ta.func_params) != [lst_ta.dtype]:
        return None
    return f_ta.dtype


def _temps_map(node, ctx):
    args = node[2]
    if len(args) != 2:
        return
    infer_scope = ctx['infer_scope']
    func_table = ctx['func_table']
    try:
        f_ta = _resolve_func_ta(args[0], infer_scope, func_table, 'map')
        _, lst_ta = _list_arg_ta(args[1], infer_scope, 'map', 2)
    except SyntaxError:
        return
    if list(f_ta.func_params) != [lst_ta.dtype]:
        return
    TypeAnn = ctx['TypeAnn']
    key = id(args)
    ctx['declare_named'](f'__map{key}_f', f_ta)
    ctx['declare_named'](f'__map{key}_src', TypeAnn(lst_ta.dtype, 'list'))
    ctx['declare_named'](f'__map{key}_idx', TypeAnn('i32', None))
    ctx['declare_named'](f'__map{key}_res', TypeAnn(f_ta.dtype, 'list'))


def push_map(args, scope, out, dtype, ctx):
    f_node, lst_node = args
    f_ta = _resolve_func_ta(f_node, scope, ctx['func_table'], 'map')
    lst_name, lst_ta = _list_arg_ta(lst_node, scope, 'map', 2)
    if list(f_ta.func_params) != [lst_ta.dtype]:
        raise SyntaxError(
            f"il_codegen: map(f, {lst_name}) - chu ky 'f' (({', '.join(f_ta.func_params)}) "
            f"-> {f_ta.dtype}) khong khop dtype phan tu cua '{lst_name}' ({lst_ta.dtype!r})")
    key = id(args)
    _, f_idx, _ = scope[f'__map{key}_f']
    _, src_idx, _ = scope[f'__map{key}_src']
    _, idx_idx, _ = scope[f'__map{key}_idx']
    _, res_idx, _ = scope[f'__map{key}_res']
    src_list_type = il_list_type(lst_ta.dtype, ctx.get('records'))
    res_list_type = il_list_type(f_ta.dtype, ctx.get('records'))
    func_il = ctx['il_type_str'](f_ta, ctx.get('records'))
    ctx['compile_funcref_arg'](f_node, f_ta, scope, out, ctx)
    out.append(f'    stloc.s {f_idx}')
    ctx['load_var_ref'](lst_name, scope, out)
    out.append(f'    stloc.s {src_idx}')
    out.append(f'    newobj instance void {res_list_type}::.ctor()')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_map{n}_start"
    end_lbl = f"{ctx['prefix']}_map{n}_end"
    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    callvirt instance int32 {src_list_type}::get_Count()')
    out.append(f'    bge {end_lbl}')
    out.append(f'    ldloc.s {res_idx}')
    out.append(f'    ldloc.s {f_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {src_list_type}::get_Item(int32)')
    n_params = len(f_ta.func_params)
    invoke_params = ', '.join(f'!{i}' for i in range(n_params))
    out.append(f'    callvirt instance !{n_params} {func_il}::Invoke({invoke_params})')
    out.append(f'    callvirt instance void {res_list_type}::Add(!0)')
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {res_idx}')


# ---------------------------------------------------------------------
# filter(f, xs) -> list[xs.dtype] (f tra 'i32' lam gia tri bool 0/1)
# ---------------------------------------------------------------------

def _temps_filter(node, ctx):
    args = node[2]
    if len(args) != 2:
        return
    infer_scope = ctx['infer_scope']
    func_table = ctx['func_table']
    try:
        f_ta = _resolve_func_ta(args[0], infer_scope, func_table, 'filter')
        _, lst_ta = _list_arg_ta(args[1], infer_scope, 'filter', 2)
    except SyntaxError:
        return
    if list(f_ta.func_params) != [lst_ta.dtype]:
        return
    TypeAnn = ctx['TypeAnn']
    key = id(args)
    ctx['declare_named'](f'__filter{key}_f', f_ta)
    ctx['declare_named'](f'__filter{key}_src', TypeAnn(lst_ta.dtype, 'list'))
    ctx['declare_named'](f'__filter{key}_idx', TypeAnn('i32', None))
    ctx['declare_named'](f'__filter{key}_res', TypeAnn(lst_ta.dtype, 'list'))


def push_filter(args, scope, out, dtype, ctx):
    f_node, lst_node = args
    f_ta = _resolve_func_ta(f_node, scope, ctx['func_table'], 'filter')
    lst_name, lst_ta = _list_arg_ta(lst_node, scope, 'filter', 2)
    if list(f_ta.func_params) != [lst_ta.dtype]:
        raise SyntaxError(
            f"il_codegen: filter(f, {lst_name}) - chu ky 'f' (({', '.join(f_ta.func_params)}) "
            f"-> {f_ta.dtype}) khong khop dtype phan tu cua '{lst_name}' ({lst_ta.dtype!r})")
    if f_ta.dtype != 'i32':
        raise SyntaxError(
            f"il_codegen: filter(f, ...) - 'f' phai tra ve 'i32' (dung lam gia tri bool "
            f"0/1), dang tra ve {f_ta.dtype!r}")
    key = id(args)
    _, f_idx, _ = scope[f'__filter{key}_f']
    _, src_idx, _ = scope[f'__filter{key}_src']
    _, idx_idx, _ = scope[f'__filter{key}_idx']
    _, res_idx, _ = scope[f'__filter{key}_res']
    list_type = il_list_type(lst_ta.dtype, ctx.get('records'))
    func_il = ctx['il_type_str'](f_ta, ctx.get('records'))
    ctx['compile_funcref_arg'](f_node, f_ta, scope, out, ctx)
    out.append(f'    stloc.s {f_idx}')
    ctx['load_var_ref'](lst_name, scope, out)
    out.append(f'    stloc.s {src_idx}')
    out.append(f'    newobj instance void {list_type}::.ctor()')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_filter{n}_start"
    skip_lbl = f"{ctx['prefix']}_filter{n}_skip"
    end_lbl = f"{ctx['prefix']}_filter{n}_end"
    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append(f'    bge {end_lbl}')
    out.append(f'    ldloc.s {f_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append(f'    callvirt instance !1 {func_il}::Invoke(!0)')
    out.append(f'    brfalse {skip_lbl}')
    out.append(f'    ldloc.s {res_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append(f'    callvirt instance void {list_type}::Add(!0)')
    out.append(f'  {skip_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {res_idx}')


# ---------------------------------------------------------------------
# reduce(f, xs, init) -> f.dtype (functools.reduce)
# ---------------------------------------------------------------------

def _reduce_result_dtype(args, scope):
    # Cung gioi han nhu _map_result_dtype: khong co func_table o day.
    if len(args) != 3:
        return None
    try:
        f_ta = _resolve_func_ta(args[0], scope, {}, 'reduce')
    except SyntaxError:
        return None
    return f_ta.dtype


def _temps_reduce(node, ctx):
    args = node[2]
    if len(args) != 3:
        return
    infer_scope = ctx['infer_scope']
    func_table = ctx['func_table']
    try:
        f_ta = _resolve_func_ta(args[0], infer_scope, func_table, 'reduce')
        _, lst_ta = _list_arg_ta(args[1], infer_scope, 'reduce', 2)
    except SyntaxError:
        return
    if list(f_ta.func_params) != [lst_ta.dtype, lst_ta.dtype]:
        return
    TypeAnn = ctx['TypeAnn']
    key = id(args)
    ctx['declare_named'](f'__reduce{key}_f', f_ta)
    ctx['declare_named'](f'__reduce{key}_src', TypeAnn(lst_ta.dtype, 'list'))
    ctx['declare_named'](f'__reduce{key}_idx', TypeAnn('i32', None))
    ctx['declare_named'](f'__reduce{key}_res', TypeAnn(f_ta.dtype, None))


def push_reduce(args, scope, out, dtype, ctx):
    f_node, lst_node, init_node = args
    f_ta = _resolve_func_ta(f_node, scope, ctx['func_table'], 'reduce')
    lst_name, lst_ta = _list_arg_ta(lst_node, scope, 'reduce', 2)
    if list(f_ta.func_params) != [lst_ta.dtype, lst_ta.dtype]:
        raise SyntaxError(
            f"il_codegen: reduce(f, {lst_name}, init) - chu ky 'f' can (({lst_ta.dtype}, "
            f"{lst_ta.dtype}) -> {f_ta.dtype}) (2 tham so CUNG dtype phan tu cua "
            f"'{lst_name}'), dang la (({', '.join(f_ta.func_params)}) -> {f_ta.dtype})")
    key = id(args)
    _, f_idx, _ = scope[f'__reduce{key}_f']
    _, src_idx, _ = scope[f'__reduce{key}_src']
    _, idx_idx, _ = scope[f'__reduce{key}_idx']
    _, res_idx, _ = scope[f'__reduce{key}_res']
    list_type = il_list_type(lst_ta.dtype, ctx.get('records'))
    func_il = ctx['il_type_str'](f_ta, ctx.get('records'))
    ctx['compile_expr'](init_node, scope, out, f_ta.dtype, ctx)
    out.append(f'    stloc.s {res_idx}')
    ctx['compile_funcref_arg'](f_node, f_ta, scope, out, ctx)
    out.append(f'    stloc.s {f_idx}')
    ctx['load_var_ref'](lst_name, scope, out)
    out.append(f'    stloc.s {src_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_reduce{n}_start"
    end_lbl = f"{ctx['prefix']}_reduce{n}_end"
    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append(f'    bge {end_lbl}')
    out.append(f'    ldloc.s {f_idx}')
    out.append(f'    ldloc.s {res_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append(f'    callvirt instance !2 {func_il}::Invoke(!0, !1)')
    out.append(f'    stloc.s {res_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {res_idx}')


def _filter_result_dtype(args, scope):
    if len(args) != 2:
        return None
    try:
        return _list_arg_ta(args[1], scope, 'filter', 2)[1].dtype
    except SyntaxError:
        return None


register_expr_builtin('map', push_map, None, return_shape='list',
                       temps_fn=_temps_map, return_dtype_fn=_map_result_dtype)
register_expr_builtin('filter', push_filter, None, return_shape='list',
                       temps_fn=_temps_filter, return_dtype_fn=_filter_result_dtype)
register_expr_builtin('reduce', push_reduce, None,
                       temps_fn=_temps_reduce, return_dtype_fn=_reduce_result_dtype)

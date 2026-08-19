# -*- coding: utf-8 -*-
"""collections.Counter (Phase 3.2, 2026-08-11) - "kieu built-in moi hoan
chinh" (nguoi dung da chon), phan cuoi cua Phase 3.2 sau namedtuple/
defaultdict.

Vat ly VAN LA 1 Dictionary<K,i32> (dung chung ha tang voi dict/defaultdict
- xem il_codegen.py's il_type_str/compile_index_store) - GHI qua chi so
(c[k] = v) hoat dong Y HET dict thuong. dtype GIA TRI luon CO DINH 'i32'
(khac dict/defaultdict co the chon dtype gia tri).

KHAC 'defaultdict' o hanh vi DOC khi THIEU khoa: Python's Counter tra ve
0 nhung KHONG chen key moi vao dict (defaultdict CO chen) - xem
compile_index_counter. Vi luon la hang so 0 (khong phai 1 factory tuy
bien), KHONG can delegate/local an giu factory nhu defaultdict.

`most_common(c, n)` (nguoi dung chon tra ve dung 'list[tuple(K,i32)]'
giong Python that, sau khi duoc giai thich ro rui ro so voi phuong an 2
list song song don gian hon) - qua 2 buoc:
1) copy toan bo entries cua Dictionary<K,i32> ra 2 List<K>/List<i32> song
   song (mau IL COPY Y HET codegen_for_in_dict_items trong dict_type.py -
   GetEnumerator/MoveNext/get_Current(KeyValuePair)/get_Key()/get_Value(),
   KHONG viet lai tu dau).
2) selection sort THU CONG giam dan theo vals (KHONG dung List<T>.Sort()
   - khong co comparer theo value san co trong ha tang), roi dung tuple
   literal MOI (newobj ValueTuple`2 - CHUA TUNG dung o vi tri BIEU THUC
   truoc gio, tuple truoc gio CHI xuat hien o 'return a,b'/'x,y = f()' -
   xem tuple_type.py) de dung List<ValueTuple<K,i32>> ket qua."""
from il_features.dict_type import il_dict_type
from il_features.list_type import il_list_type
from il_features.tuple_type import il_tupleN_type
from il_dispatch import register_expr_builtin
from typed_dsl_parser import TypeAnn as _TypeAnn


def compile_assign_counter_new(name, var_ta, rhs_node, scope, out, ctx):
    """'c: "Counter[K]" = Counter()' (rong) hoac 'Counter(xs)' (dem tan
    suat phan tu cua 1 BIEN list[K] da khai bao - khong bieu thuc long
    nhau, giong gioi han cua map/filter/sum)."""
    args = rhs_node[2]
    dict_type = ctx['il_type_str'](var_ta, ctx.get('records'))
    out.append(f'    newobj instance void {dict_type}::.ctor()')
    ctx['store_var'](name, scope, out)
    if len(args) == 0:
        return
    if len(args) != 1 or args[0][0] != 'var':
        raise SyntaxError(
            f"il_codegen: Counter(...) chi nhan 0 tham so (rong) hoac 1 BIEN "
            f"list[{var_ta.key_dtype}] (khong bieu thuc long nhau - gan ra 1 bien truoc)")
    list_name = args[0][1]
    _, _, list_ta = scope[list_name]
    if list_ta.shape != 'list' or list_ta.dtype != var_ta.key_dtype:
        raise SyntaxError(
            f"il_codegen: Counter({list_name}) - can 1 list[{var_ta.key_dtype}] (dang co "
            f"shape={list_ta.shape!r} dtype={list_ta.dtype!r})")
    list_type = il_list_type(list_ta.dtype, ctx.get('records'))
    _, idx_idx, _ = scope[f'__counter_idx_{name}']
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_counter{n}_start"
    have_lbl = f"{ctx['prefix']}_counter{n}_have"
    after_lbl = f"{ctx['prefix']}_counter{n}_after"
    end_lbl = f"{ctx['prefix']}_counter{n}_end"
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    ctx['load_var_ref'](list_name, scope, out)
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append(f'    bge {end_lbl}')
    ctx['load_var_ref'](name, scope, out)
    ctx['load_var_ref'](list_name, scope, out)
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append(f'    callvirt instance bool {dict_type}::ContainsKey(!0)')
    out.append(f'    brtrue {have_lbl}')
    ctx['load_var_ref'](name, scope, out)
    ctx['load_var_ref'](list_name, scope, out)
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append('    ldc.i4.1')
    out.append(f'    callvirt instance void {dict_type}::set_Item(!0, !1)')
    out.append(f'    br {after_lbl}')
    out.append(f'  {have_lbl}:')
    ctx['load_var_ref'](name, scope, out)
    ctx['load_var_ref'](list_name, scope, out)
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    ctx['load_var_ref'](name, scope, out)
    ctx['load_var_ref'](list_name, scope, out)
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append(f'    callvirt instance !1 {dict_type}::get_Item(!0)')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    callvirt instance void {dict_type}::set_Item(!0, !1)')
    out.append(f'  {after_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')


def compile_index_counter(name, indices, scope, out, dtype, ctx):
    """'c[k]' (doc) tren 1 Counter - KHAC defaultdict: khi THIEU khoa tra
    ve 0 nhung KHONG chen key moi vao dict (Python that: doc Counter
    khong lam phinh dict, chi GHI/tang truc tiep moi lam vay)."""
    if len(indices) != 1:
        raise SyntaxError(f"il_codegen: Counter '{name}' chi ho tro 1 khoa (vd {name}[k])")
    key_node = indices[0]
    if key_node[0] not in ('var', 'num', 'str_lit'):
        raise SyntaxError(
            f"il_codegen: Counter '{name}[k]' - khoa 'k' hien CHI nhan 1 BIEN hoac 1 hang so "
            f"(khong bieu thuc phuc tap - tranh bien dich lai khoa 2 lan gay tac dung phu kep)")
    _, _, type_ann = scope[name]
    dict_type = ctx['il_type_str'](type_ann, ctx.get('records'))
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    have_lbl = f"{ctx['prefix']}_counterget{n}_have"
    end_lbl = f"{ctx['prefix']}_counterget{n}_end"
    ctx['load_var_ref'](name, scope, out)
    ctx['compile_expr'](key_node, scope, out, type_ann.key_dtype, ctx)
    out.append(f'    callvirt instance bool {dict_type}::ContainsKey(!0)')
    out.append(f'    brtrue {have_lbl}')
    out.append('    ldc.i4.0')
    out.append(f'    br {end_lbl}')
    out.append(f'  {have_lbl}:')
    ctx['load_var_ref'](name, scope, out)
    ctx['compile_expr'](key_node, scope, out, type_ann.key_dtype, ctx)
    out.append(f'    callvirt instance !1 {dict_type}::get_Item(!0)')
    out.append(f'  {end_lbl}:')
    ctx['widen_if_needed']('i32', dtype, out)


def _most_common_result_dtype(args, scope):
    # EXPR_BUILTIN_DTYPE_FN (best-effort, khong co ctx day du - cung gioi
    # han nhu stdlib_functional.py's _map_result_dtype).
    return None


def _temps_most_common(node, ctx):
    args = node[2]
    if len(args) != 2 or args[0][0] != 'var':
        return
    infer_scope = ctx['infer_scope']
    try:
        c_ta = infer_scope[args[0][1]][2]
    except KeyError:
        return
    if c_ta.shape != 'counter':
        return
    TypeAnn = ctx['TypeAnn']
    key = id(args)
    ctx['declare_named'](f'__mc{key}_keys', TypeAnn(c_ta.key_dtype, 'list'))
    ctx['declare_named'](f'__mc{key}_vals', TypeAnn('i32', 'list'))
    # 'dict_enumerator'/'dict_kvpair' - shape CO SAN (dict_type.py, dung
    # cho 'for k,v in d.items():') - tai dung nguyen, khong tu dat shape moi.
    ctx['declare_named'](f'__mc{key}_en', TypeAnn('i32', 'dict_enumerator', key_dtype=c_ta.key_dtype))
    ctx['declare_named'](f'__mc{key}_cur', TypeAnn('i32', 'dict_kvpair', key_dtype=c_ta.key_dtype))
    for nm in ('i', 'j', 'maxi', 'maxv', 'cnt', 'limit', 'tmpv', 'nval'):
        ctx['declare_named'](f'__mc{key}_{nm}', TypeAnn('i32', None))
    ctx['declare_named'](f'__mc{key}_tmpk', TypeAnn(c_ta.key_dtype, None))
    ctx['declare_named'](f'__mc{key}_res', TypeAnn(c_ta.key_dtype, 'list',
                          elem_ta=TypeAnn('i32', 'tuple', tuple_dtypes=[c_ta.key_dtype, 'i32'])))


def push_most_common(args, scope, out, dtype, ctx):
    c_node, n_node = args
    if c_node[0] != 'var':
        raise SyntaxError("il_codegen: most_common(c, n) - 'c' phai la 1 BIEN Counter")
    c_name = c_node[1]
    _, _, c_ta = scope[c_name]
    if c_ta.shape != 'counter':
        raise SyntaxError(f"il_codegen: most_common({c_name}, ...) - '{c_name}' khong phai Counter")
    key = id(args)
    _, keys_idx, _ = scope[f'__mc{key}_keys']
    _, vals_idx, _ = scope[f'__mc{key}_vals']
    _, en_idx, _ = scope[f'__mc{key}_en']
    _, cur_idx, _ = scope[f'__mc{key}_cur']
    _, i_idx, _ = scope[f'__mc{key}_i']
    _, j_idx, _ = scope[f'__mc{key}_j']
    _, maxi_idx, _ = scope[f'__mc{key}_maxi']
    _, maxv_idx, _ = scope[f'__mc{key}_maxv']
    _, cnt_idx, _ = scope[f'__mc{key}_cnt']
    _, limit_idx, _ = scope[f'__mc{key}_limit']
    _, tmpk_idx, _ = scope[f'__mc{key}_tmpk']
    _, tmpv_idx, _ = scope[f'__mc{key}_tmpv']
    _, nval_idx, _ = scope[f'__mc{key}_nval']
    _, res_idx, _ = scope[f'__mc{key}_res']

    dict_type = il_dict_type(c_ta.key_dtype, 'i32', ctx.get('records'))
    keys_list_type = il_list_type(c_ta.key_dtype, ctx.get('records'))
    vals_list_type = il_list_type('i32', ctx.get('records'))
    tuple_dtypes = [c_ta.key_dtype, 'i32']
    tuple_type = il_tupleN_type(tuple_dtypes)
    res_list_type = f'class [mscorlib]System.Collections.Generic.List`1<{tuple_type}>'
    en_type_ph = 'valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<!0, !1>'
    kv_type_ph = 'valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<!0, !1>'
    key_il = ctx['il_type_str'](_TypeAnn(c_ta.key_dtype, None), ctx.get('records'))
    en_type = f'valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<{key_il}, int32>'
    kv_type = f'valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<{key_il}, int32>'

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    copy_start = f"{ctx['prefix']}_mc{n}_copy_start"
    copy_end = f"{ctx['prefix']}_mc{n}_copy_end"
    sort_i_start = f"{ctx['prefix']}_mc{n}_sorti_start"
    sort_i_end = f"{ctx['prefix']}_mc{n}_sorti_end"
    sort_j_start = f"{ctx['prefix']}_mc{n}_sortj_start"
    sort_j_end = f"{ctx['prefix']}_mc{n}_sortj_end"
    sort_j_skip = f"{ctx['prefix']}_mc{n}_sortj_skip"
    swap_skip = f"{ctx['prefix']}_mc{n}_swap_skip"
    build_start = f"{ctx['prefix']}_mc{n}_build_start"
    build_end = f"{ctx['prefix']}_mc{n}_build_end"
    limit_ge = f"{ctx['prefix']}_mc{n}_limit_ge"

    # --- Buoc 0: n (so luong yeu cau) - danh gia truoc, chua dung toi.
    ctx['compile_expr'](n_node, scope, out, 'i32', ctx)
    out.append(f'    stloc.s {nval_idx}')

    # --- Buoc 1: copy entries Dictionary<K,i32> -> 2 List<K>/List<i32>
    # song song (mau IL Y HET codegen_for_in_dict_items, dict_type.py).
    out.append(f'    newobj instance void {keys_list_type}::.ctor()')
    out.append(f'    stloc.s {keys_idx}')
    out.append(f'    newobj instance void {vals_list_type}::.ctor()')
    out.append(f'    stloc.s {vals_idx}')
    ctx['load_var_ref'](c_name, scope, out)
    out.append(f'    callvirt instance {en_type_ph} {dict_type}::GetEnumerator()')
    out.append(f'    stloc.s {en_idx}')
    out.append(f'  {copy_start}:')
    out.append(f'    ldloca.s {en_idx}')
    out.append(f'    call instance bool {en_type}::MoveNext()')
    out.append(f'    brfalse {copy_end}')
    out.append(f'    ldloca.s {en_idx}')
    out.append(f'    call instance {kv_type_ph} {en_type}::get_Current()')
    out.append(f'    stloc.s {cur_idx}')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    ldloca.s {cur_idx}')
    out.append(f'    call instance !0 {kv_type}::get_Key()')
    out.append(f'    callvirt instance void {keys_list_type}::Add(!0)')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloca.s {cur_idx}')
    out.append(f'    call instance !1 {kv_type}::get_Value()')
    out.append(f'    callvirt instance void {vals_list_type}::Add(!0)')
    out.append(f'    br {copy_start}')
    out.append(f'  {copy_end}:')

    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    callvirt instance int32 {keys_list_type}::get_Count()')
    out.append(f'    stloc.s {cnt_idx}')

    # --- Buoc 2: selection sort THU CONG giam dan theo vals (hoan doi
    # dong bo ca keys[i]/vals[i]) - khong dung List<T>.Sort() (khong co
    # comparer theo value san co).
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'  {sort_i_start}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {cnt_idx}')
    out.append(f'    bge {sort_i_end}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    stloc.s {maxi_idx}')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {vals_list_type}::get_Item(int32)')
    out.append(f'    stloc.s {maxv_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {j_idx}')
    out.append(f'  {sort_j_start}:')
    out.append(f'    ldloc.s {j_idx}')
    out.append(f'    ldloc.s {cnt_idx}')
    out.append(f'    bge {sort_j_end}')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {j_idx}')
    out.append(f'    callvirt instance !0 {vals_list_type}::get_Item(int32)')
    out.append(f'    ldloc.s {maxv_idx}')
    out.append(f'    ble {sort_j_skip}')
    out.append(f'    ldloc.s {j_idx}')
    out.append(f'    stloc.s {maxi_idx}')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {j_idx}')
    out.append(f'    callvirt instance !0 {vals_list_type}::get_Item(int32)')
    out.append(f'    stloc.s {maxv_idx}')
    out.append(f'  {sort_j_skip}:')
    out.append(f'    ldloc.s {j_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {j_idx}')
    out.append(f'    br {sort_j_start}')
    out.append(f'  {sort_j_end}:')
    out.append(f'    ldloc.s {maxi_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    beq {swap_skip}')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {keys_list_type}::get_Item(int32)')
    out.append(f'    stloc.s {tmpk_idx}')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    ldloc.s {maxi_idx}')
    out.append(f'    callvirt instance !0 {keys_list_type}::get_Item(int32)')
    out.append(f'    callvirt instance void {keys_list_type}::set_Item(int32, !0)')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    ldloc.s {maxi_idx}')
    out.append(f'    ldloc.s {tmpk_idx}')
    out.append(f'    callvirt instance void {keys_list_type}::set_Item(int32, !0)')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {vals_list_type}::get_Item(int32)')
    out.append(f'    stloc.s {tmpv_idx}')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {maxi_idx}')
    out.append(f'    callvirt instance !0 {vals_list_type}::get_Item(int32)')
    out.append(f'    callvirt instance void {vals_list_type}::set_Item(int32, !0)')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {maxi_idx}')
    out.append(f'    ldloc.s {tmpv_idx}')
    out.append(f'    callvirt instance void {vals_list_type}::set_Item(int32, !0)')
    out.append(f'  {swap_skip}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {sort_i_start}')
    out.append(f'  {sort_i_end}:')

    # --- Buoc 3: limit = min(n, cnt); dung List<ValueTuple<K,i32>> ket qua.
    out.append(f'    ldloc.s {nval_idx}')
    out.append(f'    ldloc.s {cnt_idx}')
    out.append(f'    bge {limit_ge}')
    out.append(f'    ldloc.s {nval_idx}')
    out.append(f'    stloc.s {limit_idx}')
    out.append(f'    br {build_start}_setup')
    out.append(f'  {limit_ge}:')
    out.append(f'    ldloc.s {cnt_idx}')
    out.append(f'    stloc.s {limit_idx}')
    out.append(f'  {build_start}_setup:')
    out.append(f'    newobj instance void {res_list_type}::.ctor()')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'  {build_start}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {limit_idx}')
    out.append(f'    bge {build_end}')
    out.append(f'    ldloc.s {res_idx}')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {keys_list_type}::get_Item(int32)')
    out.append(f'    ldloc.s {vals_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {vals_list_type}::get_Item(int32)')
    out.append(f'    newobj instance void {tuple_type}::.ctor(!0, !1)')
    out.append(f'    callvirt instance void {res_list_type}::Add(!0)')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {build_start}')
    out.append(f'  {build_end}:')
    out.append(f'    ldloc.s {res_idx}')


register_expr_builtin('most_common', push_most_common, None, return_shape='list',
                       temps_fn=_temps_most_common, return_dtype_fn=_most_common_result_dtype)

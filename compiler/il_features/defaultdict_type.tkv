# -*- coding: utf-8 -*-
"""collections.defaultdict (Phase 3.2, 2026-08-11) - "kieu built-in moi
hoan chinh" (nguoi dung da chon), KHONG syntax sugar tren dict co san.

Pham vi CO Y THUC thu hep (giong nguyen tac da dung cho map/filter/reduce
o Phase 3.3): vat ly VAN LA 1 Dictionary<K,V> (dung chung il_dict_type/
il_type_str voi 'dict' thuong - xem il_codegen.py's il_type_str) - CHI
KHAC hanh vi DOC qua chi so (d[k]): thay vi nem KeyNotFoundException khi
thieu khoa, tu dong goi 1 'factory' (ham 0 tham so, tra ve dung dtype gia
tri) de tao gia tri mac dinh, luu vao dict roi tra ve - dung Y HET ngu
nghia defaultdict cua Python that.

Factory (Lua chon nguoi dung, mo rong hon "chi int/list"): CHAP NHAN CA
1) ten 1 ham top-level 0 tham so, HOAC 2) 1 bien da khai bao kieu 'func()->
V' - tai su dung 100% ha tang first-class function cua Phase 3.3
(_resolve_func_ta cua stdlib_functional.py, ctx['compile_funcref_arg']) -
KHONG nhan lambda truc tiep tai cho (cung han che nhu map/filter, ly do
giong het: lambda tu than khong mang kieu).

Gia tri (V) CHI vo huong (i32/i64/f32/f64/str) - KHONG ho tro long nhau
(list/dict lam gia tri mac dinh) trong pham vi nay, vi 'd[k].append(x)'
kieu auto-vivify-roi-mutate can 1 thiet ke rieng phuc tap hon nhieu (gia
tri tra ve tu get_Item la 1 BAN SAO cho scalar nhung la THAM CHIEU cho
container - dung duoc 've mat ky thuat' nhung chua kiem chung ky, de lai
cho 1 phien sau neu can).

Chi so DOC (d[k]) CHI nhan 1 bien/hang so lam khoa (khong bieu thuc phuc
tap) - tranh phai bien dich lai khoa 2 LAN (1 lan ContainsKey, 1 lan
get_Item/set_Item) gay tac dung phu kep neu khoa la 1 bieu thuc co side-
effect - han che nay giong het 'sum()/min()/max()' chi nhan 1 BIEN list
don (_agg_arg_ta trong stdlib_aggregates.py), cung 1 tinh than."""
from il_features.stdlib_functional import _resolve_func_ta
from typed_dsl_parser import TypeAnn


def _factory_local_name(dict_var_name):
    return f'__defaultdict_factory_{dict_var_name}'


def compile_assign_defaultdict_new(name, var_ta, rhs_node, scope, out, ctx):
    """'d: "defaultdict[K,V]" = defaultdict(factory)' - tao 1 Dictionary<K,V>
    RONG (giong het 'd = {}') roi bien dich+luu factory (1 delegate
    System.Func`1<V>) vao local AN rieng (khai bao boi _fpw_assign_typed_decl
    trong il_codegen.py) de compile_index_defaultdict goi lai moi lan doc
    thieu khoa."""
    args = rhs_node[2]
    if len(args) != 1:
        raise SyntaxError(
            f"il_codegen: defaultdict(factory) can dung 1 tham so (ham 0 tham so tra ve "
            f"gia tri mac dinh), gap {len(args)}")
    factory_node = args[0]
    f_ta = _resolve_func_ta(factory_node, scope, ctx['func_table'], 'defaultdict')
    if f_ta.func_params:
        raise SyntaxError(
            f"il_codegen: defaultdict(factory) - 'factory' phai la 1 ham/bien kieu 'func' "
            f"KHONG THAM SO (dang nhan {len(f_ta.func_params)} tham so)")
    if f_ta.dtype != var_ta.dtype:
        raise SyntaxError(
            f"il_codegen: defaultdict[{var_ta.key_dtype},{var_ta.dtype}](...) - factory tra "
            f"ve {f_ta.dtype!r}, khong khop dtype gia tri khai bao ({var_ta.dtype!r})")
    dict_type = ctx['il_type_str'](var_ta, ctx.get('records'))
    out.append(f'    newobj instance void {dict_type}::.ctor()')
    ctx['store_var'](name, scope, out)
    ctx['compile_funcref_arg'](factory_node, f_ta, scope, out, ctx)
    ctx['store_var'](_factory_local_name(name), scope, out)


def compile_index_defaultdict(name, indices, scope, out, dtype, ctx):
    """'d[k]' (doc) tren 1 defaultdict - tag 'index' cua _compile_expr khi
    shape=='defaultdict', xem il_codegen.py's _expr_index. Khoa CHI nhan 1
    bien/hang so (xem docstring module) - bien dich lai duoc 2 LAN an toan."""
    if len(indices) != 1:
        raise SyntaxError(f"il_codegen: defaultdict '{name}' chi ho tro 1 khoa (vd {name}[k])")
    key_node = indices[0]
    if key_node[0] not in ('var', 'num', 'str_lit'):
        raise SyntaxError(
            f"il_codegen: defaultdict '{name}[k]' - khoa 'k' hien CHI nhan 1 BIEN hoac 1 "
            f"hang so (khong bieu thuc phuc tap - tranh bien dich lai khoa 2 lan gay tac "
            f"dung phu kep)")
    _, _, type_ann = scope[name]
    dict_type = ctx['il_type_str'](type_ann, ctx.get('records'))
    func_il = ctx['il_type_str'](
        TypeAnn(type_ann.dtype, 'func', func_params=[]), ctx.get('records'))
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    have_lbl = f"{ctx['prefix']}_defaultdict{n}_have"
    ctx['load_var_ref'](name, scope, out)
    ctx['compile_expr'](key_node, scope, out, type_ann.key_dtype, ctx)
    out.append(f'    callvirt instance bool {dict_type}::ContainsKey(!0)')
    out.append(f'    brtrue {have_lbl}')
    ctx['load_var_ref'](name, scope, out)
    ctx['compile_expr'](key_node, scope, out, type_ann.key_dtype, ctx)
    ctx['load_var_ref'](_factory_local_name(name), scope, out)
    out.append(f'    callvirt instance !0 {func_il}::Invoke()')
    out.append(f'    callvirt instance void {dict_type}::set_Item(!0, !1)')
    out.append(f'  {have_lbl}:')
    ctx['load_var_ref'](name, scope, out)
    ctx['compile_expr'](key_node, scope, out, type_ann.key_dtype, ctx)
    out.append(f'    callvirt instance !1 {dict_type}::get_Item(!0)')
    ctx['widen_if_needed'](type_ann.dtype, dtype, out)

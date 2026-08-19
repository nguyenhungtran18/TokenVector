# -*- coding: utf-8 -*-
"""d.setdefault(k, default) (2026-07-29, Huong A stdlib mo rong - nhom
rieng thu 7, mo phong kien truc d.get()/d.pop() cua dict_get.py/dict_pop.py:
dang ky truc tiep vao if-chain cua record_feature.py's compile_method_call.

Ngu nghia Python that: neu k CO trong d, tra ve d[k] (KHONG doi gi); neu
KHONG co, GAN d[k] = default ROI tra ve default. Da xac minh truoc khi
viet (PowerShell reflection): Dictionary<K,V>.set_Item(K,V) CO THAT (tuong
duong d[k]=v). GIOI HAN DA BIET (giong get()/pop()): key_node/default_node
duoc compile_expr NHIEU LAN - an toan vi DSL nay khong co bieu thuc co
side-effect."""
from il_features.dict_type import il_dict_type


def compile_dict_method_setdefault(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 2:
        raise SyntaxError("il_codegen: d.setdefault(k, default) can dung 2 tham so")
    _, _, ta = scope[obj_name]
    if ta.shape != 'dict':
        raise SyntaxError(f"il_codegen: '{obj_name}.setdefault(...)' can '{obj_name}' la dict")
    key_node, default_node = args[0], args[1]
    dict_type = il_dict_type(ta.key_dtype, ta.dtype, (ctx or {}).get('records'))
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    miss_lbl = f"{ctx['prefix']}_dsetdef{n}_miss"
    end_lbl = f"{ctx['prefix']}_dsetdef{n}_end"

    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    out.append(f'    callvirt instance bool {dict_type}::ContainsKey(!0)')
    out.append(f'    brfalse {miss_lbl}')

    # k CO san: tra ve d[k], KHONG ghi gi
    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    out.append(f'    callvirt instance !1 {dict_type}::get_Item(!0)')
    ctx['widen_if_needed'](ta.dtype, dtype, out)
    out.append(f'    br {end_lbl}')

    out.append(f'  {miss_lbl}:')
    # k KHONG co: d[k] = default (set_Item), roi tra ve default
    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    compile_expr(default_node, scope, out, ta.dtype, ctx)
    out.append(f'    callvirt instance void {dict_type}::set_Item(!0, !1)')
    compile_expr(default_node, scope, out, dtype, ctx)

    out.append(f'  {end_lbl}:')

# -*- coding: utf-8 -*-
"""d.pop(k, default) (2026-07-29, Huong A stdlib mo rong - nhom rieng,
mo phong CHINH XAC kien truc d.get(k, default) cua dict_get.py: dang ky
truc tiep vao if-chain cua record_feature.py's compile_method_call
(khong can ASSIGN_RHS_PARSERS/first-pass rieng vi KHONG can hidden local -
xem ky thuat 'dup+pop' duoi day).

GIOI HAN DA BIET (giong het get()): CHI ho tro dang 2-THAM-SO co
default (Python dict.pop(k) 1-THAM-SO nem KeyError khi thieu key - CHUA
ho tro, giong ly do get() cung chi ho tro 2-tham-so). key_node duoc
compile_expr BA LAN (ContainsKey/get_Item/Remove) - an toan voi bien/hang,
co the tinh lai sai neu la bieu thuc phuc tap co side-effect (DSL nay
khong co side-effect trong bieu thuc nen an toan THAT SU, giong ghi chu
cua get())."""


def compile_dict_method_pop(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 2:
        raise SyntaxError("il_codegen: d.pop(k, default) can dung 2 tham so")
    _, _, ta = scope[obj_name]
    if ta.shape != 'dict':
        raise SyntaxError(f"il_codegen: '{obj_name}.pop(...)' can '{obj_name}' la dict")
    key_node, default_node = args[0], args[1]
    dict_type = ctx['il_type_str'](ta, ctx.get('records'))
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    miss_lbl = f"{ctx['prefix']}_dpop{n}_miss"
    end_lbl = f"{ctx['prefix']}_dpop{n}_end"

    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    out.append(f'    callvirt instance bool {dict_type}::ContainsKey(!0)')
    out.append(f'    brfalse {miss_lbl}')

    # value = d[k]  (lay TRUOC khi xoa - Remove(k) sau do se khong con doc
    # duoc gia tri nay tu dictionary nua)
    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    out.append(f'    callvirt instance !1 {dict_type}::get_Item(!0)')
    # d.Remove(k) - tra ve bool, day chong: [value, bool] -> 'pop' bo di
    # CHI bool (dinh nghia IL: pop bo phan tu TREN CUNG), giu lai [value]
    # duoi day nguyen ven - khong can local an nao.
    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    out.append(f'    callvirt instance bool {dict_type}::Remove(!0)')
    out.append('    pop')
    ctx['widen_if_needed'](ta.dtype, dtype, out)
    out.append(f'    br {end_lbl}')

    out.append(f'  {miss_lbl}:')
    compile_expr(default_node, scope, out, dtype, ctx)

    out.append(f'  {end_lbl}:')

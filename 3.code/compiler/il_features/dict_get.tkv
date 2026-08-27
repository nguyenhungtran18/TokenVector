# -*- coding: utf-8 -*-
"""d.get(k, default) (2026-07-29) - soan nhap boi Gemini, dung khop chu ky
method_call that ngay lan dau. Re nhanh kieu ternary (label_counter/prefix)
dua theo ContainsKey().

GIOI HAN DA BIET (giong path_exists()): key_node duoc compile_expr HAI
LAN (1 lan ContainsKey, 1 lan get_Item neu nhanh do chay) - an toan neu k
la 1 bien/hang, co the tinh lai sai neu k la 1 bieu thuc phuc tap co
side-effect."""


def compile_dict_method_get(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 2:
        raise SyntaxError("il_codegen: d.get(k, default) can dung 2 tham so")
    _, _, ta = scope[obj_name]
    if ta.shape != 'dict':
        raise SyntaxError(f"il_codegen: '{obj_name}.get(...)' can '{obj_name}' la dict")
    key_node, default_node = args[0], args[1]
    dict_type = ctx['il_type_str'](ta, ctx.get('records'))
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    miss_lbl = f"{ctx['prefix']}_dget{n}_miss"
    end_lbl = f"{ctx['prefix']}_dget{n}_end"

    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    out.append(f'    callvirt instance bool {dict_type}::ContainsKey(!0)')
    out.append(f'    brfalse {miss_lbl}')

    load_var_ref(obj_name, scope, out)
    compile_expr(key_node, scope, out, ta.key_dtype, ctx)
    out.append(f'    callvirt instance !1 {dict_type}::get_Item(!0)')
    ctx['widen_if_needed'](ta.dtype, dtype, out)
    out.append(f'    br {end_lbl}')

    out.append(f'  {miss_lbl}:')
    # Gia tri MAC DINH phai bien dich theo dtype GIA TRI CUA DICT roi moi
    # widen ve dtype ngu canh - truoc day dung thang `dtype` cua ngu canh
    # nen 'seen.get(w, 0)' trong 1 ham tra ve 'str' sinh 'ldc <str> 0'
    # (KeyError luc bien dich). 2026-08-03, dot 3.
    compile_expr(default_node, scope, out, ta.dtype, ctx)
    ctx['widen_if_needed'](ta.dtype, dtype, out)

    out.append(f'  {end_lbl}:')

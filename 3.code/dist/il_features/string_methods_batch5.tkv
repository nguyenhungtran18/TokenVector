# -*- coding: utf-8 -*-
"""String methods batch 5 (Moc 14, 2026-08-09): s.removeprefix(prefix), s.removesuffix(suffix), s.rfind(sub)."""
from il_dispatch import register_expr_method

def _validate_str_method_caller(obj_name, scope):
    ta = scope[obj_name][2]
    if ta.dtype != 'str' or ta.shape is not None:
        raise SyntaxError(f"il_codegen: '{obj_name}' khong phai la bien string vo huong")

def compile_str_method_removeprefix(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: s.removeprefix(prefix) nhan dung 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    prefix_arg = args[0]
    load_var_ref = ctx['load_var_ref']
    compile_expr = ctx['compile_expr']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    starts_lbl = f"{ctx['prefix']}_rempref{n}_starts"
    end_lbl = f"{ctx['prefix']}_rempref{n}_end"

    load_var_ref(obj_name, scope, out)
    compile_expr(prefix_arg, scope, out, 'str', ctx)
    out.append('    callvirt instance bool [mscorlib]System.String::StartsWith(string)')
    out.append(f'    brtrue {starts_lbl}')
    
    # False: return original s
    load_var_ref(obj_name, scope, out)
    out.append(f'    br {end_lbl}')

    # True: return s.Substring(prefix.Length)
    out.append(f'  {starts_lbl}:')
    load_var_ref(obj_name, scope, out)
    compile_expr(prefix_arg, scope, out, 'str', ctx)
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    out.append('    callvirt instance string [mscorlib]System.String::Substring(int32)')

    out.append(f'  {end_lbl}:')

def compile_str_method_removesuffix(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: s.removesuffix(suffix) nhan dung 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    suffix_arg = args[0]
    load_var_ref = ctx['load_var_ref']
    compile_expr = ctx['compile_expr']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    ends_lbl = f"{ctx['prefix']}_remsuff{n}_ends"
    end_lbl = f"{ctx['prefix']}_remsuff{n}_end"

    load_var_ref(obj_name, scope, out)
    compile_expr(suffix_arg, scope, out, 'str', ctx)
    out.append('    callvirt instance bool [mscorlib]System.String::EndsWith(string)')
    out.append(f'    brtrue {ends_lbl}')
    
    # False: return original s
    load_var_ref(obj_name, scope, out)
    out.append(f'    br {end_lbl}')

    # True: return s.Substring(0, s.Length - suffix.Length)
    out.append(f'  {ends_lbl}:')
    load_var_ref(obj_name, scope, out)
    out.append('    ldc.i4.0')
    load_var_ref(obj_name, scope, out)
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    compile_expr(suffix_arg, scope, out, 'str', ctx)
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    out.append('    sub')
    out.append('    callvirt instance string [mscorlib]System.String::Substring(int32, int32)')

    out.append(f'  {end_lbl}:')

def compile_str_method_rfind(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: s.rfind(sub) nhan dung 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    sub_arg = args[0]
    load_var_ref = ctx['load_var_ref']
    compile_expr = ctx['compile_expr']

    load_var_ref(obj_name, scope, out)
    compile_expr(sub_arg, scope, out, 'str', ctx)
    out.append('    callvirt instance int32 [mscorlib]System.String::LastIndexOf(string)')
    if dtype == 'i64':
        out.append('    conv.i8')

STR_METHODS_EXTRA3 = {
    'removeprefix': compile_str_method_removeprefix,
    'removesuffix': compile_str_method_removesuffix,
    'rfind': compile_str_method_rfind,
}

register_expr_method('str', 'removeprefix', compile_str_method_removeprefix, return_dtype='str')
register_expr_method('str', 'removesuffix', compile_str_method_removesuffix, return_dtype='str')
register_expr_method('str', 'rfind', compile_str_method_rfind, return_dtype='i32')

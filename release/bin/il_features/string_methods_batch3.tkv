# -*- coding: utf-8 -*-
"""string.startswith()/.endswith()/.find()/.rfind()/.lstrip()/.rstrip()
(2026-07-29,
Huong A stdlib mo rong - nhom rieng, dang ky qua STR_METHODS-compatible
dict giong het string_methods_batch2.py, KHONG sua file do). Chi 5 ham co
anh xa 1:1 THAT SU voi 1 method .NET co san (dung tinh than "chi la du
lieu, khong logic moi"): cac ham Python string CHUA co anh xa 1:1 an toan
(count/isalpha/title/capitalize/zfill - ngu nghia khac .NET hoac can vong
lap) CHU Y KHONG dua vao day, de nhom rieng khi thuc su can va xac minh ky
ngu nghia. isdigit() da duoc dua vao day sau khi ledger P036/P041 chung minh
khoang trong compile_gap; no di qua TkvStr helper rieng vi chuoi rong cua
Python phai la False."""


def _validate_str_method_caller(obj_name, scope):
    ta = scope[obj_name][2]
    if ta.dtype != 'str' or ta.shape is not None:
        raise SyntaxError(f"il_codegen: '{obj_name}' khong phai la bien string vo huong")


def compile_str_method_startswith(node, scope, out, dtype, ctx):
    """s.startswith(prefix) - String::StartsWith(string) tra ve bool,
    ngu nghia khop het Python (so sanh ordinal theo tung ky tu dau)."""
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: s.startswith(x) can dung 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    callvirt instance bool [mscorlib]System.String::StartsWith(string)')


def compile_str_method_endswith(node, scope, out, dtype, ctx):
    """s.endswith(suffix) - String::EndsWith(string), tuong tu startswith."""
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: s.endswith(x) can dung 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    callvirt instance bool [mscorlib]System.String::EndsWith(string)')


def compile_str_method_find(node, scope, out, dtype, ctx):
    """s.find(sub) / s.find(sub, start) - String::IndexOf(string) hoac
    IndexOf(string, int32), tra ve -1 khi khong tim thay, KHOP CHINH XAC
    ngu nghia Python str.find (khac str.index nem ValueError - khong lam
    index() o day vi can co che nem exception rieng, chua co trong DSL
    nay). Tham so 2 'start' them 2026-08-11 (Phase 1.5) - Python cho phep
    start > len(s) (tra -1 an toan), .NET IndexOf(string,int32) NEM
    ArgumentOutOfRangeException trong truong hop do - chua xu ly rieng vi
    it gap trong thuc te (canh bao trong docstring, khong am tham sai)."""
    obj_name, args = node[1], node[3]
    if len(args) not in (1, 2):
        raise SyntaxError("il_codegen: s.find(x) hoac s.find(x, start) can 1 hoac 2 tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    if len(args) == 2:
        ctx['compile_expr'](args[1], scope, out, 'i32', ctx)
        out.append('    callvirt instance int32 [mscorlib]System.String::IndexOf(string, int32)')
    else:
        out.append('    callvirt instance int32 [mscorlib]System.String::IndexOf(string)')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_str_method_rfind(node, scope, out, dtype, ctx):
    """s.rfind(sub) - B6 (2026-08-05): di qua TkvStr::RFind (khong goi
    thang String::LastIndexOf) vi do THAT bang arbiter lo lech o ca bien
    sub="": Python "hello".rfind("") = 5 (do dai chuoi), .NET's
    LastIndexOf("") = 4 - can re nhanh RIENG cho truong hop nay (xem
    tkvstr.py). 'sub' la bieu thuc bat ky luc chay nen khong quyet dinh
    duoc rong hay khong luc bien dich."""
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: s.rfind(x) can dung 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    import il_features.tkvstr as _tkvstr
    _tkvstr.ensure_class(ctx)
    ctx['load_var_ref'](obj_name, scope, out)
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append(f'    call int32 {_tkvstr.TKVSTR_CLASS}::RFind(string, string)')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_str_method_isdigit(node, scope, out, dtype, ctx):
    """s.isdigit() - Python tra False cho chuoi rong va True chi khi moi
    ky tu la digit. Khong goi thang LINQ/all de tranh them dependency; helper
    TkvStr::IsDigit lap ro trong CIL."""
    obj_name, args = node[1], node[3]
    if len(args) != 0:
        raise SyntaxError("il_codegen: s.isdigit() khong nhan tham so")
    _validate_str_method_caller(obj_name, scope)
    import il_features.tkvstr as _tkvstr
    _tkvstr.ensure_class(ctx)
    ctx['load_var_ref'](obj_name, scope, out)
    out.append(f'    call int32 {_tkvstr.TKVSTR_CLASS}::IsDigit(string)')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_str_method_lstrip(node, scope, out, dtype, ctx):
    """s.lstrip() - String KHONG co overload TrimStart() KHONG tham so
    that su (xac minh qua PowerShell reflection: [string].GetMethods()
    CHI co 'TrimStart(Char[])') - C# 's.TrimStart()' duoc trinh bien dich
    tu dong nap 'null' cho tham so char[] nay, phai lam dung y het
    (ldnull truoc callvirt).
    s.lstrip(chars) them 2026-08-13: mirror compile_str_method_strip -
    'chars'.ToCharArray() truoc khi goi TrimStart(char[])."""
    obj_name, args = node[1], node[3]
    if len(args) not in (0, 1):
        raise SyntaxError("il_codegen: s.lstrip() hoac s.lstrip(chars) can 0 hoac 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    if len(args) == 1:
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    callvirt instance char[] [mscorlib]System.String::ToCharArray()')
    else:
        out.append('    ldnull')
    out.append('    callvirt instance string [mscorlib]System.String::TrimStart(char[])')


def compile_str_method_rstrip(node, scope, out, dtype, ctx):
    """s.rstrip() - tuong tu lstrip(), TrimEnd(Char[]) voi null.
    s.rstrip(chars) them 2026-08-13: mirror compile_str_method_strip."""
    obj_name, args = node[1], node[3]
    if len(args) not in (0, 1):
        raise SyntaxError("il_codegen: s.rstrip() hoac s.rstrip(chars) can 0 hoac 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    if len(args) == 1:
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    callvirt instance char[] [mscorlib]System.String::ToCharArray()')
    else:
        out.append('    ldnull')
    out.append('    callvirt instance string [mscorlib]System.String::TrimEnd(char[])')


STR_METHODS_EXTRA = {
    'startswith': compile_str_method_startswith,
    'endswith': compile_str_method_endswith,
    'find': compile_str_method_find,
    'rfind': compile_str_method_rfind,
    'isdigit': compile_str_method_isdigit,
    'lstrip': compile_str_method_lstrip,
    'rstrip': compile_str_method_rstrip,
}

# Dung boi il_codegen.py's _infer_dtype (method_call) de biet dtype THAT
# ket qua tra ve khi khac 'str' mac dinh - startswith/endswith la bool
# (dai dien i32 trong DSL nay, giong re_match), find/rfind la vi tri i32.
RETURN_DTYPE = {
    'startswith': 'i32',
    'endswith': 'i32',
    'find': 'i32',
    'rfind': 'i32',
    'isdigit': 'i32',
}

from il_dispatch import register_str_method_return_dtype

register_str_method_return_dtype(RETURN_DTYPE)

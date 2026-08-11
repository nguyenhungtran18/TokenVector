# -*- coding: utf-8 -*-
"""string.upper()/.lower()/.strip()/.replace() (2026-07-29) - soan nhap
boi Gemini, dung KHOP ngay chu ky EXPR_CODEGEN thuc su (node, scope,
out, dtype, ctx) - khong can Claude sua logic, chi doi ten file khi tich
hop. record_feature.py's compile_method_call goi lai cac ham nay khi
obj_ta.shape is None va dtype=='str' (string la REFERENCE TYPE giong
List/Dictionary, chi can load_var_ref - khac record la STRUCT can
load_var_addr)."""


def _validate_str_method_caller(obj_name, scope):
    ta = scope[obj_name][2]
    if ta.dtype != 'str' or ta.shape is not None:
        raise SyntaxError(f"il_codegen: '{obj_name}' khong phai la bien string vo huong")


def compile_str_method_upper(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 0:
        raise SyntaxError("il_codegen: s.upper() khong nhan tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    out.append('    callvirt instance string [mscorlib]System.String::ToUpper()')


def compile_str_method_lower(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 0:
        raise SyntaxError("il_codegen: s.lower() khong nhan tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    out.append('    callvirt instance string [mscorlib]System.String::ToLower()')


def compile_str_method_strip(node, scope, out, dtype, ctx):
    """s.strip() -> String::Trim() (khong tham so). s.strip(chars) them
    2026-08-11 (Phase 1.5): Trim(char[]) can 1 MANG ky tu, khong phai 1
    string - dung 'chars'.ToCharArray() de doi kieu truoc khi goi, giong
    het ngu nghia Python str.strip(chars) (bo TAT CA ky tu co trong tap
    'chars' o ca 2 dau, khong phai bo NGUYEN CHUOI con)."""
    obj_name, args = node[1], node[3]
    if len(args) not in (0, 1):
        raise SyntaxError("il_codegen: s.strip() hoac s.strip(chars) can 0 hoac 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    if len(args) == 1:
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    callvirt instance char[] [mscorlib]System.String::ToCharArray()')
        out.append('    callvirt instance string [mscorlib]System.String::Trim(char[])')
    else:
        out.append('    callvirt instance string [mscorlib]System.String::Trim()')


def compile_str_method_replace(node, scope, out, dtype, ctx):
    """'.replace(old, new)' - di qua TkvStr::Replace (khong goi thang
    System.String::Replace) vi .NET NEM ArgumentException khi old="" con
    Python thi hop le (chen new xen giua moi ky tu) - xem tkvstr.py."""
    obj_name, args = node[1], node[3]
    if len(args) != 2:
        raise SyntaxError("il_codegen: s.replace(old, new) can dung 2 tham so")
    _validate_str_method_caller(obj_name, scope)
    import il_features.tkvstr as _tkvstr
    _tkvstr.ensure_class(ctx)
    ctx['load_var_ref'](obj_name, scope, out)
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    out.append(f'    call string {_tkvstr.TKVSTR_CLASS}::Replace(string, string, string)')


def compile_str_method_join(node, scope, out, dtype, ctx):
    """sep.join(lst) - Join la STATIC method tren System.String (class
    KHONG generic), khac List<T>::AddRange/.ctor(IEnumerable<T>) dung !0:
    tham so IEnumerable o day PHAI dong kieu cu the IEnumerable`1<string>,
    dung !0 se MissingMethodException luc chay (giao Gemini, xac nhan
    dung mau)."""
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: sep.join(lst) can dung 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    if args[0][0] != 'var':
        raise SyntaxError("il_codegen: sep.join(lst) chi ho tro tham so la 1 bien list don")
    lst_name = args[0][1]
    _, _, lst_ta = scope[lst_name]
    if lst_ta.shape != 'list' or lst_ta.dtype != 'str':
        raise SyntaxError(f"il_codegen: '{obj_name}.join({lst_name})' can '{lst_name}' la list cua string")
    load_var_ref = ctx['load_var_ref']
    load_var_ref(obj_name, scope, out)
    load_var_ref(lst_name, scope, out)
    out.append(
        '    call string [mscorlib]System.String::Join(string, class '
        '[mscorlib]System.Collections.Generic.IEnumerable`1<string>)')


STR_METHODS = {
    'upper': compile_str_method_upper,
    'lower': compile_str_method_lower,
    'strip': compile_str_method_strip,
    'replace': compile_str_method_replace,
    'join': compile_str_method_join,
}

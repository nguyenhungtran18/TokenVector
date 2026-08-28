# -*- coding: utf-8 -*-
"""s.capitalize() (2026-07-29, Huong A stdlib mo rong - nhom rieng thu 10,
KHONG phai anh xa 1:1 (giong zfill) - Python capitalize() = ky tu DAU
UPPER, TOAN BO phan con lai LOWER (KHAC .NET khong co method tuong duong
truc tiep). File RIENG (khong sua string_methods_batch2/batch3.py),
merge vao _STR_METHODS qua them 1 dict o record_feature.py.

Ky thuat: dung nhanh label-based 'hop nhat gia tri' (giong dict_get.py's
ternary-style branch, KHONG can hidden local vi day la EXPRESSION
codegen thuan tuy qua method_call, khac zfill/string.count can vong lap+
local nen phai qua ASSIGN_RHS_PARSERS). GIOI HAN: rong (len==0) tra ve
nguyen s (Python that cung vay, "".capitalize()==''), tranh
Substring(1) tren chuoi rong (.NET nem ArgumentOutOfRangeException neu
khong bao ve truong hop nay - da xac minh qua PowerShell reflection
truoc: ''.Substring(1) UNCAUGHT tren chuoi rong, KHONG phai gia dinh)."""


def _validate_str_method_caller(obj_name, scope):
    ta = scope[obj_name][2]
    if ta.dtype != 'str' or ta.shape is not None:
        raise SyntaxError(f"il_codegen: '{obj_name}' khong phai la bien string vo huong")


def compile_str_method_capitalize(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 0:
        raise SyntaxError("il_codegen: s.capitalize() khong nhan tham so")
    _validate_str_method_caller(obj_name, scope)
    load_var_ref = ctx['load_var_ref']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    nonempty_lbl = f"{ctx['prefix']}_cap{n}_nonempty"
    end_lbl = f"{ctx['prefix']}_cap{n}_end"

    load_var_ref(obj_name, scope, out)
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    out.append('    ldc.i4.0')
    out.append(f'    bgt {nonempty_lbl}')
    # rong: tra nguyen s
    load_var_ref(obj_name, scope, out)
    out.append(f'    br {end_lbl}')

    out.append(f'  {nonempty_lbl}:')
    # s.Substring(0,1).ToUpper() + s.Substring(1).ToLower()
    load_var_ref(obj_name, scope, out)
    out.append('    ldc.i4.0')
    out.append('    ldc.i4.1')
    out.append('    callvirt instance string [mscorlib]System.String::Substring(int32, int32)')
    out.append('    callvirt instance string [mscorlib]System.String::ToUpper()')
    load_var_ref(obj_name, scope, out)
    out.append('    ldc.i4.1')
    out.append('    callvirt instance string [mscorlib]System.String::Substring(int32)')
    out.append('    callvirt instance string [mscorlib]System.String::ToLower()')
    out.append('    call string [mscorlib]System.String::Concat(string, string)')

    out.append(f'  {end_lbl}:')


STR_METHODS_EXTRA2 = {
    'capitalize': compile_str_method_capitalize,
}

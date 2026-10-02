# -*- coding: utf-8 -*-
"""s.zfill(width) (2026-07-29, Huong A stdlib mo rong; nang cap Giai doan
0.2 nhom 3 ngay 2026-08-03). KHONG phai anh xa 1:1 don gian (ngu nghia
Python zfill khac han .NET, khong co method tuong duong) - phai tu viet
thuat toan rieng.

TU 2026-08-03: dang ky qua register_expr_method (il_dispatch.py) nen chay
duoc o MOI vi tri bieu thuc ('return s.zfill(5)', 's.zfill(5) + "!"'),
KHONG con gioi han "chi RHS truc tiep 1 phep gan". Duong ASSIGN_RHS cu da
BO HAN - 'x = s.zfill(n)' nay di qua nhanh assign_scalar CHUNG.

Thuat toan (khop Python str.zfill that): dem so '0' can them =
width - len(s); NEU <= 0 tra ve s KHONG doi; NGUOC LAI, NEU s bat dau
bang '+'/'-' (dau), chen '0' SAU dau (vd (-42).zfill(5) -> '-0042', KHONG
phai '000-42'); NGUOC LAI chen '0' o DAU chuoi.

Da xac minh truoc khi viet (PowerShell reflection): String.Substring(Int32)/
Substring(Int32,Int32)/Concat(string,string) deu CO THAT (dung API tieu
chuan, khong doan mo)."""
from il_dispatch import register_expr_method


def temps_string_zfill(node, ctx):
    """FIRST PASS: hidden local, khoa = id(node) (xem stdlib_string_count.py).
    '__zfill..._res' la bien KET QUA (ban cu ghi thang vao bien dich)."""
    ctx['declare_named'](f'__zfill{id(node)}_res', ctx['TypeAnn']('str', None))
    ctx['declare_named'](f'__zfill{id(node)}_padlen', ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__zfill{id(node)}_zeros', ctx['TypeAnn']('str', None))


def compile_string_zfill(node, scope, out, dtype, ctx):
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: str.zfill() chi nhan dung 1 tham so")
    body = out

    _, res_idx, _ = scope[f'__zfill{id(node)}_res']
    _, padlen_idx, _ = scope[f'__zfill{id(node)}_padlen']
    _, zeros_idx, _ = scope[f'__zfill{id(node)}_zeros']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    no_pad_lbl = f"{ctx['prefix']}_zfill{n}_nopad"
    has_sign_lbl = f"{ctx['prefix']}_zfill{n}_hassign"
    no_sign_lbl = f"{ctx['prefix']}_zfill{n}_nosign"
    end_lbl = f"{ctx['prefix']}_zfill{n}_end"

    # pad_len = width - len(s)
    compile_expr(args[0], scope, body, 'i32', ctx)
    load_var_ref(obj_name, scope, body)
    body.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    body.append('    sub')
    body.append(f'    stloc.s {padlen_idx}')

    body.append(f'    ldloc.s {padlen_idx}')
    body.append('    ldc.i4.0')
    body.append(f'    ble {no_pad_lbl}')

    # zeros = new string('0', pad_len)
    body.append('    ldc.i4.s 48')
    body.append(f'    ldloc.s {padlen_idx}')
    body.append('    newobj instance void [mscorlib]System.String::.ctor(char, int32)')
    body.append(f'    stloc.s {zeros_idx}')

    # if len(s) > 0 and (s[0]=='+' or s[0]=='-'): goto has_sign
    load_var_ref(obj_name, scope, body)
    body.append('    ldc.i4.0')
    body.append('    callvirt instance char [mscorlib]System.String::get_Chars(int32)')
    body.append('    ldc.i4.s 43')  # '+'
    body.append('    ceq')
    body.append(f'    brtrue {has_sign_lbl}')
    load_var_ref(obj_name, scope, body)
    body.append('    ldc.i4.0')
    body.append('    callvirt instance char [mscorlib]System.String::get_Chars(int32)')
    body.append('    ldc.i4.s 45')  # '-'
    body.append('    ceq')
    body.append(f'    brtrue {has_sign_lbl}')
    body.append(f'    br {no_sign_lbl}')

    body.append(f'  {has_sign_lbl}:')
    # name = s.Substring(0,1) + zeros + s.Substring(1)
    load_var_ref(obj_name, scope, body)
    body.append('    ldc.i4.0')
    body.append('    ldc.i4.1')
    body.append('    callvirt instance string [mscorlib]System.String::Substring(int32, int32)')
    body.append(f'    ldloc.s {zeros_idx}')
    body.append('    call string [mscorlib]System.String::Concat(string, string)')
    load_var_ref(obj_name, scope, body)
    body.append('    ldc.i4.1')
    body.append('    callvirt instance string [mscorlib]System.String::Substring(int32)')
    body.append('    call string [mscorlib]System.String::Concat(string, string)')
    body.append(f'    stloc.s {res_idx}')
    body.append(f'    br {end_lbl}')

    body.append(f'  {no_sign_lbl}:')
    # res = zeros + s
    body.append(f'    ldloc.s {zeros_idx}')
    load_var_ref(obj_name, scope, body)
    body.append('    call string [mscorlib]System.String::Concat(string, string)')
    body.append(f'    stloc.s {res_idx}')
    body.append(f'    br {end_lbl}')

    body.append(f'  {no_pad_lbl}:')
    # res = s (khong doi)
    load_var_ref(obj_name, scope, body)
    body.append(f'    stloc.s {res_idx}')

    body.append(f'  {end_lbl}:')
    body.append(f'    ldloc.s {res_idx}')


register_expr_method('str', 'zfill', compile_string_zfill, 'str', temps_string_zfill)

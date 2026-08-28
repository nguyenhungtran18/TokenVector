# -*- coding: utf-8 -*-
"""s.count(sub) cho STRING (2026-07-29, Huong A stdlib mo rong; nang cap
Giai doan 0.2 nhom 3 ngay 2026-08-03).

TU 2026-08-03: dang ky qua register_expr_method (il_dispatch.py) nen chay
duoc o MOI vi tri bieu thuc ('return s.count(x)', 's.count(x) + 1',
'f(s.count(x))'), KHONG con gioi han "chi RHS truc tiep 1 phep gan" nhu
ban dau. Duong ASSIGN_RHS_PARSERS cu da BO HAN (khong con
'assign_string_count') - 'n = s.count(x)' nay di qua nhanh assign_scalar
CHUNG, giam 1 duong phan tich song song (dung tinh than "giam no ky thuat,
khong chi va trieu chung" cua ke hoach 0.2). Hidden local (sub/idx/found)
duoc first-pass cap phat qua temps_fn, dat ten theo id(node AST).

KHONG dung chung code voi list.count() cua list_count_index.py du regex
giong het - 2 thuat toan khac han (list duyet phan tu, string dung IndexOf).

Thuat toan: dem KHONG CHONG LAP (giong Python str.count that) bang vong
lap IndexOf(sub, tu_vi_tri) - moi lan tim thay, nhay qua ca do dai sub
truoc khi tim tiep. GIOI HAN DA BIET (chua xu ly, giong tinh than chap
nhan gioi han cua min/max list rong): sub la CHUOI RONG se vong lap VO
HAN (tim thay lai CHINH vi tri cu, khong tien len) - KHONG dung count()
voi tham so la chuoi rong."""
from il_dispatch import register_expr_method


def temps_string_count(node, ctx):
    """FIRST PASS: cap phat 3 hidden local. Khoa = id(node) - AST parse
    DUY NHAT 1 lan va dung lai o pass 2 (xem ghi chu tai _expr_ternary
    trong il_codegen.py), nen id() la khoa TIN CAY giua 2 pass."""
    ctx['declare_named'](f'__strcnt{id(node)}_sub', ctx['TypeAnn']('str', None))
    ctx['declare_named'](f'__strcnt{id(node)}_idx', ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__strcnt{id(node)}_found', ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__strcnt{id(node)}_cnt', ctx['TypeAnn']('i32', None))


def compile_string_count(node, scope, out, dtype, ctx):
    """PASS 2: day KET QUA (so lan xuat hien, i32) len stack - KHAC ban cu
    (ghi thang vao bien dich): gio la 1 bieu thuc nen phai ket thuc bang
    'ldloc' cua bien dem, de caller (binop/return/...) dung tiep."""
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: str.count() chi nhan dung 1 tham so")
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']

    _, sub_idx, _ = scope[f'__strcnt{id(node)}_sub']
    _, idx_idx, _ = scope[f'__strcnt{id(node)}_idx']
    _, found_idx, _ = scope[f'__strcnt{id(node)}_found']
    _, cnt_idx, _ = scope[f'__strcnt{id(node)}_cnt']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_scnt{n}_start"
    end_lbl = f"{ctx['prefix']}_scnt{n}_end"

    # sub = <bieu thuc x> (tinh 1 LAN duy nhat)
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append(f'    stloc.s {sub_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {cnt_idx}')

    out.append(f'  {start_lbl}:')
    # found = s.IndexOf(sub, idx)
    load_var_ref(obj_name, scope, out)
    out.append(f'    ldloc.s {sub_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    callvirt instance int32 [mscorlib]System.String::IndexOf(string, int32)')
    out.append(f'    stloc.s {found_idx}')
    # if found == -1: goto end
    out.append(f'    ldloc.s {found_idx}')
    out.append('    ldc.i4.m1')
    out.append(f'    beq {end_lbl}')
    # cnt += 1
    out.append(f'    ldloc.s {cnt_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {cnt_idx}')
    # idx = found + sub.Length
    out.append(f'    ldloc.s {found_idx}')
    out.append(f'    ldloc.s {sub_idx}')
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {cnt_idx}')
    ctx['widen_if_needed']('i32', dtype, out)


register_expr_method('str', 'count', compile_string_count, 'i32', temps_string_count)

# -*- coding: utf-8 -*-
"""s.title() (2026-07-29, Huong A stdlib mo rong; nang cap Giai doan 0.2
nhom 3 ngay 2026-08-03).

TU 2026-08-03: dang ky qua register_expr_method (il_dispatch.py) nen chay
duoc o MOI vi tri bieu thuc ('return s.title()', 's.title() + "!"'),
KHONG con gioi han "chi RHS truc tiep 1 phep gan". Duong ASSIGN_RHS cu da
BO HAN - 'x = s.title()' nay di qua nhanh assign_scalar CHUNG.

Thuat toan (XAC MINH qua Gemini doi voi hanh vi CPython that truoc khi
viet, KHONG doan mo): duyet TUNG KY TU, giu 1 co bool 'previous_is_cased'.
- Ky tu 'cased' (co phan biet hoa/thuong, o day thu hep ve ASCII qua
  Char.IsLetter - KHONG ho tro Unicode day du, chi dung cho pham vi
  ASCII/Latin co ban cua TokenVector hien tai): NEU previous_is_cased=false
  -> ToUpper (bat dau tu moi), NGUOC LAI ToLower (giua tu). Cap nhat
  previous_is_cased=true.
- Ky tu KHONG cased (so, dau cau, khoang trang): giu nguyen, cap nhat
  previous_is_cased=false (ngat chuoi lien tuc chu, tu tiep theo se viet
  hoa lai) - vi du that: 'apple42book'->'Apple42Book' (so ngat tu),
  "they're"->"They'Re" (dau nhay don CUNG ngat tu, KHONG phai ngoai le).

Xay dung KET QUA bang Concat trong vong lap (giong repeat_str cua
stdlib_repeat.py, chap nhan O(n^2) - da la mo hinh chuan cua compiler nay
cho string builder don gian, khong dung StringBuilder vi kieu do khong
nam trong tap dtype TypeAnn ho tro).

Da xac minh truoc khi viet (PowerShell reflection): Char.IsLetter(Char),
Char.ToUpper(Char), Char.ToLower(Char) deu la STATIC method THAT tren
System.Char (khong phai instance, khong can dia chi/ldloca) - va
String::.ctor(char, int32) da duoc dung THAT trong stdlib_string_zfill.py
(cung file nay) de dung 1 char lam chuoi 1 ky tu."""
from il_dispatch import register_expr_method


def temps_string_title(node, ctx):
    """FIRST PASS: hidden local, khoa = id(node) (xem stdlib_string_count.py).
    '__title..._res' la bien KET QUA (ban cu ghi thang vao bien dich; gio
    la bieu thuc nen can 1 cho chua rieng roi 'ldloc' o cuoi)."""
    ctx['declare_named'](f'__title{id(node)}_res', ctx['TypeAnn']('str', None))
    ctx['declare_named'](f'__title{id(node)}_idx', ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__title{id(node)}_c', ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__title{id(node)}_prevcased', ctx['TypeAnn']('i32', None))


def compile_string_title(node, scope, out, dtype, ctx):
    load_var_ref = ctx['load_var_ref']
    obj_name = node[1]
    if node[3]:
        raise SyntaxError("il_codegen: str.title() khong nhan tham so")
    body = out

    _, res_idx, _ = scope[f'__title{id(node)}_res']
    _, idx_idx, _ = scope[f'__title{id(node)}_idx']
    _, c_idx, _ = scope[f'__title{id(node)}_c']
    _, prevcased_idx, _ = scope[f'__title{id(node)}_prevcased']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_title{n}_start"
    not_letter_lbl = f"{ctx['prefix']}_title{n}_notletter"
    prev_cased_lbl = f"{ctx['prefix']}_title{n}_prevcased"
    append_lbl = f"{ctx['prefix']}_title{n}_append"
    end_lbl = f"{ctx['prefix']}_title{n}_end"

    # result = "" ; idx = 0 ; prev_cased = 0
    body.append('    ldstr ""')
    body.append(f'    stloc.s {res_idx}')
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {idx_idx}')
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {prevcased_idx}')

    body.append(f'  {start_lbl}:')
    # if idx >= len(s): goto end
    body.append(f'    ldloc.s {idx_idx}')
    load_var_ref(obj_name, scope, body)
    body.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    body.append(f'    bge {end_lbl}')

    # c = s.get_Chars(idx)
    load_var_ref(obj_name, scope, body)
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    callvirt instance char [mscorlib]System.String::get_Chars(int32)')
    body.append(f'    stloc.s {c_idx}')

    # if !Char.IsLetter(c): goto not_letter
    body.append(f'    ldloc.s {c_idx}')
    body.append('    call bool [mscorlib]System.Char::IsLetter(char)')
    body.append(f'    brfalse {not_letter_lbl}')

    # is a letter: if prev_cased: ToLower else ToUpper ; luon set prev_cased=1
    body.append(f'    ldloc.s {prevcased_idx}')
    body.append(f'    brtrue {prev_cased_lbl}')
    body.append(f'    ldloc.s {c_idx}')
    body.append('    call char [mscorlib]System.Char::ToUpper(char)')
    body.append(f'    stloc.s {c_idx}')
    body.append('    ldc.i4.1')
    body.append(f'    stloc.s {prevcased_idx}')
    body.append(f'    br {append_lbl}')
    body.append(f'  {prev_cased_lbl}:')
    body.append(f'    ldloc.s {c_idx}')
    body.append('    call char [mscorlib]System.Char::ToLower(char)')
    body.append(f'    stloc.s {c_idx}')
    body.append('    ldc.i4.1')
    body.append(f'    stloc.s {prevcased_idx}')
    body.append(f'    br {append_lbl}')

    body.append(f'  {not_letter_lbl}:')
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {prevcased_idx}')

    body.append(f'  {append_lbl}:')
    # result = result + new string(c, 1)
    body.append(f'    ldloc.s {res_idx}')
    body.append(f'    ldloc.s {c_idx}')
    body.append('    ldc.i4.1')
    body.append('    newobj instance void [mscorlib]System.String::.ctor(char, int32)')
    body.append('    call string [mscorlib]System.String::Concat(string, string)')
    body.append(f'    stloc.s {res_idx}')
    # idx += 1
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'    br {start_lbl}')

    body.append(f'  {end_lbl}:')
    body.append(f'    ldloc.s {res_idx}')


register_expr_method('str', 'title', compile_string_title, 'str', temps_string_title)

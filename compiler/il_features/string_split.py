# -*- coding: utf-8 -*-
"""s.split(sep) (2026-07-29, Wave 1 con lai) - tra ve List<str> MOI.

GIOI HAN DA BIET (co chu dich, khong phai thieu cong suc): 'sep' PHAI la
1 chuoi DUNG 1 KY TU (Python str.split(sep) cho phep sep nhieu ky tu -
KHONG duoc ho tro o day, chi lay ky tu DAU TIEN qua get_Chars(0) - .NET
String.Split(char[]) von chi tach theo TUNG KY TU DON, khac han
String.Split(string[], StringSplitOptions) moi ho tro chuoi phan cach
nhieu ky tu - chon overload char[] don gian hon, du cho phan lon truong
hop DSL nho gon muc tieu cua du an).

Ket qua la 1 LIST MOI (khong phai scalar). TU 2026-08-03 (Giai doan 0.2
nhom 4): dang ky qua register_expr_method(..., return_shape='list') nen
chay duoc o MOI vi tri bieu thuc ('return s.split(",")',
'len(s.split(","))'), KHONG con gioi han "chi RHS truc tiep 1 phep gan".
Duong ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN -
'parts = s.split(sep)' nay di qua nhanh assign_scalar CHUNG, voi hinh
dang list[str] lay tu EXPR_METHOD_SHAPE (xem _shaped_return_ta_of_call
trong il_codegen.py - CUNG nhanh da dung cho ham nguoi dung tra ve
container, khong phai duong rieng thu 2)."""
from il_dispatch import register_expr_method
from il_features.list_type import il_list_type
from typed_dsl_parser import TypeAnn


def compile_string_split(node, scope, out, dtype, ctx):
    """THU TU STACK (da xac minh THAT qua ilasm.exe compile+run):
    nap nguon -> tao char[1 phan tu] (newarr+dup de giu tham chieu mang
    lai sau khi ghi) -> trich ky tu DAU TIEN cua 'sep' (get_Chars(0)) ->
    ghi vao mang (stelem.i2, opcode danh cho mang phan tu 16-bit nhu
    System.Char) -> goi String.Split(char[]) -> boc ket qua string[]
    thanh List<str> qua .ctor(IEnumerable<!0>) (cung ky thuat da verify
    voi dict_keys_values.py - string[] TU NO da implement IEnumerable<string>)."""
    src_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: str.split() chi nhan dung 1 tham so")
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']

    load_var_ref(src_name, scope, out)
    out.append('    ldc.i4.1')
    out.append('    newarr [mscorlib]System.Char')
    out.append('    dup')
    out.append('    ldc.i4.0')
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    ldc.i4.0')
    out.append('    callvirt instance char [mscorlib]System.String::get_Chars(int32)')
    out.append('    stelem.i2')
    out.append('    callvirt instance string[] [mscorlib]System.String::Split(char[])')
    list_type = il_list_type('str', ctx.get('records'))
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


register_expr_method('str', 'split', compile_string_split,
                      return_ta_fn=lambda _obj_ta: TypeAnn('str', 'list'),
                      result_shape='list')

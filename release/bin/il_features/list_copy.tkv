# -*- coding: utf-8 -*-
"""lst.copy() (2026-07-29, Huong A stdlib mo rong; nang cap Giai doan 0.2
nhom 5 ngay 2026-08-03).

Ban sao NONG (shallow copy) - tao List<T> MOI tu IEnumerable<T> nguon,
dung y het ky thuat sorted() cua stdlib_aggregates.py's
codegen_assign_sorted (List<T>::.ctor(IEnumerable<T>)) NHUNG khong goi
Sort() sau do - giu nguyen thu tu phan tu (Python list.copy() KHONG sap
xep lai). Da grep xac nhan truoc khi viet: KHONG co dau khac dinh nghia
'list_copy'/'.copy(' trong il_features/*.py.

TU 2026-08-03 (nhom 5): dang ky qua register_expr_method nen chay duoc o
MOI vi tri bieu thuc, KHONG con gioi han "chi RHS truc tiep 1 phep gan".
Duong ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN. Kieu
tra ve la DUNG kieu cua list nguon (tra THANG obj_ta - giu nguyen ca
elem_ta khi nguon la container long nhau, dung nhu ban cu lam)."""
from il_dispatch import register_expr_method


def compile_list_copy(node, scope, out, dtype, ctx):
    if node[3]:
        raise SyntaxError("il_codegen: list.copy() khong nhan tham so")
    list_name = node[1]
    list_ta = scope[list_name][2]
    list_type = ctx['il_type_str'](list_ta, ctx.get('records'))
    ctx['load_var_ref'](list_name, scope, out)
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


register_expr_method('list', 'copy', compile_list_copy,
                      return_ta_fn=lambda lst_ta: lst_ta, result_shape='list')

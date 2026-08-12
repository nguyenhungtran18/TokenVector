# -*- coding: utf-8 -*-
"""s.to_list() - HashSet<T> -> List<T> (2026-08-03).

VI SAO CAN: 'for x in <set>:' KHONG chay duoc. Macro for-in (control_flow.
py's try_expand_for_in_list) khai trien thanh 'for i in range(len(c)):
x = c[i]' - HashSet<T> KHONG co indexer nen buoc x = c[i] hong (truoc day
bao loi kho hieu 'chi ho tro mang rank 1 hoac 2'). Macro lam viec o tang
VAN BAN, chua he biet hinh dang cua bien, nen khong the tu re nhanh.

Thay vi viet 1 duong lap RIENG cho set (Enumerator thu cong tren
valuetype), cho phep chuyen sang list roi lap nhu binh thuong:
    xs = s.to_list()
    for x in xs:
        ...
1 loi goi newobj List`1::.ctor(IEnumerable`1<!0>) - DUNG ky thuat cua
list.copy()/sorted()/dict.items(). Python that KHONG co set.to_list()
(viet la list(s)) - day la KHAC BIET co y thuc, ghi ro: DSL nay chua co
builtin list() nhan container.

THU TU phan tu: theo thu tu duyet cua HashSet<T> - KHONG dam bao, giong
het set cua Python. Can thu tu on dinh thi tu sap xep sau."""
from il_dispatch import register_expr_method
from il_features.list_type import il_list_type
from typed_dsl_parser import TypeAnn


def _to_list_return_ta(set_ta):
    return TypeAnn(set_ta.dtype, 'list')


def compile_set_to_list(node, scope, out, dtype, ctx):
    if node[3]:
        raise SyntaxError("il_codegen: set.to_list() khong nhan tham so")
    set_name = node[1]
    set_ta = scope[set_name][2]
    list_type = il_list_type(set_ta.dtype, ctx.get('records'))
    ctx['load_var_ref'](set_name, scope, out)
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


register_expr_method('set', 'to_list', compile_set_to_list,
                      return_ta_fn=_to_list_return_ta, result_shape='list')

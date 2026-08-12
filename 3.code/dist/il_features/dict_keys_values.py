# -*- coding: utf-8 -*-
"""dict.keys()/.values() (2026-07-29, Wave 1 con lai) - vat lieu hoa
(materialize) thanh 1 List<T> MOI de tuong tac duoc voi toan bo co che
"for x in lst:"/index/len() da co san cho list (Dictionary<K,V>.KeyCollection/
ValueCollection KHONG dung duoc truc tiep voi cu phap for-loop hien tai,
chi ho tro rieng List<T> va 'for k,v in d.items():').

Ky thuat: List<T>::.ctor(IEnumerable<T>) - KeyCollection/ValueCollection
tu no da IMPLEMENT IEnumerable<T> nen truyen thang duoc, khong can tu
duyet tay. QUAN TRONG (giong het loai bug da gap voi GetRange/AddRange):
CA return type cua get_Keys()/get_Values() LAN tham so .ctor() deu phai
dung placeholder generic MO (!0/!1), KHONG phai kieu da dong - vi 2
method nay duoc dinh nghia TREN chinh dinh nghia generic MO cua
Dictionary`2/List`1, khong phai tren ban dong cu the.

TU 2026-08-03 (Giai doan 0.2 nhom 5): dang ky qua register_expr_method nen
chay duoc o MOI vi tri bieu thuc (lam doi so 1 loi goi ham khac...), KHONG
con gioi han "chi RHS truc tiep 1 phep gan". Duong ASSIGN_RHS_PARSERS/
FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN. Kieu tra ve PHU THUOC dict
nguon (list[key_dtype] vs list[val_dtype]) nen dung ham phan giai
return_ta_fn (xem il_dispatch.py) - day chinh la ly do nhom 5 phai tong
quat hoa EXPR_METHOD_SHAPE tu cap (dtype, shape) TINH sang HAM."""

from il_dispatch import register_expr_method
from il_features.dict_type import il_dict_type
from il_features.list_type import il_list_type
from typed_dsl_parser import TypeAnn


def _compile_dict_collection(dict_name, scope, out, ctx, which):
    _, _, dict_ta = scope[dict_name]
    dict_type = il_dict_type(dict_ta.key_dtype, dict_ta.dtype, (ctx or {}).get('records'))
    elem_dtype = dict_ta.key_dtype if which == 'keys' else dict_ta.dtype
    list_type = il_list_type(elem_dtype, (ctx or {}).get('records'))
    coll_name = 'KeyCollection' if which == 'keys' else 'ValueCollection'
    getter = 'get_Keys' if which == 'keys' else 'get_Values'
    coll_type_ph = (
        f'class [mscorlib]System.Collections.Generic.Dictionary`2/{coll_name}<!0, !1>')

    ctx['load_var_ref'](dict_name, scope, out)
    out.append(f'    callvirt instance {coll_type_ph} {dict_type}::{getter}()')
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


def _make_compile(which):
    def fn(node, scope, out, dtype, ctx):
        if node[3]:
            raise SyntaxError(f"il_codegen: dict.{which}() khong nhan tham so")
        _compile_dict_collection(node[1], scope, out, ctx, which)
    return fn


register_expr_method('dict', 'keys', _make_compile('keys'),
                      return_ta_fn=lambda d_ta: TypeAnn(d_ta.key_dtype, 'list'),
                      result_shape='list')
register_expr_method('dict', 'values', _make_compile('values'),
                      return_ta_fn=lambda d_ta: TypeAnn(d_ta.dtype, 'list'),
                      result_shape='list')

# -*- coding: utf-8 -*-
"""dict.items() gan bien DOC LAP ('items_list = d.items()') - hang muc
CUOI CUNG con lai cua Huong A stdlib mo rong (2026-07-29), khac VOI 'for
k, v in d.items():' da co san TRUOC do trong dict_type.py (cu phap do CHI
dung TRUC TIEP trong for-loop, khong materialize duoc thanh 1 gia tri
list doc lap de truyen/luu/duyet lai).

QUYET DINH KIEN TRUC (theo huong nguoi dung chon - "Day du nhu for k,v
in d.items()"): dung List<KeyValuePair<K,V>> lam kieu chua, KHONG dung
ValueTuple<K,V> - vi Dictionary<K,V> tu no da la
IEnumerable<KeyValuePair<K,V>> THAT (BCL chuan), nen new
List<KeyValuePair<K,V>>(d) chay THANG, KHONG can 1 vong lap thu cong
nao de chuyen doi (giong ky thuat list.copy()/sorted() cua
stdlib_aggregates.py/list_copy.py - List<T>::.ctor(IEnumerable<T>)).
Day CHINH LA ly do quyet dinh nay RE hon nhieu so voi phuong an
ValueTuple<K,V> (se can 1 vong lap thu cong chuyen doi KeyValuePair->
ValueTuple, khong co san trong BCL).

TypeAnn cua bien ket qua: dtype=val_dtype (sentinel, xem docstring
elem_ta trong typed_dsl_parser.py), shape='list', elem_ta=TypeAnn(
val_dtype, 'dict_kvpair', key_dtype) - TAI SU DUNG 100% ha tang container-
long-nhau co san tu Wave 2 (il_type_str's shape=='list'+elem_ta,
_index_src_is_nested_container trong il_codegen.py) - KHONG can code moi
cho phan 'pair = items_list[idx]' (list-cua-kvpair indexing) VA
'k = pair.key'/'v = pair.val' (attr access tren shape 'dict_kvpair',
xem record_feature.py's compile_attr + il_codegen.py's _infer_dtype,
2 diem duy nhat CAN sua trong core cho tinh nang nay).

'for k, v in items_list:' (duyet TRUC TIEP bien da materialize, giai nen
ca hai gia tri ngay tai for-loop, KHONG can 'pair.key'/'pair.value' thu
cong) - xem file rieng for_in_kvlist.py (macro TEXT-LEVEL, giong
for_in_list cua control_flow.py).

TU 2026-08-03 (Giai doan 0.2 nhom 6): dang ky qua register_expr_method nen
chay duoc o MOI vi tri bieu thuc, KHONG con gioi han "chi RHS truc tiep 1
phep gan". Duong ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu da BO
HAN. Kieu tra ve PHU THUOC dict nguon nen dung ham phan giai return_ta_fn
(co che nhom 5) - KHONG can co che loi moi nao."""
from il_dispatch import register_expr_method
from typed_dsl_parser import TypeAnn


def _items_return_ta(dict_ta):
    """list[KeyValuePair<K,V>] cua CHINH dict nguon - dung y het TypeAnn
    ma fpw_assign_dict_items cu tao ra (dtype=val_dtype lam sentinel,
    elem_ta mang ca key_dtype), chi khac la nay tinh tu obj_ta thay vi
    tu stmt."""
    kv_ta = TypeAnn(dict_ta.dtype, 'dict_kvpair', dict_ta.key_dtype)
    return TypeAnn(dict_ta.dtype, 'list', elem_ta=kv_ta)


def compile_dict_items(node, scope, out, dtype, ctx):
    if node[3]:
        raise SyntaxError("il_codegen: dict.items() khong nhan tham so")
    dict_name = node[1]
    _, _, dict_ta = scope[dict_name]
    list_type = ctx['il_type_str'](_items_return_ta(dict_ta), ctx.get('records'))
    ctx['load_var_ref'](dict_name, scope, out)
    # '!0' (placeholder generic, KHONG phai kieu KeyValuePair<K,V> da thay
    # the) - CUNG ly do voi list.copy()/sorted(): .ctor duoc dinh nghia
    # tren List`1 MO, methodref phai ghi dung nhu vay (da bi MissingMethodException
    # khi viet sai kieu nay o cac nhom truoc, xem memory).
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


register_expr_method('dict', 'items', compile_dict_items,
                      return_ta_fn=_items_return_ta, result_shape='list')

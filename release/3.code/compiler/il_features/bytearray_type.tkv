# -*- coding: utf-8 -*-
"""Kieu 'bytearray' (muc 6.8, 3/4, 2026-08-13) - List<uint8> (khac
List<int32> cua list[i32] CHI o KICH THUOC phan tu). File RIENG (giong
list_type.py/set_type.py) de sua bug/them tinh nang KHONG can dong den
list/dict/set.

CHI ho tro (theo dung pham vi task):
  - 'ba = bytearray()' (constructor RONG, khong nhan n/list/literal)
  - 'ba.append(x)' - x la i32, NARROW ve byte qua 'conv.u1' TRUOC Add(!0)
    (List<uint8>.Add can 1 gia tri uint8 THAT tren stack, khac list[i32]
    khong can narrow). KHONG validate 0-255 luc chay - tran (vd 300) bi
    conv.u1 CAT AM THAM con 300 mod 256 = 44 - day la HANH VI CO Y THUC
    (giong C#/CIL that), khong phai bug can sua o day.
  - Doc (index/len/for-in): xac nhan qua DIEU TRA THAT (Step 1, xem plan
    2026-08-13-bytearray.md) - _list_compile_index_list (list_type.py's
    compile_index_list) VA len()'s nhanh 'list' trong il_codegen.py deu
    CHI dung ctx['il_type_str'](type_ann,...) + 'callvirt instance !0
    ...::get_Item(int32)' - KHONG hardcode int32/dtype cu the nao, hoan
    toan tong quat qua placeholder generic '!0' (ECMA-335: gia tri nho
    hon int32 tren stack SAU khi generic duoc thay the bang uint8 se TU
    DUOC chuan hoa thanh int32 khi callvirt tra ve - da XAC NHAN THAT qua
    build+chay test, khong chi tin ly thuyet). VI VAY: doc TAI DUNG
    NGUYEN VEN 2 ham do (_list_compile_index_list, len()'s nhanh list) -
    CHI can day il_codegen.py's il_type_str/_expr_index/len() nhan them
    shape=='bytearray' va tra ve dung List<uint8> (qua il_bytearray_type
    o duoi) thay vi List<i32>. KHONG viet ham doc rieng - giai thuyet
    trong plan la DUNG."""
import re

from il_core import parse_expr
from il_dispatch import (
    register_assign_rhs_parser, register_line_parser,
    register_stmt_codegen, register_first_pass_walk,
)


def il_bytearray_type() -> str:
    """Kieu IL DONG (closed generic) cua bytearray - List<uint8>. Khong
    nhan tham so dtype (khac il_list_type) vi phan tu LUON la 1 kieu duy
    nhat, khong suy tu '.append()' dau tien nhu list."""
    return 'class [mscorlib]System.Collections.Generic.List`1<unsigned int8>'


_BYTEARRAY_NEW_RE = re.compile(r'^bytearray\(\)\s*$')
_BYTEARRAY_APPEND_RE = re.compile(r'^(\w+)\.append\((.+)\)\s*$')


def try_rhs_bytearray_new(rhs, name, known_shapes):
    """ASSIGN_RHS_PARSERS entry: 'ba = bytearray()' - CHI dang RONG (khong
    'bytearray(n)'/'bytearray(list)'/literal 'b"..."', ngoai pham vi task
    nay theo dung Global Constraints cua plan)."""
    rhs_s = rhs.strip()
    if not _BYTEARRAY_NEW_RE.match(rhs_s):
        return None
    known_shapes[name] = 'bytearray'
    return {'kind': 'assign_bytearray_new', 'name': name}


def try_parse_bytearray_append(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: 'ba.append(x)' - CHI khop khi 'known_shapes[name]
    == "bytearray"' (giong het cach try_parse_list_remove loai tru set/
    frozenset) - PHAI dang ky TRUOC list.append/method_call_stmt tong
    quat de khong bi 'cuop' mat (thu tu dang ky trong LINE_PARSERS quyet
    dinh thu tu thu - xem il_dispatch.py)."""
    m = _BYTEARRAY_APPEND_RE.match(line)
    if not m or known_shapes.get(m.group(1)) != 'bytearray':
        return None
    name, arg_expr = m.groups()
    return {'kind': 'bytearray_append', 'name': name, 'value_node': parse_expr(arg_expr)}, pos + 1


def codegen_assign_bytearray_new(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'ba = bytearray()'."""
    body.append(f'    newobj instance void {il_bytearray_type()}::.ctor()')
    ctx['store_var'](stmt['name'], scope, body)


def codegen_bytearray_append(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'ba.append(x)' - x bien dich nhu i32 (gia tri
    THAT nguoi dung viet ra luon la so nguyen thuong), THEM 'conv.u1'
    truoc Add(!0) de narrow xuong byte THAT tren stack (List<uint8>.Add
    doi hoi dung the, khac List<i32> khong can buoc nay) - tran (vd 300)
    bi CAT AM THAM (300 mod 256 = 44), CO Y THUC, xem ghi chu dau file."""
    ctx['load_var_ref'](stmt['name'], scope, body)
    ctx['compile_expr'](stmt['value_node'], scope, body, 'i32', ctx)
    body.append('    conv.u1')
    body.append(f'    callvirt instance void {il_bytearray_type()}::Add(!0)')


def fpw_assign_bytearray_new(stmt, ctx):
    """FIRST_PASS_WALK: khai bao local List<uint8> - dtype phan tu luon
    co dinh ('i32', dung lam kenh gia tri tren stack sau widen/khong-
    widen; shape='bytearray' moi la thu quyet dinh IL that qua il_type_str)
    KHONG can suy tu '.append()' dau tien nhu list (khac list_type.py's
    declare_list) vi phan tu bytearray LUON la 1 kieu duy nhat."""
    ctx['declare_named'](stmt['name'], ctx['TypeAnn']('i32', 'bytearray'))


def fpw_bytearray_append(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['value_node'])


register_assign_rhs_parser('bytearray_new', try_rhs_bytearray_new)
register_line_parser('bytearray_append', try_parse_bytearray_append)
register_stmt_codegen('assign_bytearray_new', codegen_assign_bytearray_new)
register_stmt_codegen('bytearray_append', codegen_bytearray_append)
register_first_pass_walk('assign_bytearray_new', fpw_assign_bytearray_new)
register_first_pass_walk('bytearray_append', fpw_bytearray_append)

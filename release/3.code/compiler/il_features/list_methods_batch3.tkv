# -*- coding: utf-8 -*-
"""list.reverse() (2026-07-29, Huong A stdlib mo rong - nhom rieng, mo
phong khuon list_methods_batch2.py (sort()/extend()): dang ky
LINE_PARSERS + STMT_CODEGEN rieng (statement, khong tra ve gia tri).

CHU Y (phat hien luc tich hop): 'list.remove(x)'/'list.insert(i,x)' DA
CO SAN trong il_features/list_type.py (try_parse_list_remove/
try_parse_list_insert) - ban dau dinh them ca remove() vao day gay
TRUNG LAP kind='list_remove' (STMT_CODEGEN bi ghi de vi la dict, dtype
khac nhau giua 2 ban -> KeyError 'target_node' vs 'value_node' cua ban
cu). Da bo phan remove() khoi file nay, CHI con reverse() (xac nhan
chua co o dau qua grep truoc khi viet).

Da xac minh truoc: 'Reverse()' (khong tham so, dao nguoc List<T> TAI
CHO) CO THAT qua PowerShell reflection tren List`1[int].GetMethods()."""
import re

from il_dispatch import register_line_parser, register_stmt_codegen, register_first_pass_walk
from il_features.list_type import il_list_type

_LIST_REVERSE_RE = re.compile(r'^(\w+)\.reverse\(\)\s*$')


def try_parse_list_reverse(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: 'lst.reverse()' - PHAI dang ky TRUOC method_call_stmt."""
    m = _LIST_REVERSE_RE.match(line)
    if not m:
        return None
    return {'kind': 'list_reverse', 'name': m.group(1)}, pos + 1


def codegen_list_reverse(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'lst.reverse()' - List<T>.Reverse() (khong
    tham so, dao nguoc TAI CHO - dung ngu nghia Python list.reverse())."""
    _, _, ta = scope[stmt['name']]
    ctx['load_var_ref'](stmt['name'], scope, body)
    body.append(f'    callvirt instance void {il_list_type(ta.dtype, ctx.get("records"))}::Reverse()')


def fpw_list_reverse(stmt, ctx):
    pass


register_line_parser('list_reverse', try_parse_list_reverse)
register_stmt_codegen('list_reverse', codegen_list_reverse)
register_first_pass_walk('list_reverse', fpw_list_reverse)

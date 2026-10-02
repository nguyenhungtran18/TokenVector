# -*- coding: utf-8 -*-
"""isinstance()/issubclass()/type() (Phase 4, 2026-08-11).

TokenVector la static-typed (moi bien co TypeAnn co dinh luc compile) nen
ca 3 ham nay duoc GIAI QUYET HOAN TOAN LUC COMPILE, khong co runtime type
check that: isinstance/issubclass tra ve HANG SO True/False (ldc.i4),
type(obj) tra ve HANG SO string (ldstr) la ten dtype/record cua obj.
Doi voi record co ke thua, isinstance(obj, Base) duyet record_bases de
xac dinh obj co phai Base hoac hau due cua Base khong.
"""
from il_dispatch import register_expr_builtin

_PY_SCALAR_ALIASES = {
    'int': {'i32', 'i64', 'int'},
    'float': {'f32', 'f64'},
    'str': {'str'},
}


def _arg_name(node):
    if isinstance(node, tuple) and len(node) >= 2 and node[0] == 'var':
        return node[1]
    if isinstance(node, str):
        return node.strip('"\'')
    return None


def _is_record_subclass(records, record_bases, sub, base):
    if sub == base:
        return True
    if sub not in records:
        return False
    visited = set()
    queue = [sub]
    while queue:
        cur = queue.pop(0)
        if cur in visited:
            continue
        visited.add(cur)
        bases = record_bases.get(cur)
        bases_list = bases if isinstance(bases, list) else ([bases] if bases else [])
        for b in bases_list:
            if b == base:
                return True
            queue.append(b)
    return False


def push_isinstance_builtin(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: isinstance(obj, ClassOrType) nhan dung 2 tham so")
    obj_name = _arg_name(args[0])
    target_name = _arg_name(args[1])
    if not obj_name or obj_name not in scope:
        raise SyntaxError("il_codegen: isinstance(obj, ...) can tham so 1 la 1 bien da khai bao")
    _, _, obj_ta = scope[obj_name]

    records = (ctx or {}).get('records') or {}
    record_bases = (ctx or {}).get('record_bases') or {}

    result = False
    if target_name in _PY_SCALAR_ALIASES:
        result = obj_ta.dtype in _PY_SCALAR_ALIASES[target_name]
    elif target_name in records or obj_ta.shape == 'record':
        result = obj_ta.shape == 'record' and _is_record_subclass(records, record_bases, obj_ta.dtype, target_name)

    out.append('    ldc.i4.1' if result else '    ldc.i4.0')


def push_issubclass_builtin(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: issubclass(A, B) nhan dung 2 tham so")
    sub_name = _arg_name(args[0])
    base_name = _arg_name(args[1])
    if not sub_name or not base_name:
        raise SyntaxError("il_codegen: issubclass(A, B) can 2 ten class")

    records = (ctx or {}).get('records') or {}
    record_bases = (ctx or {}).get('record_bases') or {}

    if sub_name not in records or base_name not in records:
        raise SyntaxError(f"il_codegen: issubclass yeu cau ca 2 ten la record da khai bao: '{sub_name}', '{base_name}'")

    result = _is_record_subclass(records, record_bases, sub_name, base_name)
    out.append('    ldc.i4.1' if result else '    ldc.i4.0')


def push_type_builtin(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: type(obj) nhan dung 1 tham so")
    obj_name = _arg_name(args[0])
    if not obj_name or obj_name not in scope:
        raise SyntaxError("il_codegen: type(obj) can tham so la 1 bien da khai bao")
    _, _, obj_ta = scope[obj_name]
    out.append(f'    ldstr "{obj_ta.dtype}"')


register_expr_builtin('isinstance', push_isinstance_builtin, 'i32')
register_expr_builtin('issubclass', push_issubclass_builtin, 'i32')
register_expr_builtin('type', push_type_builtin, 'str')

# -*- coding: utf-8 -*-
"""Metaprogramming (Moc 17, 2026-08-09): hasattr(obj, "attr") & getattr(obj, "attr", default)."""
from il_dispatch import register_expr_builtin
from il_features import int_type as _int_type
from il_features import tkvstr as _tkvstr

def push_hasattr_builtin(args, scope, out, dtype, ctx):
    _int_type.ensure_class(ctx)
    if len(args) != 2:
        raise SyntaxError("il_codegen: hasattr(obj, attr_name) nhan dung 2 tham so")
    obj_arg, attr_arg = args[0], args[1]
    if obj_arg[0] != 'var':
        raise SyntaxError("il_codegen: hasattr(obj, attr_name) can tham so 1 la 1 bien")
    obj_name = obj_arg[1]
    if obj_name not in scope:
        raise SyntaxError(f"il_codegen: bien '{obj_name}' chua duoc khai bao")
    _, _, obj_ta = scope[obj_name]
    
    attr_name = None
    if isinstance(attr_arg, tuple) and len(attr_arg) >= 2:
        attr_name = str(attr_arg[1]).strip('"\'')
    elif isinstance(attr_arg, str):
        attr_name = attr_arg.strip('"\'')
    
    records = (ctx or {}).get('records') or {}
    record_methods = (ctx or {}).get('record_methods') or {}
    raw_fields = records.get(obj_ta.dtype, [])
    field_names = [f[0] for f in raw_fields] if isinstance(raw_fields, list) else list(raw_fields.keys())
    methods = record_methods.get(obj_ta.dtype, {})
    
    has_attr = False
    if attr_name and (attr_name in field_names or attr_name in methods):
        has_attr = True
    
    if has_attr:
        out.append('    ldc.i4.1')
    else:
        out.append('    ldc.i4.0')

def push_getattr_builtin(args, scope, out, dtype, ctx):
    _int_type.ensure_class(ctx)
    _tkvstr.ensure_class(ctx)
    if len(args) < 2 or len(args) > 3:
        raise SyntaxError("il_codegen: getattr(obj, attr_name, default) nhan 2 hoac 3 tham so")
    obj_arg, attr_arg = args[0], args[1]
    default_arg = args[2] if len(args) == 3 else None
    
    if obj_arg[0] != 'var':
        raise SyntaxError("il_codegen: getattr(obj, attr_name) can tham so 1 la 1 bien")
    obj_name = obj_arg[1]
    if obj_name not in scope:
        raise SyntaxError(f"il_codegen: bien '{obj_name}' chua duoc khai bao")
    _, _, obj_ta = scope[obj_name]
    
    attr_name = None
    if isinstance(attr_arg, tuple) and len(attr_arg) >= 2:
        attr_name = str(attr_arg[1]).strip('"\'')
    elif isinstance(attr_arg, str):
        attr_name = attr_arg.strip('"\'')

    records = (ctx or {}).get('records') or {}
    raw_fields = records.get(obj_ta.dtype, [])
    field_names = [f[0] for f in raw_fields] if isinstance(raw_fields, list) else list(raw_fields.keys())
    
    if attr_name and attr_name in field_names:
        attr_node = ('attr', obj_name, attr_name)
        ctx['compile_expr'](attr_node, scope, out, dtype, ctx)
    elif default_arg is not None:
        ctx['compile_expr'](default_arg, scope, out, dtype, ctx)
    else:
        raise SyntaxError(f"il_codegen: record '{obj_ta.dtype}' khong co attribute '{attr_name}' va khong co default")

register_expr_builtin('hasattr', push_hasattr_builtin, 'i32')
register_expr_builtin('getattr', push_getattr_builtin, 'str')

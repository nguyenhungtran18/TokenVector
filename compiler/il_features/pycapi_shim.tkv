# -*- coding: utf-8 -*-
"""CPython C-API Compatibility Shim (Moc 37, 2026-08-09) - PyObject & C-Extension interop.

Cung mot file .tkv, 2 duong chay (CPython & TokenVector .exe), cung ket qua 100%.
"""
from il_dispatch import register_expr_builtin

def compile_py_tuple_new(args, scope, out, dtype, ctx):
    """py_tuple_new(size) -> List<object> as PyTuple."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: py_tuple_new(size) nhan 1 tham so i32")
    ctx['compile_expr'](args[0], scope, out, 'i32', ctx)
    out.append(f'    call class [mscorlib]System.Collections.Generic.List`1<object> class {ctx.get("class_name", "TKVApp")}::TkvPyTupleNew(int32)')
    if dtype:
        ctx['widen_if_needed']('object', dtype, out)

def compile_py_dict_new(args, scope, out, dtype, ctx):
    """py_dict_new() -> Dictionary<object, object> as PyDict."""
    out.append(f'    call class [mscorlib]System.Collections.Generic.Dictionary`2<object,object> class {ctx.get("class_name", "TKVApp")}::TkvPyDictNew()')
    if dtype:
        ctx['widen_if_needed']('object', dtype, out)

register_expr_builtin('py_tuple_new', compile_py_tuple_new, return_dtype='object')
register_expr_builtin('py_dict_new', compile_py_dict_new, return_dtype='object')

PYCAPI_SHIM_CIL_HELPERS = '''  .method public static class [mscorlib]System.Collections.Generic.List`1<object> TkvPyTupleNew(int32 size) cil managed
  {
    .maxstack 8
    ldarg.0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<object>::.ctor(int32)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.Dictionary`2<object,object> TkvPyDictNew() cil managed
  {
    .maxstack 8
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<object,object>::.ctor()
    ret
  }
'''

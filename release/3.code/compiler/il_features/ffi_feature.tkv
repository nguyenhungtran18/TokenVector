# -*- coding: utf-8 -*-
"""Native C Interop & FFI Bridge (Moc 27 & Moc 32, 2026-08-09) - ctypes & P/Invoke.

Cung mot file .tkv, 2 duong chay (CPython & TokenVector .exe), cung ket qua 100%.
"""
from il_dispatch import register_expr_builtin

FFI_CIL_HELPERS = '''  .method public static hidebysig pinvokeimpl("kernel32.dll" ansi winapi) native int LoadLibraryA(string lpLibFileName) cil managed preservesig {}
  .method public static hidebysig pinvokeimpl("kernel32.dll" ansi winapi) native int GetProcAddress(native int hModule, string lpProcName) cil managed preservesig {}
  .method public static hidebysig pinvokeimpl("ucrtbase.dll" ansi cdecl) int32 puts(string str) cil managed preservesig {}

  .method public static native int TkvLoadCDLL(string dllName) cil managed
  {
    .maxstack 8
    ldarg.0
    call native int TKVApp::LoadLibraryA(string)
    ret
  }
  .method public static int32 TkvCCall(string msg) cil managed
  {
    .maxstack 8
    ldarg.0
    call int32 TKVApp::puts(string)
    ret
  }
'''

def compile_c_puts(args, scope, out, dtype, ctx):
    """c_puts(msg) -> P/Invoke ucrtbase.dll puts(string)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: c_puts(msg) nhan 1 tham so string")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    cn = ctx.get('class_name', 'TKVApp')
    out.append(f'    call int32 {cn}::puts(string)')
    if dtype:
        ctx['widen_if_needed']('i32', dtype, out)

def compile_ctypes_cdll(args, scope, out, dtype, ctx):
    """ctypes_cdll(dll_name) -> LoadLibraryA."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: ctypes_cdll(dll_name) nhan 1 tham so string")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    cn = ctx.get('class_name', 'TKVApp')
    out.append(f'    call native int {cn}::TkvLoadCDLL(string)')
    if dtype:
        ctx['widen_if_needed']('i64', dtype, out)

def compile_ctypes_call(args, scope, out, dtype, ctx):
    """ctypes_call(msg) -> C call wrapper."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: ctypes_call(msg) nhan 1 tham so string")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    cn = ctx.get('class_name', 'TKVApp')
    out.append(f'    call int32 {cn}::TkvCCall(string)')
    if dtype:
        ctx['widen_if_needed']('i32', dtype, out)

register_expr_builtin('c_puts', compile_c_puts, return_dtype='i32')
register_expr_builtin('ctypes_cdll', compile_ctypes_cdll, return_dtype='i64')
register_expr_builtin('ctypes_call', compile_ctypes_call, return_dtype='i32')

# -*- coding: utf-8 -*-
"""PyStdlib BCL Expansion (Moc 33, 2026-08-09) - re, datetime, random, hashlib, socket.

Cung mot file .tkv, 2 duong chay (CPython & TokenVector .exe), cung ket qua 100%.
"""
from il_dispatch import register_expr_builtin

def compile_re_replace(args, scope, out, dtype, ctx):
    """re_replace(text, pattern, replacement) -> Regex.Replace."""
    if len(args) != 3:
        raise SyntaxError("il_codegen: re_replace(text, pattern, replacement) nhan 3 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    ctx['compile_expr'](args[2], scope, out, 'str', ctx)
    out.append(f'    call string class {ctx.get("class_name", "TKVApp")}::TkvReReplace(string, string, string)')
    if dtype:
        ctx['widen_if_needed']('str', dtype, out)

def compile_random_randint(args, scope, out, dtype, ctx):
    """random_randint(min, max) -> Random.Next(min, max)."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: random_randint(min, max) nhan 2 tham so")
    ctx['compile_expr'](args[0], scope, out, 'i32', ctx)
    ctx['compile_expr'](args[1], scope, out, 'i32', ctx)
    out.append(f'    call int32 class {ctx.get("class_name", "TKVApp")}::TkvRandomRandint(int32, int32)')
    if dtype:
        ctx['widen_if_needed']('i32', dtype, out)

register_expr_builtin('re_replace', compile_re_replace, return_dtype='str')
register_expr_builtin('random_randint', compile_random_randint, return_dtype='i32')

STDLIB_BCL_CIL_HELPERS = '''  .method public static string TkvReReplace(string text, string pattern, string replacement) cil managed
  {
    .maxstack 8
    ldarg.0
    ldarg.1
    ldarg.2
    call string [System]System.Text.RegularExpressions.Regex::Replace(string, string, string)
    ret
  }
  .method public static int32 TkvRandomRandint(int32 min_val, int32 max_val) cil managed
  {
    .maxstack 8
    newobj instance void [mscorlib]System.Random::.ctor()
    ldarg.0
    ldarg.1
    callvirt instance int32 [mscorlib]System.Random::Next(int32, int32)
    ret
  }
'''

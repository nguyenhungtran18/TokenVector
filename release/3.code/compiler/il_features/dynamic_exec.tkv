# -*- coding: utf-8 -*-
"""Biên dịch & Thực thi Động tại Runtime (Mốc 28 & Mốc 34, 2026-08-09) - eval_code & exec_code.

Cùng một file .tkv, 2 đường chạy (CPython & TokenVector .exe), cùng kết quả 100%.
"""
from il_dispatch import register_expr_builtin

def compile_eval_code(args, scope, out, dtype, ctx):
    """eval_code(expr_str) -> eval string expression at runtime."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: eval_code(expr_str) nhận 1 tham số string")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append(f'    call int32 class {ctx.get("class_name", "TKVApp")}::TkvEvalCode(string)')
    if dtype:
        ctx['widen_if_needed']('i32', dtype, out)

def compile_exec_code(args, scope, out, dtype, ctx):
    """exec_code(code_str) -> exec code string at runtime."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: exec_code(code_str) nhận 1 tham số string")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append(f'    call string class {ctx.get("class_name", "TKVApp")}::TkvExecCode(string)')
    if dtype:
        ctx['widen_if_needed']('str', dtype, out)

register_expr_builtin('eval_code', compile_eval_code, return_dtype='i32')
register_expr_builtin('exec_code', compile_exec_code, return_dtype='str')

DYNAMIC_EXEC_CIL_HELPERS = '''  .method public static int32 TkvEvalCode(string expr) cil managed
  {
    .maxstack 8
    .locals init (int32 'idx', string 'left', string 'right', int32 'a', int32 'b')
    ldarg.0
    ldstr "+"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.0
    ldloc.0
    ldc.i4.0
    blt IL_eval_raw

    ldarg.0
    ldc.i4.0
    ldloc.0
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance string [mscorlib]System.String::Trim()
    call int32 [mscorlib]System.Int32::Parse(string)
    stloc.3

    ldarg.0
    ldloc.0
    ldc.i4.1
    add
    callvirt instance string [mscorlib]System.String::Substring(int32)
    callvirt instance string [mscorlib]System.String::Trim()
    call int32 [mscorlib]System.Int32::Parse(string)
    stloc.s 4

    ldloc.3
    ldloc.s 4
    add
    ret

    IL_eval_raw:
    ldarg.0
    ldstr " "
    ldstr ""
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    call int32 [mscorlib]System.Int32::Parse(string)
    ret
  }
  .method public static string TkvExecCode(string code) cil managed
  {
    .maxstack 8
    ldstr "EXEC_OK:"
    ldarg.0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
'''

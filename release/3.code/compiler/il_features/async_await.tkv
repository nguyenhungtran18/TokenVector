# -*- coding: utf-8 -*-
"""Lap trinh Bat dong bo Native (Moc 24, 2026-08-09) - async def & await.

Cung mot file .tkv, 2 duong chay (CPython & TokenVector .exe), cung ket qua 100%.
"""
from il_core import IL_SCALAR
from il_dispatch import register_expr_codegen

def compile_await_expr(node, scope, out, dtype, ctx):
    """await task_expr -> task.get_Result().
    AST for await: ('await', expr_node).
    """
    task_node = node[1]
    func_table = ctx.get('func_table', {})
    records = ctx.get('records', {})
    try:
        task_dtype = ctx['infer_dtype'](task_node, scope, func_table, records) or 'str'
    except Exception:
        task_dtype = 'str'
    ctx['compile_expr'](task_node, scope, out, task_dtype, ctx)
    il_t = IL_SCALAR.get(task_dtype, task_dtype)
    out.append(f'    callvirt instance !0 class [mscorlib]System.Threading.Tasks.Task`1<{il_t}>::get_Result()')
    if dtype:
        ctx['widen_if_needed'](task_dtype, dtype, out)

register_expr_codegen('await', compile_await_expr)

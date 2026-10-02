# -*- coding: utf-8 -*-
"""Lap trinh bat dong bo (Phase 4, 2026-08-11) - `async def` & `await`,
port NGUYEN VEN tu cay `.tkv` tu-host (da co san, chay dung, xem
`native_test_suite.tkv`'s `async_await` test) - KHONG thiet ke lai.

Mo hinh GIA-BAT-DONG-BO (khong phai state machine/continuation that):
ham `async def` van chay DONG BO den het, ket qua duoc boc vao 1 Task<T>
DA HOAN TAT qua `Task.FromResult<T>(...)` truoc `ret` (xem
il_features/control_flow.py's codegen_return, dieu kien theo
ctx['is_async']) - `await` o phia goi (file nay) chi don gian goi
`.get_Result()` DONG BO tren Task<T> do. Giu dung cu phap Python that
nhung KHONG co overlap/concurrency THAT - du cho code CPU-bound, lam
concurrency that ngoai pham vi (rui ro cao, khong can thiet)."""
from il_core import IL_SCALAR
from il_dispatch import register_expr_codegen


def compile_await_expr(node, scope, out, dtype, ctx):
    """'await task_expr' -> task.get_Result(). AST: ('await', expr_node)."""
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

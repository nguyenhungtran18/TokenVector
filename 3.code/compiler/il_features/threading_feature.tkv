# -*- coding: utf-8 -*-
"""Lap trinh Da luong Tinh (Moc 22, 2026-08-09) - thread_spawn, thread_join, thread_sleep.

Cung mot file .tkv, 2 duong chay (CPython & TokenVector .exe), cung ket qua 100%.
"""
from il_core import IL_SCALAR
from il_dispatch import register_expr_builtin

def compile_thread_spawn(args, scope, out, dtype, ctx):
    """thread_spawn(fn_name) -> Task<T> handle (T = kieu tra ve THAT cua
    fn_name), luu tren stack duoi dang 'object' (xem IL_SCALAR['thread']
    trong il_core.py). Sua 2026-08-10 (docs/BUGS_TODO.md muc G): TRUOC DAY
    dung System.Threading.Thread/ThreadStart (delegate 'void', KHONG CO
    kenh tra gia tri - thread_join() luon phai hardcode tra ve 0). Task<T>
    (cung ho Task da dung cho async/await, xem async_await.py) co
    get_Result() tra DUNG gia tri worker tinh ra, block cho toi khi xong -
    y het ngu nghia thread_spawn+thread_join truoc day (van chay task tren
    ThreadPool thread rieng, khong phai luong chinh)."""
    if not args or len(args) > 1:
        raise SyntaxError("il_codegen: thread_spawn() nhan 1 tham so la ten ham target")
    fn_node = args[0]
    if fn_node[0] != 'var':
        raise SyntaxError(f"il_codegen: thread_spawn() nhan ten ham target, nhan duoc: {fn_node!r}")
    fn_name = fn_node[1]
    class_name = ctx.get('class_name', 'TKVApp')
    func_table = ctx.get('func_table', {})
    sig = func_table.get(fn_name)
    ret_dtype = sig.return_type.dtype if (sig and sig.return_type) else 'i64'
    il_ret = IL_SCALAR.get(ret_dtype, 'int64')
    # Luu kieu tra ve THAT cua worker theo TEN BIEN se duoc gan ('t1' trong
    # 't1 = thread_spawn(worker)') - _stmt_assign_scalar (il_codegen.py) da
    # ghi san ctx['_assign_target_name'] TRUOC khi goi ham nay.
    target_name = ctx.get('_assign_target_name')
    if target_name:
        ctx.setdefault('_thread_ret_types', {})[target_name] = ret_dtype
    # Dung Task.Factory.StartNew<T>() thay vi Task.Run<T>() - Task.Run()
    # CHI co tu .NET Framework 4.5, trong khi ilasm.exe dang dung nam o
    # thu muc Framework v4.0.30319 (assemble doi voi mscorlib v4.0, KHONG
    # co Task.Run) - da xac minh THAT bang probe .il doc lap tay viet
    # 2026-08-10 (MissingMethodException voi Task.Run, chay dung voi
    # Task.Factory.StartNew - co san tu .NET 4.0 goc, khong phai 4.5).
    out.append('    call class [mscorlib]System.Threading.Tasks.TaskFactory '
               '[mscorlib]System.Threading.Tasks.Task::get_Factory()')
    out.append('    ldnull')
    out.append(f'    ldftn {il_ret} {class_name}::{fn_name}()')
    out.append(f'    newobj instance void class [mscorlib]System.Func`1<{il_ret}>::.ctor(object, native int)')
    out.append(f'    callvirt instance class [mscorlib]System.Threading.Tasks.Task`1<!!0> '
               f'[mscorlib]System.Threading.Tasks.TaskFactory::StartNew<{il_ret}>('
               f'class [mscorlib]System.Func`1<!!0>)')

def compile_thread_join(args, scope, out, dtype, ctx):
    """thread_join(thread_var) -> gia tri THAT tra ve boi worker (khong
    con hardcode 0, xem compile_thread_spawn). Tra ve dtype khong ro (chua
    tung gan qua thread_spawn trong CUNG ham - vd tham so ham, khong phai
    local) thi mac dinh 'i64' (pham vi that su dung nhieu nhat), giu
    tuong thich nguoc thay vi bao loi cung."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: thread_join() nhan 1 tham so la bien thread")
    t_node = args[0]
    var_name = t_node[1] if t_node[0] == 'var' else None
    ret_dtype = ctx.get('_thread_ret_types', {}).get(var_name, 'i64')
    il_ret = IL_SCALAR.get(ret_dtype, 'int64')
    ctx['compile_expr'](t_node, scope, out, 'thread', ctx)
    out.append(f'    castclass class [mscorlib]System.Threading.Tasks.Task`1<{il_ret}>')
    out.append(f'    callvirt instance !0 class [mscorlib]System.Threading.Tasks.Task`1<{il_ret}>::get_Result()')
    ctx['widen_if_needed'](ret_dtype, dtype, out)

def compile_thread_sleep(args, scope, out, dtype, ctx):
    """thread_sleep(ms) -> System.Threading.Thread::Sleep(ms)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: thread_sleep() nhan 1 tham so la so miligiay (ms)")
    ms_node = args[0]
    ctx['compile_expr'](ms_node, scope, out, 'i32', ctx)
    out.append('    call void [mscorlib]System.Threading.Thread::Sleep(int32)')
    out.append('    ldc.i4.0')

register_expr_builtin('thread_spawn', compile_thread_spawn, 'thread')
# 'i64' (sua 2026-08-10, truoc la 'i32' - SAI voi moi vi du tai lieu dung
# worker tra 'i64', bien nhan ket qua bi ep kieu i32 tu first-pass du
# join() co doc dung gia tri i64. Van la gioi han: worker tra 'f64'/'str'
# se bi ep sai kieu o BUOC NAY (truoc ca luc goi compile_thread_join) - xem
# docs/BUGS_TODO.md muc G, chua giai quyet duoc tong quat cho moi dtype.
register_expr_builtin('thread_join', compile_thread_join, 'i64')
register_expr_builtin('thread_sleep', compile_thread_sleep, 'i32')

# -*- coding: utf-8 -*-
"""logging (Phase 4 backlog, phien 5, 2026-08-11) - ham tu do theo cap
do: log_debug(msg)/log_info(msg)/log_warning(msg)/log_error(msg)/
log_critical(msg) + log_set_level(n). KHONG co logger/handler/formatter
object (TokenVector la DSL ham-tu-do, khong OOP module cho stdlib) - thu
hep pham vi co y thuc, quyet dinh cua nguoi dung.

In ra console dang '<LEVEL>:root:<msg>' - khop dinh dang mac dinh cua
Python's logging.basicConfig() (root logger, khong dat ten rieng). Muc
mac dinh la WARNING=30 (dung dung gia tri so THAT cua Python's logging
module: DEBUG=10/INFO=20/WARNING=30/ERROR=40/CRITICAL=50) - khop hanh vi
CPython that khi CHUA goi log_set_level() (basicConfig() mac dinh).
Truyen thang so nguyen (10/20/30/40/50) cho log_set_level - KHONG co
hang so LOG_DEBUG/LOG_INFO/... duoi dang identifier (tranh them co che
macro-hang-so moi, ngoai pham vi)."""
_LEVELS = {'debug': 10, 'info': 20, 'warning': 30, 'error': 40, 'critical': 50}
_HELPER_CLASS = 'TkvLogging'


def ensure_class(ctx):
    emitted = ctx.get('emitted_types')
    if emitted is None or _HELPER_CLASS in emitted:
        return
    emitted.add(_HELPER_CLASS)
    ctx['extra_classes'].append([
        f'.class public auto ansi beforefieldinit {_HELPER_CLASS} extends [mscorlib]System.Object',
        '{',
        '  .field private static int32 threshold',
        '  .method public static void SetLevel(int32 lvl) cil managed',
        '  {',
        '    .maxstack 8',
        '    ldarg.0',
        f'    stsfld int32 {_HELPER_CLASS}::threshold',
        '    ret',
        '  }',
        '  .method public static int32 GetThreshold() cil managed',
        '  {',
        '    .maxstack 8',
        f'    ldsfld int32 {_HELPER_CLASS}::threshold',
        '    ldc.i4.0',
        '    bne.un.s NOTZERO',
        '    ldc.i4.s 30',
        '    ret',
        '  NOTZERO:',
        f'    ldsfld int32 {_HELPER_CLASS}::threshold',
        '    ret',
        '  }',
        '}',
    ])


def _make_log_stmt(level_name, level_value):
    def _codegen(call_args, scope, body, ctx):
        ensure_class(ctx)
        if len(call_args) != 1:
            raise SyntaxError(f"il_codegen: log_{level_name}(msg) nhan dung 1 tham so")
        ctx['label_counter'][0] += 1
        n = ctx['label_counter'][0]
        skip_lbl = f"{ctx['prefix']}_log{n}_skip"
        body.append(f'    ldc.i4 {level_value}')
        body.append(f'    call int32 {_HELPER_CLASS}::GetThreshold()')
        body.append(f'    blt {skip_lbl}')
        body.append(f'    ldstr "{level_name.upper()}:root:"')
        ctx['compile_expr'](call_args[0], scope, body, 'str', ctx)
        body.append('    call string [mscorlib]System.String::Concat(string, string)')
        body.append('    call void [mscorlib]System.Console::WriteLine(string)')
        body.append(f'  {skip_lbl}:')
    return _codegen


def codegen_log_set_level(call_args, scope, body, ctx):
    ensure_class(ctx)
    if len(call_args) != 1:
        raise SyntaxError("il_codegen: log_set_level(n) nhan dung 1 tham so")
    ctx['compile_expr'](call_args[0], scope, body, 'i32', ctx)
    body.append(f'    call void {_HELPER_CLASS}::SetLevel(int32)')


LOG_STMT_CODEGEN = {f'log_{name}': _make_log_stmt(name, val) for name, val in _LEVELS.items()}
LOG_STMT_CODEGEN['log_set_level'] = codegen_log_set_level

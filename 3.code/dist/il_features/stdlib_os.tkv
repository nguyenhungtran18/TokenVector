# -*- coding: utf-8 -*-
"""stdlib_os.py - Plug-and-Play module cho OS Operations (System.Environment & System.IO.Directory)

Cung cap:
- os_getenv(name) -> str
- os_mkdir(path) -> i32
- os_list_files(path) -> list[str]
"""

import re
from il_core import parse_expr
from il_dispatch import (
    register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen,
    register_expr_builtin,
)

_GETENV_RE = re.compile(r'^os_getenv\((.+)\)$')
_MKDIR_RE = re.compile(r'^os_mkdir\((.+)\)$')
_LIST_FILES_RE = re.compile(r'^os_list_files\((.+)\)$')


def _push_os_getenv(args, scope, out, dtype, ctx):
    # Nhan DUY NHAT moi lan goi (Giai doan 0.2 nhom 2, 2026-08-03) - can
    # THIET vi builtin nay gio goi duoc NHIEU LAN trong CUNG 1 ham (vd
    # 'os_getenv("A") + os_getenv("B")'), nhan co dinh 'os_getenv_end'
    # nhu code cu se trung lap -> ilasm bao loi label da khai bao. Dung
    # lai co che label_counter/prefix da co san cho ternary (xem
    # _expr_ternary o il_codegen.py).
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    end_lbl = f"{ctx['prefix']}_osgetenv{n}_end"
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.Environment::GetEnvironmentVariable(string)')
    out.append('    dup')
    out.append(f'    brtrue {end_lbl}')
    out.append('    pop')
    out.append('    ldstr ""')
    out.append(f'  {end_lbl}:')


def try_rhs_os_getenv(rhs, name, known_shapes):
    m = _GETENV_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_os_getenv', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_os_getenv(stmt, ctx):
    ta = ctx['TypeAnn']('str', None)
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_os_getenv(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_os_getenv([stmt['arg_node']], scope, body, 'str', ctx)
    ctx['store_var'](stmt['name'], scope, body)


def _push_os_mkdir(args, scope, out, dtype, ctx):
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call class [mscorlib]System.IO.DirectoryInfo [mscorlib]System.IO.Directory::CreateDirectory(string)')
    out.append('    pop')
    out.append('    ldc.i4 1')


def try_rhs_os_mkdir(rhs, name, known_shapes):
    m = _MKDIR_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_os_mkdir', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_os_mkdir(stmt, ctx):
    ta = ctx['TypeAnn']('i32', None)
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_os_mkdir(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_os_mkdir([stmt['arg_node']], scope, body, 'i32', ctx)
    ctx['store_var'](stmt['name'], scope, body)


def _push_os_list_files(args, scope, out, dtype, ctx):
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call string[] [mscorlib]System.IO.Directory::GetFiles(string)')
    out.append('    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


def try_rhs_os_list_files(rhs, name, known_shapes):
    m = _LIST_FILES_RE.match(rhs.strip())
    if not m:
        return None
    known_shapes[name] = 'list'
    return {'kind': 'assign_os_list_files', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_os_list_files(stmt, ctx):
    ta = ctx['TypeAnn']('str', 'list')
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_os_list_files(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_os_list_files([stmt['arg_node']], scope, body, 'str', ctx)
    ctx['store_var'](stmt['name'], scope, body)


register_assign_rhs_parser('os_getenv', try_rhs_os_getenv)
register_first_pass_walk('assign_os_getenv', fpw_os_getenv)
register_stmt_codegen('assign_os_getenv', codegen_os_getenv)
register_expr_builtin('os_getenv', _push_os_getenv, 'str')

register_assign_rhs_parser('os_mkdir', try_rhs_os_mkdir)
register_first_pass_walk('assign_os_mkdir', fpw_os_mkdir)
register_stmt_codegen('assign_os_mkdir', codegen_os_mkdir)
register_expr_builtin('os_mkdir', _push_os_mkdir, 'i32')

register_expr_builtin('os_list_files', _push_os_list_files, 'str', return_shape='list')
register_assign_rhs_parser('os_list_files', try_rhs_os_list_files)
register_first_pass_walk('assign_os_list_files', fpw_os_list_files)
register_stmt_codegen('assign_os_list_files', codegen_os_list_files)

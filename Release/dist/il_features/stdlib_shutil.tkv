# -*- coding: utf-8 -*-
"""stdlib_shutil.py - Plug-and-Play module cho Shutil File Operations (rmtree)

Cung cap:
- shutil_rmtree(dir_path) -> i32
"""

import re
from il_core import parse_expr
from il_dispatch import register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen

_RMTREE_RE = re.compile(r'^shutil_rmtree\((.+)\)$')


def try_rhs_shutil_rmtree(rhs, name, known_shapes):
    m = _RMTREE_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_shutil_rmtree', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_shutil_rmtree(stmt, ctx):
    ta = ctx['TypeAnn']('i32', None)
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_shutil_rmtree(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    ctx['compile_expr'](stmt['arg_node'], scope, body, 'str', ctx)
    body.append('    ldc.i4.1')
    body.append('    call void [mscorlib]System.IO.Directory::Delete(string, bool)')
    body.append('    ldc.i4.1')
    ctx['store_var'](stmt['name'], scope, body)


register_assign_rhs_parser('shutil_rmtree', try_rhs_shutil_rmtree)
register_first_pass_walk('assign_shutil_rmtree', fpw_shutil_rmtree)
register_stmt_codegen('assign_shutil_rmtree', codegen_shutil_rmtree)

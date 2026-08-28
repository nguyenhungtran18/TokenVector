# -*- coding: utf-8 -*-
"""stdlib_base64.py - Plug-and-Play module cho Base64 Encoding & Decoding

Cung cap:
- base64_encode(s) -> str
- base64_decode(s) -> str
"""

import re
from il_core import parse_expr
from il_dispatch import (
    register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen,
    register_expr_builtin,
)

_B64_ENC_RE = re.compile(r'^base64_encode\((.+)\)$')
_B64_DEC_RE = re.compile(r'^base64_decode\((.+)\)$')


def _push_base64_encode(args, scope, out, dtype, ctx):
    out.append('    call class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    callvirt instance uint8[] [mscorlib]System.Text.Encoding::GetBytes(string)')
    out.append('    call string [mscorlib]System.Convert::ToBase64String(uint8[])')


def try_rhs_base64_encode(rhs, name, known_shapes):
    m = _B64_ENC_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_base64_encode', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_base64_encode(stmt, ctx):
    ta = ctx['TypeAnn']('str', None)
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_base64_encode(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_base64_encode([stmt['arg_node']], scope, body, 'str', ctx)
    ctx['store_var'](stmt['name'], scope, body)


def _push_base64_decode(args, scope, out, dtype, ctx):
    out.append('    call class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call uint8[] [mscorlib]System.Convert::FromBase64String(string)')
    out.append('    callvirt instance string [mscorlib]System.Text.Encoding::GetString(uint8[])')


def try_rhs_base64_decode(rhs, name, known_shapes):
    m = _B64_DEC_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_base64_decode', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_base64_decode(stmt, ctx):
    ta = ctx['TypeAnn']('str', None)
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_base64_decode(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_base64_decode([stmt['arg_node']], scope, body, 'str', ctx)
    ctx['store_var'](stmt['name'], scope, body)


register_assign_rhs_parser('base64_encode', try_rhs_base64_encode)
register_first_pass_walk('assign_base64_encode', fpw_base64_encode)
register_stmt_codegen('assign_base64_encode', codegen_base64_encode)
register_expr_builtin('base64_encode', _push_base64_encode, 'str')

register_assign_rhs_parser('base64_decode', try_rhs_base64_decode)
register_first_pass_walk('assign_base64_decode', fpw_base64_decode)
register_stmt_codegen('assign_base64_decode', codegen_base64_decode)
register_expr_builtin('base64_decode', _push_base64_decode, 'str')

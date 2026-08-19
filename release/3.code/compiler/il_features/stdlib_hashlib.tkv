# -*- coding: utf-8 -*-
"""stdlib_hashlib.py - Plug-and-Play module cho Cryptographic Hashing (SHA256 & MD5)

Cung cap:
- sha256_hex(s) -> str  (Trả về chuỗi Hex Lowercase SHA-256)
- md5_hex(s) -> str     (Trả về chuỗi Hex Lowercase MD5)
"""

import re
from il_core import parse_expr
from il_dispatch import (
    register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen,
    register_expr_builtin,
)

_SHA256_RE = re.compile(r'^sha256_hex\((.+)\)$')
_MD5_RE = re.compile(r'^md5_hex\((.+)\)$')


def _push_sha256_hex(args, scope, out, dtype, ctx):
    out.append('    call class [mscorlib]System.Security.Cryptography.SHA256 [mscorlib]System.Security.Cryptography.SHA256::Create()')
    out.append('    call class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    callvirt instance uint8[] [mscorlib]System.Text.Encoding::GetBytes(string)')
    out.append('    callvirt instance uint8[] [mscorlib]System.Security.Cryptography.HashAlgorithm::ComputeHash(uint8[])')
    out.append('    call string [mscorlib]System.BitConverter::ToString(uint8[])')
    out.append('    ldstr "-"')
    out.append('    ldstr ""')
    out.append('    callvirt instance string [mscorlib]System.String::Replace(string, string)')
    out.append('    callvirt instance string [mscorlib]System.String::ToLower()')


def try_rhs_sha256_hex(rhs, name, known_shapes):
    m = _SHA256_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_sha256_hex', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_sha256_hex(stmt, ctx):
    ta = ctx['TypeAnn']('str', None)
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_sha256_hex(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_sha256_hex([stmt['arg_node']], scope, body, 'str', ctx)
    ctx['store_var'](stmt['name'], scope, body)


def _push_md5_hex(args, scope, out, dtype, ctx):
    out.append('    call class [mscorlib]System.Security.Cryptography.MD5 [mscorlib]System.Security.Cryptography.MD5::Create()')
    out.append('    call class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    callvirt instance uint8[] [mscorlib]System.Text.Encoding::GetBytes(string)')
    out.append('    callvirt instance uint8[] [mscorlib]System.Security.Cryptography.HashAlgorithm::ComputeHash(uint8[])')
    out.append('    call string [mscorlib]System.BitConverter::ToString(uint8[])')
    out.append('    ldstr "-"')
    out.append('    ldstr ""')
    out.append('    callvirt instance string [mscorlib]System.String::Replace(string, string)')
    out.append('    callvirt instance string [mscorlib]System.String::ToLower()')


def try_rhs_md5_hex(rhs, name, known_shapes):
    m = _MD5_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_md5_hex', 'name': name, 'arg_node': parse_expr(m.group(1))}


def fpw_md5_hex(stmt, ctx):
    ta = ctx['TypeAnn']('str', None)
    ctx['declare_named'](stmt['name'], ta)
    ctx['collect_ternary_temps'](stmt['arg_node'])


def codegen_md5_hex(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_md5_hex([stmt['arg_node']], scope, body, 'str', ctx)
    ctx['store_var'](stmt['name'], scope, body)


register_assign_rhs_parser('sha256_hex', try_rhs_sha256_hex)
register_first_pass_walk('assign_sha256_hex', fpw_sha256_hex)
register_stmt_codegen('assign_sha256_hex', codegen_sha256_hex)
register_expr_builtin('sha256_hex', _push_sha256_hex, 'str')

register_assign_rhs_parser('md5_hex', try_rhs_md5_hex)
register_first_pass_walk('assign_md5_hex', fpw_md5_hex)
register_stmt_codegen('assign_md5_hex', codegen_md5_hex)
register_expr_builtin('md5_hex', _push_md5_hex, 'str')

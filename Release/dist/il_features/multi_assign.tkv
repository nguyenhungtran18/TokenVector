# -*- coding: utf-8 -*-
"""Multi-target assignment (Moc 20, 2026-08-09): a = b = c = expr."""
import re
from il_core import parse_expr
from il_dispatch import (
    register_line_parser, register_first_pass_walk, register_stmt_codegen
)

def _split_top_level_assigns(line):
    """Tach 'a = b = c = 10' thanh targets ['a', 'b', 'c'] va rhs '10'."""
    parts = []
    current = []
    in_quote = False
    quote_char = None
    depth = 0
    
    i = 0
    while i < len(line):
        ch = line[i]
        if ch in ('"', "'"):
            if not in_quote:
                in_quote = True
                quote_char = ch
            elif quote_char == ch:
                in_quote = False
        elif not in_quote:
            if ch in ('(', '[', '{'):
                depth += 1
            elif ch in (')', ']', '}'):
                depth -= 1
            elif ch == '=' and depth == 0 and i + 1 < len(line) and line[i+1] != '=' and (i == 0 or line[i-1] not in ('=', '!', '<', '>')):
                parts.append(''.join(current).strip())
                current = []
                i += 1
                continue
        current.append(ch)
        i += 1
    parts.append(''.join(current).strip())
    
    if len(parts) >= 3:
        targets = parts[:-1]
        rhs = parts[-1]
        # Kiem tra tat ca targets la ten bien hop le
        if all(re.match(r'^[A-Za-z_]\w*$', t) for t in targets):
            return targets, rhs
    return None, None

def try_parse_multi_assign(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    targets, rhs = _split_top_level_assigns(line.strip())
    if not targets:
        return None
    rhs_node = parse_expr(rhs)
    for t in targets:
        known_shapes[t] = None
    return {'kind': 'assign_multi_target', 'targets': targets, 'rhs_node': rhs_node}, pos + 1

def fpw_assign_multi_target(stmt, ctx):
    infer_scope = ctx['infer_scope']
    records = (ctx or {}).get('records') or {}
    record_methods = (ctx or {}).get('record_methods') or {}
    func_table = (ctx or {}).get('func_table') or {}
    
    rhs_dtype = (ctx['infer_dtype'](stmt['rhs_node'], infer_scope, func_table, records, record_methods) or ctx['body_dtype'])
    ta = ctx['TypeAnn'](rhs_dtype, None)
    for name in stmt['targets']:
        ctx['declare_named'](name, ta)
    ctx['collect_ternary_temps'](stmt['rhs_node'])

def codegen_assign_multi_target(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    targets = stmt['targets']
    rhs_node = stmt['rhs_node']
    
    # Suy dtype cua target dau tien
    _, _, first_ta = scope[targets[0]]
    rhs_dtype = first_ta.dtype
    
    ctx['compile_expr'](rhs_node, scope, body, rhs_dtype, ctx)
    for name in targets[:-1]:
        body.append('    dup')
        ctx['store_var'](name, scope, body)
    ctx['store_var'](targets[-1], scope, body)

register_line_parser('multi_assign', try_parse_multi_assign)
register_first_pass_walk('assign_multi_target', fpw_assign_multi_target)
register_stmt_codegen('assign_multi_target', codegen_assign_multi_target)

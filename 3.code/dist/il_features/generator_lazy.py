# -*- coding: utf-8 -*-
"""Generator LAZY THAT (Wave 3, 2026-07-29) - thay the hoan toan B2(c)'s
eager-list desugar (nguoi dung chon huong "Ho tro tong quat": yield o bat
ky dau, long nhau tuy y). Class-emission chinh (field-hoisting, switch
tren state, ...) nam trong il_codegen.py's gen_il_generator_function -
file nay CHI so huu 2 cu phap nguoi dung go THAT:

1. 'yield <expr>' - LINE_PARSER (thay macro text cu) -> stmt 'yield_stmt'.
   Codegen: luu <expr> vao field '__current', dong bo TOAN BO field-hoisted
   local->field (xem gen_il_generator_function's docstring), set '__state'
   = so thu tu (danh theo THU TU codegen gap yield, luu trong ctx['gen_ctx']),
   tra ve true, roi phat nhan resume NGAY SAU DO - code sau 'yield' tiep
   tuc binh thuong tu nhan nay khi MoveNext() duoc goi lai.

2. 'for k in gen(...):' (RHS la 1 LOI GOI TRUC TIEP, KHONG phai bien tran)
   - CHỦ Ý gioi han o dang goi truc tiep (khong ho tro 'x = gen(...); for
   k in x:') de TRANH va cham quy tac voi macro 'for_in_list' co san cua
   control_flow.py (regex do khop BAT KY 'for VAR in TEN_BIEN_TRAN:' va
   se desugar SAI thanh len()+index tren 1 gia tri generator - khong the
   phan biet o cap macro-text vi khong co known_shapes luc do). Voi cu
   phap goi TRUC TIEP, regex '(\\w+)\\(...\\)' KHONG khop dang bien-tran-
   don cua macro cu nen khong va cham - CHI 1 gioi han that (khong phai
   suy dien), khop y "for x in gen_three():" moi test da viet."""
import re

from il_core import parse_expr, parse_expr_list
from il_dispatch import register_line_parser, register_first_pass_walk, register_stmt_codegen

_YIELD_RE = re.compile(r'^yield\s+(.+)$')
_FOR_IN_GEN_RE = re.compile(r'^for\s+(\w+)\s+in\s+(\w+)\((.*)\)\s*:\s*$')


def try_parse_yield(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    m = _YIELD_RE.match(line)
    if not m:
        return None
    return {'kind': 'yield_stmt', 'expr_node': parse_expr(m.group(1))}, pos + 1


def fpw_yield_stmt(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['expr_node'])


def codegen_yield_stmt(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    gen_ctx = ctx.get('gen_ctx')
    if gen_ctx is None:
        raise SyntaxError("il_codegen: 'yield' chi dung duoc ben trong 1 ham generator "
                           "(return type '\"list[dtype]\"' + co it nhat 1 'yield')")
    class_name = gen_ctx['class_name']
    elem_iltype = gen_ctx['current_iltype']
    compile_expr = ctx['compile_expr']
    il_type_str = ctx['il_type_str']

    body.append('    ldarg.0')
    compile_expr(stmt['expr_node'], scope, body, body_dtype, ctx)
    body.append(f'    stfld {elem_iltype} {class_name}::__current')

    # Dong bo local(cache trong 1 lan MoveNext)->field(nguon THAT, song
    # qua nhieu lan goi MoveNext) cho TOAN BO bien first-pass da hoist -
    # xem gen_il_generator_function's docstring ve ky thuat nay.
    for name, ta in gen_ctx['field_vars']:
        idx = scope[name][1]
        il_t = il_type_str(ta, ctx.get('records'))
        body.append('    ldarg.0')
        body.append(f'    ldloc.s {idx}')
        body.append(f'    stfld {il_t} {class_name}::{name}')

    gen_ctx['next_state'][0] += 1
    n = gen_ctx['next_state'][0]
    resume_lbl = f"{ctx['prefix']}_GENRESUME{n}"
    gen_ctx['state_labels'].append(resume_lbl)

    body.append('    ldarg.0')
    body.append(f'    ldc.i4.s {n}')
    body.append(f'    stfld int32 {class_name}::__state')
    body.append('    ldc.i4.1')
    body.append('    ret')
    body.append(f'  {resume_lbl}:')


def try_parse_for_in_generator(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    m = _FOR_IN_GEN_RE.match(line)
    if not m:
        return None
    var, callee_name, args_text = m.groups()
    if callee_name == 'range':
        return None  # 'for i in range(...):' - da co LINE_PARSER rieng (control_flow.py)
    args_text = args_text.strip()
    arg_nodes = parse_expr_list(args_text) if args_text else []
    pos += 1
    if pos >= len(lines) or lines[pos][0] <= indent_level:
        raise SyntaxError(f"il_codegen: 'for {var} in {callee_name}(...):' khong co than khoi (block rong)")
    body, pos = parse_block_fn(lines, pos, lines[pos][0], sig, known_shapes)
    return {'kind': 'for_in_generator', 'var': var, 'callee_name': callee_name,
            'arg_nodes': arg_nodes, 'body': body}, pos


def _FPW_FOR_IN_CALL_LIST(stmt, ctx):
    from il_features.list_type import fpw_for_in_call_list
    return fpw_for_in_call_list(stmt, ctx)


def fpw_for_in_generator(stmt, ctx):
    func_table = ctx['func_table']
    callee_name = stmt['callee_name']
    callee_sig = func_table.get(callee_name)
    if (callee_sig is not None and not getattr(callee_sig, 'is_generator', False)
            and callee_sig.return_type is not None
            and callee_sig.return_type.shape in ('list', 'set')):
        # 'for x in f(...):' voi f tra ve 1 LIST thuong (2026-08-03, dot 2)
        # - truoc day bao loi, bat nguoi viet gan ra 1 bien truoc. Doi
        # CHINH cau lenh nay sang dang 'for_in_call_list' (xem
        # il_features/list_type.py) roi de duong do lo lieu.
        stmt['kind'] = 'for_in_call_list'
        return _FPW_FOR_IN_CALL_LIST(stmt, ctx)
    if callee_name not in func_table or not getattr(func_table[callee_name], 'is_generator', False):
        raise SyntaxError(
            f"il_codegen: 'for {stmt['var']} in {callee_name}(...):' - '{callee_name}' khong phai "
            f"1 ham generator (khong co 'yield' trong than) - 'for x in f(...):' hien CHI ho tro "
            f"goi TRUC TIEP 1 ham generator, khong ho tro list/dict thuong o day (gan ra 1 bien "
            f"roi 'for x in bien:' voi list/dict thuong)")
    callee = func_table[callee_name]
    # Important fix (2026-08-18, duck-typing-inference): 'for x in gen(...):'
    # DI THANG toi codegen_for_in_generator (KHONG qua _expr_call), nen
    # KHONG co resolve_call_site nao chay cho tham so 'inferred' - neu goi
    # 1 ham-generator co con tham so 'inferred', il_type_str(p.type_ann) ben
    # duoi (codegen_for_in_generator) se KeyError 'inferred' - crash Python
    # THO thay vi loi bien dich ro rang. Chan SOM o day (first-pass walk,
    # truoc khi codegen chay) - GIOI HAN DA BIET, chua ho tro resolve day du
    # qua duong nay (khac Critical 1/_expr_call).
    if any(p.type_ann is not None and p.type_ann.dtype == 'inferred' for p in callee.params):
        # Muc K item 1 (docs/BUGS_TODO.md, task4-critical-fix-report.md):
        # dinh so dong nguon vao message NEU co du thong tin (thong ke
        # 'src_line' chi duoc _parse_block gan cho statement o TOP-LEVEL
        # than ham - xem docstring _parse_block, il_codegen.py - statement
        # long trong if/for khac CHUA co, giu nguyen message cu trong
        # truong hop do, khong bat buoc).
        loc_suffix = ''
        src_line = stmt.get('src_line')
        source_path = ctx.get('source_path')
        if src_line is not None and source_path:
            loc_suffix = f" (o dong {src_line} cua file {source_path})"
        raise SyntaxError(
            f"il_codegen: goi ham-generator '{callee_name}' co tham so kieu suy tu dong "
            f"'inferred' qua 'for {stmt['var']} in {callee_name}(...):' chua duoc ho tro "
            f"(gioi han da biet - dung tham so kieu cu the cho ham generator goi qua "
            f"'for...in'){loc_suffix}")
    TypeAnn = ctx['TypeAnn']
    ctx['declare_named'](stmt['var'], TypeAnn(callee.generator_elem_dtype, None))
    ctx['declare_named'](f'__geniter{id(stmt)}', TypeAnn(callee.generator_class_name, 'generator'))
    for arg_node in stmt['arg_nodes']:
        ctx['collect_ternary_temps'](arg_node)
    ctx['walk_fn'](stmt['body'])


def codegen_for_in_generator(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    func_table = ctx['func_table']
    callee = func_table[stmt['callee_name']]
    compile_expr = ctx['compile_expr']
    store_var = ctx['store_var']
    il_type_str = ctx['il_type_str']

    _, iter_idx, iter_ta = scope[f'__geniter{id(stmt)}']
    gen_class = il_type_str(iter_ta, ctx.get('records'))
    elem_iltype = ctx['il_scalar'].get(callee.generator_elem_dtype, callee.generator_elem_dtype)

    # Lazy import (cung ky thuat da dung o fpw_for_in_call_list, dong ~99)
    # de tranh circular import list_type <-> generator_lazy.
    from il_features.list_type import value_dtype_spec_for_ta
    for arg_node, p in zip(stmt['arg_nodes'], callee.params):
        # Round 3 (2026-08-19): shape-string convention cho list-literal
        # long nhau lam doi so generator ('for x in gen([[1,2],[3,4]]):').
        compile_expr(arg_node, scope, body,
                     value_dtype_spec_for_ta(p.type_ann, arg_node), ctx)
    callee_params_il = ', '.join(il_type_str(p.type_ann) for p in callee.params)
    class_name = ctx.get('class_name') or 'Program'
    body.append(f'    call {gen_class} {class_name}::{stmt["callee_name"]}({callee_params_il})')
    body.append(f'    stloc.s {iter_idx}')

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_forgen{n}_start"
    end_lbl = f"{ctx['prefix']}_forgen{n}_end"

    body.append(f'  {start_lbl}:')
    body.append(f'    ldloc.s {iter_idx}')
    body.append(f'    callvirt instance bool {gen_class}::MoveNext()')
    body.append(f'    brfalse {end_lbl}')
    body.append(f'    ldloc.s {iter_idx}')
    body.append(f"    callvirt instance {elem_iltype} {gen_class}::"
                f"'System.Collections.Generic.IEnumerator<{elem_iltype}>.get_Current'()")
    store_var(stmt['var'], scope, body)
    ctx['loop_stack'].append((start_lbl, end_lbl))
    codegen_stmts_fn(stmt['body'], scope, body, body_dtype, ctx, sig)
    ctx['loop_stack'].pop()
    body.append(f'    br {start_lbl}')
    body.append(f'  {end_lbl}:')


register_line_parser('yield_stmt', try_parse_yield)
register_first_pass_walk('yield_stmt', fpw_yield_stmt)
register_stmt_codegen('yield_stmt', codegen_yield_stmt)
register_line_parser('for_in_generator', try_parse_for_in_generator)
register_first_pass_walk('for_in_generator', fpw_for_in_generator)
register_stmt_codegen('for_in_generator', codegen_for_in_generator)

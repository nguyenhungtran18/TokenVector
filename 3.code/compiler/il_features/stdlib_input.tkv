# -*- coding: utf-8 -*-
"""input()/input(prompt) - Phase 6.4 (2026-08-12).

Anh xa thang Console.ReadLine() - co prompt (1 tham so 'str') thi in
prompt TRUOC (khong xuong dong, giong Python) roi moi doc dong. Python
that: neu gap EOF (input truyen qua pipe/redirect het du lieu), input()
nem EOFError - ReadLine() tra ve null trong truong hop tuong duong; anh
xa null -> "" (chuoi rong) thay vi nem loi CLR rieng, GIOI HAN CO Y THUC
(don gian hoa, khong dinh nghia rieng 1 loai loi EOFError - hiem gap
trong code AOT-compile thuc te, khac REPL)."""
from il_dispatch import register_expr_builtin


def push_input(args, scope, out, dtype, ctx):
    if len(args) > 1:
        raise SyntaxError("il_codegen: input() nhan toi da 1 tham so (prompt: str)")
    if len(args) == 1:
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    call void class [mscorlib]System.Console::Write(string)')
    out.append('    call string [mscorlib]System.Console::ReadLine()')
    out.append('    dup')
    lbl = f'__input_notnull_{id(args)}'
    out.append(f'    brtrue {lbl}')
    out.append('    pop')
    out.append('    ldstr ""')
    out.append(f'  {lbl}:')


register_expr_builtin('input', push_input, 'str')

# -*- coding: utf-8 -*-
"""win32_gui_window.py - Native Windows Forms GUI Window Launcher for TokenVector
"""

import re
from il_dispatch import register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen

_WIN_GUI_RE = re.compile(r'^show_native_winforms_gui\((.+)\)$')


def try_rhs_win_gui(rhs, name, known_shapes):
    m = _WIN_GUI_RE.match(rhs.strip())
    if not m:
        return None
    return {'kind': 'assign_win_gui', 'name': name, 'title_expr': m.group(1)}


def fpw_win_gui(stmt, ctx):
    ta = ctx['TypeAnn']('i32', None)
    ctx['declare_named'](stmt['name'], ta)


def codegen_win_gui(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    # Khởi tạo cửa sổ System.Windows.Forms.Form native trên Windows
    body.append('    newobj instance void [System.Windows.Forms]System.Windows.Forms.Form::.ctor()')
    body.append('    dup')
    body.append('    ldstr "🟡 TOKENVECTOR NATIVE WIN32 PAC-MAN GAME WINDOW"')
    body.append('    callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)')
    body.append('    call void [System.Windows.Forms]System.Windows.Forms.Application::Run(class [System.Windows.Forms]System.Windows.Forms.Form)')
    body.append('    ldc.i4.1')
    ctx['store_var'](stmt['name'], scope, body)


register_assign_rhs_parser('win_gui', try_rhs_win_gui)
register_first_pass_walk('assign_win_gui', fpw_win_gui)
register_stmt_codegen('assign_win_gui', codegen_win_gui)

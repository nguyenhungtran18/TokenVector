# -*- coding: utf-8 -*-
"""Cong do "da dang ky day du" cua 125 file nguon cua compiler.

Tieu chi — do bang PROBE TRUC TIEP vao `dist/tkvc-tv.exe`, khong tin tai lieu:

  A. def co `-> "kieu"`                      -> dang ky day du
  B. def thieu chu ky nhung CHI `return`     -> hop le (ham void)
  C. def thieu chu ky MA co `return <giatri>`-> VI PHAM

Compiler BO QUA hoan toan hai co che CPython (da kiem chung bang probe:
gia tri True hay False deu bi bo qua):
  * `if __tkv_chi_cpython__:` ... — bo qua ca khoi
  * `@__tkv_cpython_only__`       — bo qua ham co decorator nay

Mot thu bao: phai bo qua CA CAY cua ham long. `ast.walk` KHONG lam duoc — no
van descend vao cay con cua nested FunctionDef. Ham nay tu de quy, va co tu
kiem o chinh file nen khong the sai am tham.

Chay:  python tools\\dang_ky_gate.py            (in bang + exit code)
       python tools\\dang_ky_gate.py --quiet    (chi exit code)
Exit 0 = khong con ham nao chua dang ky day du.
"""
import ast
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DS = os.path.join(ROOT, 'compiler_src', 'ds_gop.txt')
MARK = '__tkv_chi_cpython__'


def tra_ve_gia_tri(n):
    """True neu co `return <bieu thuc>` o than cua n, bo qua moi ham long."""
    stack = list(ast.iter_child_nodes(n))
    while stack:
        s = stack.pop()
        if isinstance(s, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda,
                           ast.ClassDef)):
            continue
        if isinstance(s, ast.Return) and s.value is not None:
            return True
        stack.extend(ast.iter_child_nodes(s))
    return False


def tu_kiem():
    src = ast.parse(
        'def a():\n    return "x"\n'
        'def b():\n    return\n'
        'def c():\n    def d():\n        return "y"\n    return\n'
        'def e():\n    def f():\n        return "z"\n    return 1\n')
    ns = {n.name: n for n in src.body if isinstance(n, ast.FunctionDef)}
    assert tra_ve_gia_tri(ns['a']) is True
    assert tra_ve_gia_tri(ns['b']) is False
    assert tra_ve_gia_tri(ns['c']) is False
    assert tra_ve_gia_tri(ns['e']) is True


def dong_lines_cp_python(t):
    """Tap dong nam trong khoi `if __tkv_chi_cpython__:`."""
    s = set()
    for n in ast.walk(t):
        if isinstance(n, ast.If) and MARK in ast.unparse(n.test):
            for c in ast.walk(n):
                if getattr(c, 'lineno', None):
                    s.add(c.lineno)
    return s


def main():
    tu_kiem()
    quiet = '--quiet' in sys.argv
    ds = [l.strip() for l in io.open(DS, encoding='utf-8').read().split('\n') if l.strip()]
    n_def = n_ok = n_void = n_dec = n_blk = 0
    con_lai, arg_thieu, loi_parse = [], [], []
    for rel in ds:
        p = os.path.join(ROOT, rel)
        if not os.path.exists(p):
            loi_parse.append('%s: KHONG TON TAI' % rel)
            continue
        try:
            t = ast.parse(io.open(p, encoding='utf-8').read())
        except SyntaxError as e:
            loi_parse.append('%s:%s %s' % (rel, e.lineno, e.msg))
            continue
        blk = dong_lines_cp_python(t)
        for n in ast.walk(t):
            if not isinstance(n, ast.FunctionDef):
                continue
            n_def += 1
            if n.returns is not None:
                n_ok += 1
                continue
            if any('cpython' in ast.unparse(d) for d in n.decorator_list):
                n_dec += 1
                continue
            if n.lineno in blk:
                n_blk += 1
                continue
            if tra_ve_gia_tri(n):
                con_lai.append((rel, n.lineno, n.name))
            else:
                n_void += 1
            a = n.args
            args = list(a.posonlyargs) + list(a.args) + list(a.kwonlyargs)
            if args and args[0].arg in ('self', 'cls'):
                args = args[1:]
            miss = [x.arg for x in args if x.annotation is None]
            if miss:
                arg_thieu.append((rel, n.lineno, n.name, miss))

    if not quiet:
        print('=== %d file / %d ham tren duong TokenVector ===' % (len(ds), n_def))
        print('  A. co `-> "kieu"`                   : %4d  (%.1f%%)'
              % (n_ok, n_ok * 100.0 / max(n_def, 1)))
        print('  B. void (thieu chu ky, chi return)  : %4d  (%.1f%%)  HOP LE'
              % (n_void, n_void * 100.0 / max(n_def, 1)))
        print('     bo qua %d ham @__tkv_cpython_only__ + %d ham trong khoi `if`'
              % (n_dec, n_blk))
        print('  ' + '-' * 56)
        print('  A + B  DA DANG KY DAY DU            : %4d  (%.1f%%)'
              % (n_ok + n_void, (n_ok + n_void) * 100.0 / max(n_def, 1)))
        print()
        print('  VI PHAM (thieu chu ky + tra ve gia tri): %d' % len(con_lai))
        for rel, ln, name in con_lai:
            print('     %-46s :%-5d %s' % (rel, ln, name))
        print('  thieu chu ky tham so (tru self)        : %d' % len(arg_thieu))
        for rel, ln, name, miss in arg_thieu[:10]:
            print('     %-46s :%-5d %s(%s)' % (rel, ln, name, ','.join(miss)))
        if loi_parse:
            print()
            print('  FILE LOI:')
            for x in loi_parse:
                print('     ' + x)
        print()
    sai = len(con_lai) + len(arg_thieu) + len(loi_parse)
    if not quiet:
        print('GATE: %s' % ('PASS' if sai == 0 else 'FAIL (%d)' % sai))
    return 0 if sai == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
# -*- coding: utf-8 -*-
"""Phat hien "ham generator" (than co it nhat 1 dong 'yield <expr>' o cap
top, TRUOC khi macro-expand) - dung boi il_codegen.py's gen_il_program de
quyet dinh dieu huong sang gen_il_generator_function() (state-machine
lazy THAT, xem generator_lazy.py) thay vi gen_il_function() thong thuong.

LICH SU (2026-07-29): phien ban dau (B2(c)) desugar 'yield x' THANH
'__gen_result.append(x)' tren 1 list eager (KHONG lazy that - vong lap
vo han se treo). Nguoi dung sau do chon huong 'Ho tro tong quat' (yield o
bat ky dau, long nhau tuy y) - TOAN BO co che eager (desugar_generator_body/
try_expand_yield/macro 'yield') da bi GO BO va THAY THE hoan toan boi
generator_lazy.py's state-machine that (class rieng cai IEnumerator<T>,
field-backed locals, switch tren '<>1__state') - xem project-tokenvector-
wave2-status memory. is_generator_body la ham DUY NHAT con lai tu file
nay, van dung nguyen ven cho muc dich phat hien."""
import re

_YIELD_RE = re.compile(r'^yield\s+(.+)$')


def is_generator_body(body_lines):
    """True neu than ham (RAW, chua parse) co it nhat 1 dong 'yield <expr>'
    o cap top - dung TRUOC _expand_macros/parse de quyet dinh dieu huong
    sang gen_il_generator_function() thay vi gen_il_function() thong
    thuong."""
    for raw in body_lines:
        stripped = raw.strip()
        if _YIELD_RE.match(stripped):
            return True
    return False

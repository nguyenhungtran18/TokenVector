# -*- coding: utf-8 -*-
"""So sanh danh muc builtin TokenVector voi CPython - phan CO HOC.

Chi lay ten, KHONG ket luan gi ve viec co chay duoc hay khong. Phan kiem
chung phai probe (xem gen_builtin_ref.py va README cua file nay).

2026-10-02: KHONG doc `docs/BUILTIN_REFERENCE.md` nua - file do da bi xoa khi
gom tai lieu ve 1. Bay lay danh truc tiep tu ma nguon qua `gen_builtin_ref`
(noi sinh muc 7 cua `docs/REFERENCE.md`) nen khong con kha nang lech.
"""
import builtins
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_builtin_ref as _gen  # noqa: E402

# 5 ham xu ly TRUC TIEP trong il_codegen, khong qua bang dang ky
DIRECT = {'print', 'len', 'range', 'abs', 'round'}

# Tu khoa / gia tri dac biet - KHONG phai ten builtin trong bang dang ky,
# nen danh muc sinh tu dong khong the thay. Bo vao de khong bao loi gia.
KEYWORDS = {'True', 'False', 'None', 'NotImplemented', 'Ellipsis', 'self'}


def tokenvector_builtins():
    """Lay TEN goi duoc cua nguoi dung: ham builtin + dang khoi tao container
    o VHE PHAI PHE GAN + ham xu ly truc tiep.

    Chi lay mat "HAM BUILTIN" se bao loi GIA: `bytes`, `bytearray`,
    `frozenset`, `dict`, `list`, `set`, `tuple` la CONSTRUCTOR, duoc dang ky
    o ASSIGN_RHS_PARSERS chu khong phai o EXPR_BUILTIN."""
    b = _gen.all_registered()
    out = set()
    for key, value in b.items():
        if key.startswith('HAM BUILTIN') or key.startswith('DANG PHAI PHAI'):
            out |= {n.split('.')[-1] for n in value}
    return out


def main():
    py = set(n for n in dir(builtins) if not n.startswith('_'))
    tv = (tokenvector_builtins() | DIRECT | KEYWORDS)
    missing = sorted(py - tv)
    extra = sorted(tv - py)
    print('CPython builtin public      : %d' % len(py))
    print('TokenVector callable        : %d' % len(tv))
    print('')
    print('=== VAN CON PHAI KIEM CHUNG (%d) ===' % len(missing))
    for i in range(0, len(missing), 6):
        print('   ' + '  '.join('%-15s' % n for n in missing[i:i + 6]).rstrip())
    io.open(os.path.join(ROOT, 'tools', '_py_missing.txt'), 'w',
            encoding='utf-8', newline='\n').write('\n'.join(missing) + '\n')
    print('')
    print('TOKENVECTOR CO - PYTHON THIEU (%d) - phan mo rong ngoai Python:' % len(extra))


if __name__ == '__main__':
    main()

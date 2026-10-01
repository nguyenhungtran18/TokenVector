# -*- coding: utf-8 -*-
"""So sanh danh muc builtin TokenVector voi CPython - phan CO HOC.

Chi lay ten, KHONG ket luan gi ve viec co chay duoc hay khong. Phan kiem
chung phai probe (xem gen_builtin_ref.py va README cua file nay).
"""
import builtins
import io
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = os.path.join(ROOT, 'docs', 'BUILTIN_REFERENCE.md')

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
    txt = io.open(REF, encoding='utf-8').read()
    out = set()
    for header, stop in (
            ('## HAM BUILTIN', '\n## '),
            ('## DANG PHAI PHAI CUA PHE GAN', '\n## ')):
        sec = txt.split(header)[1].split(stop)[0]
        out |= set(re.findall(r'`([A-Za-z_][A-Za-z_0-9]*)`', sec))
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

# -*- coding: utf-8 -*-
"""Moi builtin/method THU VIEN da dang ky trong il_dispatch phai xuat
hien trong generator (moc 8, buoc 1.1) HOAC nam trong UNGENERATABLE cua
generator kem ly do - neu khong thi tinh nang moi co the lot vao ma
khong bao gio bi bo do cham toi (dung y "ngay ai do dang ky str.rfind,
bo do bat dau sinh rfind NGAY hom do" trong ke hoach).

Loai tru rieng: cac builtin I/O that (http/db/os/zip) va khong tat dinh
(dong ho that) - generator CO Y khong sinh chung vi chuong trinh sinh ra
phai THUAN va DUNG (xem generator.py's docstring), khong phai vi thieu
sot.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'test' / 'parity'))
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / 'compiler'))
import il_codegen  # noqa: E402  (kich hoat dang ky il_features)
import il_dispatch as D  # noqa: E402
import generator as G  # noqa: E402


def main():
    fails = []

    covered_builtins = (set(G.SAFE_BUILTIN_ARITY1) | G.AGG_BUILTINS
                         | G.CONTAINER_ARG_BUILTINS)
    all_builtins = set(D.EXPR_BUILTIN_CODEGEN)
    excluded = G._UNSAFE_BUILTINS | set(G.UNGENERATABLE) | {'base64_decode'}
    missing = all_builtins - covered_builtins - excluded
    if missing:
        fails.append(
            "Builtin da dang ky nhung generator KHONG sinh va cung KHONG "
            "nam trong _UNSAFE_BUILTINS/UNGENERATABLE (kem ly do) hay "
            "ngoai le co ghi ly do: %s — them vao SAFE_BUILTIN_ARITY1/"
            "AGG_BUILTINS/CONTAINER_ARG_BUILTINS hoac UNGENERATABLE kem "
            "ly do." % sorted(missing))

    covered_str_methods = set(G.REGISTRY_STR_METHODS)
    exploratory = set(G.EXPLORATORY_STR_METHODS) | G.COVERED_ELSEWHERE
    missing_methods = covered_str_methods - exploratory
    if missing_methods:
        fails.append(
            "Method chuoi DA DANG KY trong il_dispatch nhung khong nam "
            "trong EXPLORATORY_STR_METHODS/COVERED_ELSEWHERE cua generator "
            "(nen it nhat duoc THU, du la qua nhanh 'tham vong'): %s"
            % sorted(missing_methods))

    if fails:
        print('grammar_coverage_test: TRUOT')
        for f in fails:
            print('  -', f)
        return 1
    print('grammar_coverage_test: dat (%d builtin, %d method chuoi da dang ky '
          'deu duoc generator cham toi)' % (len(all_builtins), len(covered_str_methods)))
    return 0


if __name__ == '__main__':
    sys.exit(main())

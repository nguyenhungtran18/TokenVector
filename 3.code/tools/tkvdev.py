# -*- coding: utf-8 -*-
"""Chay TokenVector compiler TRUC TIEP tu source (khong qua PyInstaller).

Ly do co tool nay: `build_tkvc.ps1` danh lai compiler bang PyInstaller moi
lan ~90 giay, ma phan lon nua thoi gian do la doc lai y het. Khi sua
compiler va can xem traceback THAT (vi du loi nen mot file `.tkv` la
Python that nen Python bao loi doc duoc ngay), chay:

    python tools\\tkvdev.py build Testkit\\x_test.tkv --out %TEMP%\\x.exe --entry run
    %TEMP%\\x.exe

File `.tkv` la Python that, chi doi duoi hien thi. File nay vay meta_path
finder: ten module -> `<ten>.tkv` trong `3.code/compiler/` truoc, roi `3.code/`.
Do do `tkv.tkv` (o goc), `tkv_compile.tkv`, `il_codegen.tkv` va
`il_features/*.tkv` deu nap duoc nhu module that, va `plugin_loader` van
tu nap `compiler/il_features/` nhu khi dev.

BAO GIO CUNG PHAI CLEAN BUILD + `tools\\testkit_gate.ps1` truoc khi commit -
binary cu che giay hoi quy, va day KHONG thay the buoc do.
"""
import importlib.abc
import importlib.machinery
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class TkvFinder(importlib.abc.MetaPathFinder, importlib.abc.Loader):
    """Cho phep `import <ten>` quy ve `<ten>.tkv` (module trong compiler/
    truoc, roi cap goc 3.code/ - giong thu tu sys.path cua build script)."""

    def find_spec(self, fullname, path=None, target=None):
        stem = fullname.rsplit('.', 1)[-1]
        for base in (os.path.join(ROOT, 'compiler'), ROOT):
            cand = os.path.join(base, stem + '.tkv')
            if os.path.isfile(cand):
                return importlib.util.spec_from_file_location(
                    fullname, cand,
                    loader=importlib.machinery.SourceFileLoader(fullname, cand))
        return None

    def create_module(self, spec):
        return None

    def exec_module(self, module):
        return None


def main():
    sys.path.insert(0, ROOT)
    sys.path.insert(0, os.path.join(ROOT, 'compiler'))
    sys.meta_path.insert(0, TkvFinder())
    import tkv  # noqa: E402  (tkv.tkv o goc 3.code, nap qua finder o tren)
    return tkv.main()


if __name__ == '__main__':
    main()

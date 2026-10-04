# -*- coding: utf-8 -*-
"""Base class co cham trong - TokenVector chi nhan MOT TEN DON GIAN.

`class TkvFinder(importlib.abc.MetaPathFinder)` la kieu da ke thua Python.
TokenVector chi chap nhan `class Dog(Animal)`. Day la gioi han cua compiler,
nen py2tkv khong the lam bien no bien dich duoc.
"""


class TkvFinder(importlib.abc.MetaPathFinder, importlib.abc.Loader):
    def find_spec(self, fullname, path=None, target=None):
        return None


def main() -> int:
    return 0
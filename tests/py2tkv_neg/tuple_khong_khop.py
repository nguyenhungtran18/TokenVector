# -*- coding: utf-8 -*-
"""Giai gan chu ky tuple - TokenVector phai BAO LOI.

Ham tra ve MOT gia tri nhung ben trai la HAI bien. Day la gioi han cua compiler
(chan khong phai gioi han cua py2tkv), nen py2tkv khong the lam bien no bien
dich duoc - va KHONG duoc bo qua im lang.
"""


def f() -> int:
    return 1


def main() -> int:
    a, b = f()
    return a + b
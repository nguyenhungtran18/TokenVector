# -*- coding: utf-8 -*-
"""Gia tri cap module tinh luc chay - TokenVector chi nhan HANG SO.

`FLAG = ("--x" in sys_argv())` khong phai literal nen khong lam hang so duoc.
"""


def main() -> int:
    if FLAG:
        return 1
    return 0


FLAG = "--x" in sys_argv()
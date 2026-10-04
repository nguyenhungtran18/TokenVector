# -*- coding: utf-8 -*-
"""Code CHAY LUC CHAY o cap module - phai duoc bom vao ham `__khoi_dong()`.

TokenVector chi nhan `def`/`class`/hang so o cap module. Code .py viet kieu
script se khong bien dich duoc neu giong nguyen. py2tkv dua chung vao
`__khoi_dong()` va GOI o dau `main` - tuong duong nghia vi `main` chinh la
diem vao cua chuong trinh.

File nay CO san `main`, nen `ghi` phai chen `__khoi_dong()` o dau than no.
Cac cau lenh cap module o day KHONG gan bien nao, nen khong can gi den ham
khac (truong hop gan bien ma ham khac doc se bi py2tkh TU CHOI bom va bao
cao).
"""

import sys

print("bat dau")


def helper() -> int:
    return 7


def main() -> int:
    print(helper())
    return 0
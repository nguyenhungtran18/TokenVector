# -*- coding: utf-8 -*-
"""hashlib / json / re -> builtin TokenVector (sha256_hex, json_*, re_*).

Kieu tra ve cua chinh `json_loads` / `re_*` thi py2tkv KHONG the suy (no la
builtin, kieu tra ve nam trong tai lieu chu khong nam trong source) - nen
khai o Python. Day la hinh thuc dung chung, xem docs/TOOLS-TO-TOKENVECTOR.md.
"""
import hashlib
import json
import re

SRC = "def run() -> i32:\n    return 1\n"


def digest(text: str) -> str:
    return hashlib.sha256(text).hexdigest()


def short(text: str) -> str:
    return hashlib.md5(text).hexdigest()


def dump(obj: str) -> str:
    return json.dumps(obj)


# KHONG co ham nao goi ham `loads` cua module json trong fixture nay. Ly do:
# `json_loads` cua TokenVector tra ve MOT RECORD va BAT BUOC truyen ten record
# lam tham so thu 2 (`json_loads(s, RecordName)`), con CPython tra ve dict. Do
# lenh goi 1 tham do se khong bien dich duoc - day la khac biet nghia gi, khong
# phai thieu transform. `json_loads` van duoc py2tkv doi ten, xem
# `xuli_thu_vien_1`.


def find(pat: str, s: str) -> str:
    return re.search(pat, s)


def match(pat: str, s: str) -> str:
    return re.match(pat, s)


def all_of(pat: str, s: str) -> list[str]:
    return re.findall(pat, s)


def split_all(pat: str, s: str) -> list[str]:
    return re.split(pat, s)


def sub(pat: str, rep: str, s: str) -> str:
    return re.sub(pat, rep, s)


def main() -> int:
    print(digest("a"))
    print(short("a"))
    print(dump(SRC))
    print(len(split_all(",", "a,b,c")))
    return 0
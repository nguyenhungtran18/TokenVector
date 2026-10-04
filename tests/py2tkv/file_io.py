# -*- coding: utf-8 -*-
"""Khoi file: doc/ghi file theo kieu TokenVector (read_file / write_file).

Tham so duoc khai kieu TU TAY trong Python vi TokenVector khong suy duoc
kieu cua tham so khi no duoc truyen thang cho mot loi goi khac - day la
hanh vi py2tkv co THE lam (va doc huu khai chu ky), khong phai doan."""
import io


def read_it(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()


def write_it(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(text)


def chained_write(path: str, text: str) -> None:
    io.open(path, "w", encoding="utf-8").write(text)


def chained_read(path: str) -> str:
    return io.open(path, encoding="utf-8").read()


def main() -> int:
    p = "x.txt"
    write_it(p, "hello")
    print(read_it(p))
    chained_write(p, "bye")
    print(chained_read(p))
    return 0
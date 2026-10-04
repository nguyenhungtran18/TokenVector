# -*- coding: utf-8 -*-
"""Kieu duoc chuan hoa + return annotation duoc giu lai."""


def add(a: int, b: int) -> int:
    return a + b


def ratio(x: float, y: float) -> float:
    return x / y


def label(flag: bool) -> str:
    if flag:
        return "co"
    return "khong"


def total(xs: list[int]) -> int:
    s = 0
    for v in xs:
        s = s + v
    return s


def names(items: list[str]) -> list[str]:
    out = []
    for it in items:
        out.append(it)
    return out


def table() -> dict[str, int]:
    return {"a": 1, "b": 2}


def scale(v: float, k: float = 2.0) -> float:
    return v * k


def main() -> int:
    print(add(1, 2))
    print(ratio(3.0, 2.0))
    print(label(True))
    print(total([1, 2, 3]))
    print(len(names(["a", "b"])))
    print(scale(3.0))
    return 0
# -*- coding: utf-8 -*-
"""Hang so cap module: nhieu dong, dau phay cuoi, bool, dict, set."""


MAX = 10
NAME = "abc"
PI = 3.14
FLAG = True
SIZES = [
    1,
    2,
    4,
]
NAMES = ["a", "b"]
TABLE = {
    "x": 1,
    "y": 2,
}
KEYS = {"p", "q"}
EMPTY = []


def show() -> int:
    print(MAX)
    print(NAME)
    print(PI)
    print(SIZES)
    print(NAMES)
    print(TABLE)
    print(KEYS)
    return len(EMPTY)


def main() -> int:
    return show()
# -*- coding: utf-8 -*-
"""`def` long nhau + container rong + bien cuc bo gan trong than."""


def outer(n: int) -> int:
    def inner(x: int) -> int:
        return x + 1

    s = 0
    for i in range(n):
        s = s + inner(i)
    return s


def big() -> int:
    acc = []
    acc.append("a")
    acc.append("b")
    return len(acc)


def nums() -> int:
    vs = []
    vs.append(1)
    return len(vs)


def main() -> int:
    print(outer(3))
    print(big())
    print(nums())
    return 0
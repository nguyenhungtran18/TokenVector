import sys


def make_deep(a_param):
    a = a_param

    def mid(b_param):
        b = b_param

        def inner(c):
            return a + b + c

        return inner(10)

    return mid(1)


def bench_nested(n):
    total = 0
    i = 0
    while i < n:
        total = total + (make_deep(i) % 1000)
        i = i + 1
    return total


if __name__ == '__main__':
    n = int(sys.argv[1])
    print(bench_nested(n))

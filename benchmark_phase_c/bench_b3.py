import sys


def double_it(x):
    return x * 2


def compose(f):
    extra = 10

    def wrapped(x):
        return f(x) + extra

    return wrapped


def bench_b3(n):
    g = compose(double_it)
    total = 0
    i = 0
    while i < n:
        total = total + (g(i) % 1000)
        i = i + 1
    return total


if __name__ == '__main__':
    n = int(sys.argv[1])
    print(bench_b3(n))

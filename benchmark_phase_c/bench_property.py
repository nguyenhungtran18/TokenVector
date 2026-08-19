import sys


class Circle:
    def __init__(self, r):
        self.r = r

    @property
    def area(self):
        return 3.0 * self.r * self.r


def bench_property(n):
    c = Circle(2.0)
    total = 0.0
    i = 0
    while i < n:
        total = total + c.area
        i = i + 1
    return total


if __name__ == '__main__':
    n = int(sys.argv[1])
    print(bench_property(n))

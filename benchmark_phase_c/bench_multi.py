import sys


class Flyable:
    def fly(self):
        pass


class Animal:
    def __init__(self, sound):
        self.sound = sound

    def speak(self):
        return self.sound


class Bird(Animal, Flyable):
    def __init__(self, sound):
        super().__init__(sound)

    def fly(self):
        return self.sound * 10


def bench_multi(n):
    b = Bird(3)
    total = 0
    i = 0
    while i < n:
        total = total + ((b.speak() + b.fly()) % 1000)
        i = i + 1
    return total


if __name__ == '__main__':
    n = int(sys.argv[1])
    print(bench_multi(n))

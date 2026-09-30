# -*- coding: utf-8 -*-
# Ban CPython cua probe doi chieu. Giong het ban .tkv o muc tieu (nhan + ket qua).
# Do la bang cong, thuong tinh bo di.

def emit(k, v):
    print(k + " = " + v)

def pair(a, b):
    return [a, b]

def join_i(xs):
    return ",".join([str(x) for x in xs])

def m1():
    emit("div_slash", str(7.0 / 2))
    emit("div_floor", str(7 // 2))
    emit("div_neg_floor", str(-7 // 2))
    emit("mod_neg", str(-7 % 3))
    emit("pow", str(2 ** 10))
    emit("float_repr", str(0.1 + 0.2))
    emit("fdiv", str(1.0 / 4))
    emit("int_big", str(1000000 * 1000000))
    emit("hex", str(255) + "/" + str(0xFF))
    emit("oct", str(0o17))
    emit("bin", str(0b1011))
    emit("sci", str(1e3) + "/" + str(1.5e2))
    emit("abs", str(abs(-5)))
    emit("minmax", str(min(3, 5)) + "/" + str(max(3, 5)))
    emit("round", str(round(2.567, 2)))
    emit("int_from_str", str(int("42")) + "/" + str(int("-7")))

def repr_split(s):
    parts = s.split(", ")
    return parts[0] + "|" + parts[1] + "|n=" + str(len(parts))

def repr_join():
    parts = ["a", "b", "c"]
    return ",".join(parts)

def repr_strip():
    t = "  pad  "
    return "[" + t.strip() + "]"

def m2():
    s = "Hello, World"
    emit("upper", s.upper())
    emit("lower", s.lower())
    emit("len", str(len(s)))
    emit("find", str(s.find("World")))
    emit("find_miss", str(s.find("zzz")))
    emit("replace", s.replace("World", "TV"))
    emit("split", repr_split(s))
    emit("join", repr_join())
    emit("strip", repr_strip())
    emit("startswith", str(s.startswith("Hell")) + "/" + str(s.startswith("x")))
    emit("slicing", s[0:5] + "/" + s[-6:] + "/" + s[::2])
    emit("find_only", str(s.find("World")))
    emit("isdigit", str(s.isdigit()))
    emit("format_pct", "%s-%d" % ("a", 5))
    emit("str_concat", "a" + str(1) + "b")
    emit("in", str("World" in s) + "/" + str("zz" in s))
    emit("cmp", str(s == "Hello, World") + "/" + str(s < "Z"))

def m3():
    xs = [3, 1, 2]
    xs.append(4)
    emit("append_len", str(len(xs)))
    xs.sort()
    emit("sort", join_i(xs))
    xs.reverse()
    emit("reverse", join_i(xs))
    emit("index", str(xs.index(3)))
    n1 = xs.count(1)
    emit("count", str(n1))
    emit("in", str(2 in xs) + "/" + str(9 in xs))
    ys = xs[1:3]
    emit("slice", join_i(ys))
    del xs[0]
    emit("del_item", join_i(xs))
    xs2 = pair(1, 2)
    more = pair(3, 4)
    xs2.extend(more)
    emit("extend", join_i(xs2))
    xs2.remove(2)
    emit("remove", join_i(xs2))
    emit("max_min", str(max(xs2)) + "/" + str(min(xs2)))
    emit("sum", str(sum(xs2)))

def m4():
    d = {"a": 1, "b": 2}
    emit("d_len", str(len(d)))
    g1 = d.get("a", 0)
    g2 = d.get("q", -1)
    emit("d_get", str(g1) + "/" + str(g2))
    d["c"] = 3
    emit("d_add", str(len(d)) + "/" + str(d["c"]))
    emit("d_in", str("a" in d) + "/" + str("q" in d))
    emit("d_del", str(d.pop("a")) + "/" + str(len(d)))
    ks = sorted_keys(d)
    emit("d_keys", ks)
    s = {1, 2, 3}
    s.add(4)
    emit("set_len", str(len(s)))
    s.discard(1)
    emit("set_discard", str(len(s)))
    emit("set_in", str(2 in s) + "/" + str(9 in s))

def sorted_keys(d):
    ks = [k for k in d.keys()]
    ks.sort()
    out = ""
    for i in range(len(ks)):
        if i > 0:
            out = out + ","
        out = out + ks[i] + "=" + str(d[ks[i]])
    return out

def m5():
    xs = quad()
    c1 = [x * 2 for x in xs]
    emit("comp", join_i(c1))
    c2 = [x for x in xs if x % 2 == 0]
    emit("comp_if", join_i(c2))
    two = [x * y for x in [1, 2] for y in [10, 20]]
    emit("comp_2for", str(len(two)))
    dc = {k: 1 for k in ["a", "b"]}
    emit("dictcomp", str(len(dc)))
    sc = {x % 2 for x in xs}
    emit("setcomp", str(len(sc)))
    emit("lambda", str(apply_it(lambda x: x * 3, 5)))
    emit("map", join_i(map(inc1, xs)))
    emit("filter", join_i(filter(gt2, xs)))

def quad():
    return [1, 2, 3, 4]

def inc1(x):
    return x + 1

def gt2(x):
    return x > 2

def apply_it(f, v):
    return f(v)

def m6():
    n = 0
    for i in range(5):
        if i == 2:
            continue
        if i == 4:
            break
        n = n + i
    emit("loop_break_cont", str(n))
    k = 0
    while k < 3:
        k = k + 1
    emit("while", str(k))
    hit = 0
    for i in range(3):
        if i == 1:
            hit = 1
    emit("for_else", str(hit))
    emit("cond_ternary", str(pick(1 > 0, "yes", "no")))
    emit("cond_question", str(pick2(1 > 0, "yes", "no")))

def pick(c, a, b):
    if c:
        return a
    return b

def pick2(c, a, b):
    return a if c else b

def m7():
    emit("exc_basic", catch1())
    emit("exc_type", catch2())
    emit("exc_else", catch3())
    emit("exc_from", catch4())
    emit("exc_finally", catch5())
    emit("exc_custom_msg", catch6())
    emit("exc_unmatched", catch7())

def catch1():
    try:
        raise ValueError("x")
    except ValueError as e:
        return "caught"
    return "none"

def catch2():
    try:
        a = [1]
        return str(a[5])
    except:
        return "index"
    return "none"

def catch3():
    r = "no"
    try:
        pass
    except:
        r = "bad"
    else:
        r = "else"
    return r

def catch4():
    try:
        try:
            raise KeyError("k")
        except KeyError as e:
            raise ValueError("wrapped") from e
    except ValueError as e:
        return "chain"
    return "none"

def catch5():
    r = ""
    try:
        r = "t"
    finally:
        r = r + "f"
    return r

def catch6():
    try:
        boom()
    except MyErr as e:
        return str(e)
    return "none"

def boom():
    raise MyErr("custom-msg")

def catch7():
    try:
        try:
            raise KeyError("k")
        except MyErr as e:
            return "wrong"
    except KeyError as e:
        return "propagated"
    return "none"

class MyErr(Exception):
    def __init__(self, m):
        self.msg = m
    def __str__(self):
        return self.msg

def m8():
    p = Point(3, 4)
    emit("ctor_run", str(p.x) + "/" + str(p.y))
    emit("dunder_add", str(p + Point(1, 1)))
    emit("dunder_eq", str(p == Point(3, 4)) + "/" + str(p == Point(0, 0)))
    emit("dunder_str", str(p))
    emit("dunder_len", str(len(p)))
    q = p.scaled(2)
    emit("method", str(q.x) + "/" + str(q.y))
    d = Dog("rex", 4)
    emit("inherit", d.speak() + "/" + str(d.legs))
    emit("isinstance_like", d.tag())

class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    def __add__(self, o):
        return str(self.x + o.x) + "," + str(self.y + o.y)
    def __eq__(self, o):
        return True
    def __str__(self):
        return "P(" + str(self.x) + "," + str(self.y) + ")"
    def __len__(self):
        return 2
    def scaled(self, f):
        return Point(self.x * f, self.y * f)

class Animal:
    def __init__(self, name):
        self.name = name
        self.legs = 4
    def speak(self):
        return "..."

class Dog(Animal):
    def __init__(self, name, legs):
        self.name = name
        self.legs = legs

    def speak(self):
        return "woof"
    def tag(self):
        return self.name

def m9():
    emit("closure", str(counter() + counter()))
    emit("default_arg", str(with_default(5)) + "/" + str(with_default(0)))
    emit("recursion", str(fib(10)))
    emit("global_ok", str(bump()))

def counter():
    c = 0
    def inc():
        nonlocal c
        c = c + 1
        return c
    return inc()

def with_default(x, y=7):
    return x + y

def fib(n):
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)

gcount = 0

def bump():
    global gcount
    gcount = gcount + 1
    return gcount

def m10():
    emit("gen_list", join_i(gen_upto(4)))
    emit("gen_from", join_i(gen_chain()))
    emit("gen_ret", str(gen_total(5)))

def gen_upto(n):
    for i in range(n):
        yield i

def gen_chain():
    src = [7, 8]
    yield from src

def gen_total(n):
    t = 0
    for i in range(n):
        t = t + i
    return t

def m11():
    emit("star_args", str(sum_all(1, 2, 3)))
    emit("star_args_expand", str(sum_all(*[1, 2, 3])))
    emit("kwargs", str(greet(name="tv", n=2)))
    emit("kwargs_expand", str(greet(**{"name": "x", "n": 1})))
    emit("lambda_param", str(apply_it(lambda x: x * 2, 5)))

def sum_all(a, b, c):
    return a + b + c

def greet(name, n=1):
    return name + str(n)

def m12():
    emit("bool_str_inline", str(1 > 0))
    t = 1 > 0
    emit("bool_str_var", str(t))
    emit("and_or", str(1 and 2) + "/" + str(0 or 5))
    emit("not", str(not 0) + "/" + str(not 1))
    xs = [1]
    ys = [1]
    emit("list_identity", str(xs is ys) + "/" + str(xs is xs))
    emit("isinstance_like", str(1 == 1.0))

def m13():
    emit("mutate_list", mutate())
    lit = [1, 2, 3]
    emit("slice_full", join_i(lit[0:3]))
    emit("slice_open", join_i(lit[1:]))
    emit("nested_idx", str(nested()))

def mutate():
    xs = [1, 2]
    xs.append(3)
    return join_i(xs)

def nested():
    xs = [[1, 2], [3]]
    inner = xs[0]
    return str(len(xs)) + "/" + str(len(inner))

def main():
    m1()
    m2()
    m3()
    m4()
    m5()
    m6()
    m7()
    m8()
    m9()
    m10()
    m11()
    m12()
    m13()
    return 0

main()

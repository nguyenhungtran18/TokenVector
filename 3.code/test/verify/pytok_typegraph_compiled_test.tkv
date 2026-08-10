# -*- coding: utf-8 -*-
"""pytok + typegraph o dang DA BIEN DICH, tren dau vao nho tu chua.

Vi sao can rieng file nay: pytok_test.py va typegraph_test.py doi chieu
tren 420 file THAT cua repo (rat co gia tri), nhung vi vay chung phu thuoc
`CodeGraph/graph/code_graph_manifest.txt` tro RA NGOAI cay TokenVector -
khong chay duoc trong git worktree, va (truoc 2026-08-04) chung con khong
bien dich gi ca. Ket qua: typegraph.tkv 939 dong - file .tkv THAT lon nhat
du an - chua bao gio gap compiler.

File nay bu vao dung cho do: dau vao nho, tu chua, chay duoc o MOI moi
truong, va di qua _tkv_arbiter nen ca hai phia phai nhat tri. Hai file kia
giu nguyen vai tro doi chieu o quy mo that.

Ghi chu: `tokenize(src, out: "list[str]")` va `file_tokens(rel)` tra
'list[str]' nen KHONG co entry CLI nao goi thang duoc (tkv_compile.py:1055
- entry chi nhan tham so vo huong). Ta di qua `tok_run`/`run`, la hai ham
bao vo huong san co cua chinh hai cong cu do."""
import json
import sys

from _tkv_arbiter import run_both

# Mot file Python nho nhung co day du bay ma hai cong cu phai xu ly dung:
# docstring ba nhay, 'def' NAM TRONG chuoi, chuoi ket thuc bang chu 'f'
# (bay f-string da tung lam hong ca cong cu - xem parity_traps_test.py),
# lop long, ke thua.
SAMPLE = '\n'.join([
    '"""Mot module mau."""',
    '',
    'TEMPLATE = """',
    'def khong_phai_dinh_nghia():',
    '    pass',
    '"""',
    '',
    'def top_level(a, b):',
    '    """Cong hai so."""',
    '    if a == "def" or a == "class":',
    '        return 0',
    '    return helper(a) + b',
    '',
    'def helper(x):',
    '    return x',
    '',
    'class Base:',
    '    def method(self):',
    '        return helper(1)',
    '',
    'class Child(Base):',
    '    def method(self):',
    '        return top_level(1, 2)',
    '',
])

MANIFEST = "app/sample.py"


def main():
    fails = []

    # ---------- 1. pytok: bam file thanh dong token ----------
    res = run_both("pytok.tkv", "tok_run",
                   files={"app/sample.py": SAMPLE},
                   args=["app/sample.py", "T"], out_files=["T"])
    print("pytok :", res.line)
    if "tokens=" not in res.line:
        fails.append("tok_run khong tra ve thong ke: %r" % res.line)
    rows = [r for r in res.written["T"].split("\n") if r]
    if not rows:
        fails.append("pytok khong sinh dong token nao")
    # Bay f-string: 'def' va 'class' la chuoi ket thuc bang chu 'f'/'s'
    # trong dieu kien `a == "def" or a == "class"`. Neu bo tien xu ly
    # f-string viet de len thi so dong token se lech giua hai phia va
    # _tkv_arbiter da nem truoc khi toi day.

    # ---------- 2. typegraph: sinh canh tu manifest ----------
    res2 = run_both("typegraph.tkv", "run",
                    files={"M": MANIFEST, "app/sample.py": SAMPLE},
                    args=["M", "O"], out_files=["O"])
    print("typegraph:", res2.line)
    doc = json.loads(res2.written["O"])
    edges = doc.get("edges", [])
    kinds = {e.get("type") for e in edges}
    if "contains" not in kinds:
        fails.append("thieu canh 'contains': %s" % sorted(kinds))
    # Child ke thua Base -> phai co canh inherits
    inherits = [e for e in edges if e.get("type") == "inherits"]
    if not inherits:
        fails.append("khong sinh canh 'inherits' du co 'class Child(Base)'")
    # top_level goi helper -> phai co canh calls
    calls = [e for e in edges if e.get("type") == "calls"]
    if not calls:
        fails.append("khong sinh canh 'calls' nao du co loi goi that")
    # 'def khong_phai_dinh_nghia' nam TRONG chuoi ba nhay - khong duoc
    # tinh la dinh nghia.
    if any("khong_phai_dinh_nghia" in json.dumps(e) for e in edges):
        fails.append("'def' trong chuoi ba nhay bi tinh la dinh nghia that")

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: pytok va typegraph chay dung o dang DA BIEN DICH "
          "(canh contains/calls/inherits, khong nhan 'def' trong chuoi)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

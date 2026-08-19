# -*- coding: utf-8 -*-
"""Doi chieu impgraph.tkv voi ket qua tinh bang tay tren 1 cay thu muc gia.

2026-08-04: chuyen phan CO THE chuyen sang _tkv_arbiter (bien dich that +
doi chieu CPython). Truoc do test nay khong bien dich gi ca.

GIOI HAN CO THAT, ghi ro thay vi giau: entry CLI cua TokenVector CHI nhan
tham so VO HUONG (tkv_compile.py:1055 - "chi ho tro tham so VO HUONG
(i32/i64/f32/f64/str), khong ho tro mang/list/dict"). Nen:

  - dotted_from_rel/imported_module (str -> str) va main (str,str -> str)
    KIEM DUOC o dang da bien dich, va gio da kiem;
  - build_index/build_base_index/resolve_abs/resolve_rel nhan
    'list[str]'/'dict[str,str]' nen KHONG co entry CLI nao goi toi duoc.
    Chung chi chay duoi CPython o day. Muon kiem chung o dang bien dich
    thi phai viet ham BOC nhan/tra chuoi - viec do chua lam.

Day khong phai thieu sot cua bo test ma la mot khoang trong ve KHA NANG
KIEM CHUNG: mot lop ham that su khong the kiem o dang da bien dich neu
khong co ham boc."""

import io
import os
import sys
import types

from _tkv_arbiter import run_both

HERE = os.path.dirname(os.path.abspath(__file__))
TKV = os.path.join(HERE, "..", "..", "tools", "impgraph.tkv")

FAKE = {
    "pkg/__init__.py": "",
    "pkg/core.py": "import os\nimport json\nfrom pkg import util\n",
    "pkg/util.py": "from . import core\nfrom ..top import helper\n",
    "top.py": "import pkg.core\nfrom pkg.util import thing\nimport nowhere_at_all\n",
    "dup_a/shared.py": "import top\n",
    "dup_b/shared.py": "import top\n",
}

MANIFEST = "\n".join(FAKE.keys())


def load_cpython_only():
    """Chi cho cac ham nhan list/dict - xem GIOI HAN o docstring dau file."""
    src = io.open(TKV, encoding="utf-8").read()
    mod = types.ModuleType("impgraph")
    mod.__dict__["read_file"] = lambda p: FAKE[p] if p in FAKE else MANIFEST
    mod.__dict__["write_file"] = lambda p, c: None
    exec(compile(src, TKV, "exec"), mod.__dict__)
    return mod


def scalar_entry(entry, args):
    """Ham vo huong: doi chieu CPython voi ban DA BIEN DICH."""
    return run_both("impgraph.tkv", entry, files={}, args=args).line


def main():
    fails = []

    # ---------- 1. dotted_from_rel (DA BIEN DICH) ----------
    for rel, want in [("pkg/core.py", "pkg.core"), ("pkg/__init__.py", "pkg"),
                      ("top.py", "top")]:
        got = scalar_entry("dotted_from_rel", [rel])
        if got != want:
            fails.append("dotted_from_rel(%s)=%r want %r" % (rel, got, want))

    # ---------- 2. imported_module (DA BIEN DICH) ----------
    icases = [
        ("import os", "os"),
        ("import a.b as c", "a.b"),
        ("from a.b import c, d", "a.b"),
        ("from . import x", "."),
        ("from ..a import x", "..a"),
        ("    x = 1", ""),
        ("# import fake", ""),
    ]
    for ln, want in icases:
        got = scalar_entry("imported_module", [ln])
        if got != want:
            fails.append("imported_module(%r)=%r want %r" % (ln, got, want))

    # ---------- 3-5. CHI CPython: tham so list/dict, khong co entry CLI ----
    mod = load_cpython_only()
    paths = list(FAKE.keys())
    bidx = mod.build_base_index(paths)
    if bidx.get("shared") != mod.ambig_mark():
        fails.append("build_base_index: 'shared' phai la AMBIG, got %r"
                     % bidx.get("shared"))
    idx = mod.build_index(paths)
    got = mod.resolve_rel(".", "pkg/util.py", idx)
    if got != "pkg/__init__.py":
        fails.append("resolve_rel('.', pkg/util.py)=%r want pkg/__init__.py" % got)
    if mod.resolve_abs("pkg.core", idx, bidx) != "pkg/core.py":
        fails.append("resolve_abs('pkg.core') sai: %r"
                     % mod.resolve_abs("pkg.core", idx, bidx))
    if mod.resolve_abs("nowhere_at_all", idx, bidx) != "":
        fails.append("resolve_abs('nowhere_at_all') phai external")

    # ---------- 6. chay full (DA BIEN DICH, doi chieu ca file xuat ra) ----
    store = dict(FAKE)
    store["MANIFEST"] = MANIFEST
    res = run_both("impgraph.tkv", "main", files=store,
                   args=["MANIFEST", "out.json"], out_files=["out.json"])
    print("RESULT:", res.line)
    if "internal=" not in res.line:
        fails.append("main() khong tra ve thong ke")

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: ham vo huong + main() doi chieu o dang DA BIEN DICH; "
          "ham nhan list/dict chi chay duoc duoi CPython (xem GIOI HAN)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

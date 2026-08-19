# -*- coding: utf-8 -*-
"""Kiem tra tour.tkv: thu tu doc phai dung mach phu thuoc.

Dieu phai chung minh: file KHONG phu thuoc gi (foundation) luon dung
truoc file phu thuoc no; trong cung mot tang, file duoc nhieu nguoi
import hon thi dung truoc; test/isolated khong lot vao lo trinh."""

import json
import sys

from _tkv_arbiter import run_both


MANIFEST = "\n".join([
    "app/base_hot.py",    # foundation, 3 nguoi import
    "app/base_cold.py",   # foundation, 1 nguoi import
    "app/mid.py",         # core
    "app/main.py",        # entry
    "app/lonely.py",      # isolated - phai bi loai
    "tests/test_mid.py",  # test - phai bi loai
])

E = []
for src in ["app/mid.py", "app/main.py", "tests/test_mid.py"]:
    E.append('  {"source":"file:%s","target":"file:app/base_hot.py","type":"imports","weight":0.7},' % src)
E.append('  {"source":"file:app/mid.py","target":"file:app/base_cold.py","type":"imports","weight":0.7},')
E.append('  {"source":"file:app/main.py","target":"file:app/mid.py","type":"imports","weight":0.7}')
EDGES = '{ "edges": [\n' + "\n".join(E) + "\n ]}"

LAYERS = "\n".join([
    '{ "layers": [',
    '  {"name":"foundation","nodeIds":[', '   "file:app/base_hot.py",', '   "file:app/base_cold.py"', '  ]},',
    '  {"name":"core","nodeIds":[', '   "file:app/mid.py"', '  ]},',
    '  {"name":"entry","nodeIds":[', '   "file:app/main.py"', '  ]},',
    '  {"name":"test","nodeIds":[', '   "file:tests/test_mid.py"', '  ]},',
    '  {"name":"isolated","nodeIds":[', '   "file:app/lonely.py"', '  ]}',
    ' ]}',
])


def run_case():
    # 2026-08-04: qua _tkv_arbiter — truoc do test nay khong bien dich gi.
    res = run_both("tour.tkv", "run",
                   files={"M": MANIFEST, "E": EDGES, "L": LAYERS},
                   args=["M", "E", "L", "O"], out_files=["O"])
    return res.line, res.written["O"]


def main():
    fails = []
    line, out = run_case()
    print("RESULT:", line)
    doc = json.loads(out)

    seq = [nid[5:] for step in doc["tour"] for nid in step["nodeIds"]]
    print("thu tu:", seq)

    want = ["app/base_hot.py", "app/base_cold.py", "app/mid.py", "app/main.py"]
    if seq != want:
        fails.append("thu tu sai: %s, mong doi %s" % (seq, want))

    for bad in ("tests/test_mid.py", "app/lonely.py"):
        if bad in seq:
            fails.append("%s khong duoc nam trong lo trinh" % bad)

    # phu thuoc phai dung TRUOC nguoi dung no
    for a, b in [("app/base_hot.py", "app/mid.py"), ("app/base_cold.py", "app/mid.py"),
                 ("app/mid.py", "app/main.py")]:
        if seq.index(a) > seq.index(b):
            fails.append("%s phai doc truoc %s" % (a, b))

    # trong cung tang: nhieu nguoi import hon thi truoc
    if seq.index("app/base_hot.py") > seq.index("app/base_cold.py"):
        fails.append("file duoc import nhieu hon phai dung truoc")

    # moi tang deu phai co mat: neu foundation duoc lay khong gioi han thi
    # no chiem het suat va lo trinh khong bao gio den core/entry
    st = doc["stats"]
    for name in ("foundation", "core", "entry"):
        if st[name] == 0:
            fails.append("tang %s khong co file nao trong lo trinh" % name)

    orders = [s["order"] for s in doc["tour"]]
    if orders != list(range(1, len(orders) + 1)):
        fails.append("order khong lien tuc tu 1: %s" % orders)
    if any(not s["nodeIds"] for s in doc["tour"]):
        fails.append("co buoc rong")
    if any(not s["title"].strip() for s in doc["tour"]):
        fails.append("co buoc khong co tieu de")

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: thu tu dung mach phu thuoc, loai test/isolated, order lien tuc")
    return 0


if __name__ == "__main__":
    sys.exit(main())

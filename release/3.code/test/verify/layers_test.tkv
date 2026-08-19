# -*- coding: utf-8 -*-
"""Kiem tra layers.tkv tren mot do thi nho da biet truoc dap an.

Diem quan trong nhat: PHAN HOACH - moi file phai thuoc DUNG MOT tang,
khong sot, khong trung. Do la dieu kien de graph-reviewer kiem tra duoc.

2026-08-04: chuyen sang _tkv_arbiter.run_both. Truoc do test nay `exec`
file .tkv duoi CPython voi read_file/write_file gia va KHONG BIEN DICH GI
CA - xoa sach compiler thi no van xanh. Gio moi khang dinh ben duoi deu
chay tren ket qua ma CA HAI phia (CPython va ban bien dich) da phai nhat
tri, ke ca noi dung file xuat ra."""

import json
import sys

from _tkv_arbiter import run_both

#   app/main.py   -> app/svc.py -> app/util.py
#   app/lonely.py   khong dinh canh nao
#   tests/test_svc.py -> app/svc.py
MANIFEST = "app/main.py\napp/svc.py\napp/util.py\napp/lonely.py\ntests/test_svc.py\n"
EDGES = "\n".join([
    '{ "edges": [',
    '  {"source":"file:app/main.py","target":"file:app/svc.py","type":"imports","weight":0.7},',
    '  {"source":"file:app/svc.py","target":"file:app/util.py","type":"imports","weight":0.7},',
    '  {"source":"file:tests/test_svc.py","target":"file:app/svc.py","type":"imports","weight":0.7}',
    ' ]}',
])

WANT = {
    "app/main.py": "entry",        # khong ai import, co import
    "app/svc.py": "core",          # vua duoc import vua import
    "app/util.py": "foundation",   # duoc import, khong import gi
    "app/lonely.py": "isolated",   # khong canh nao
    "tests/test_svc.py": "test",   # uu tien tag test du no la entry
}


def run_case(manifest, edges):
    res = run_both("layers.tkv", "run",
                   files={"M": manifest, "E": edges},
                   args=["M", "E", "O"],
                   out_files=["O"])
    return res.line, res.written["O"]


def main():
    fails = []
    line, out = run_case(MANIFEST, EDGES)
    print("RESULT:", line)

    doc = json.loads(out)
    got = {}
    for layer in doc["layers"]:
        for nid in layer["nodeIds"]:
            path = nid[5:]
            if path in got:
                fails.append("file thuoc NHIEU tang: %s (%s va %s)" % (path, got[path], layer["name"]))
            got[path] = layer["name"]

    for path, want in WANT.items():
        if got.get(path) != want:
            fails.append("%s -> %r, mong doi %r" % (path, got.get(path), want))

    # phan hoach: khong sot file nao
    missing = set(WANT) - set(got)
    if missing:
        fails.append("file khong thuoc tang nao: %s" % sorted(missing))
    if len(got) != 5:
        fails.append("tong so file trong cac tang = %d, mong doi 5" % len(got))

    # canh KHONG phai 'imports' khong duoc tinh vao bac
    edges2 = EDGES.replace('"type":"imports","weight":0.7},\n  {"source":"file:tests/test_svc.py"',
                           '"type":"calls","weight":0.7},\n  {"source":"file:tests/test_svc.py"')
    _, out2 = run_case(MANIFEST, edges2)
    doc2 = json.loads(out2)
    got2 = {}
    for layer in doc2["layers"]:
        for nid in layer["nodeIds"]:
            got2[nid[5:]] = layer["name"]
    if got2.get("app/util.py") != "isolated":
        fails.append("canh 'calls' bi tinh nhu 'imports': app/util.py -> %r" % got2.get("app/util.py"))

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: phan tang dung, moi file thuoc dung 1 tang, chi dem canh imports")
    return 0


if __name__ == "__main__":
    sys.exit(main())

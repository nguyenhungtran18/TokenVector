# -*- coding: utf-8 -*-
"""Kiem tra impact.tkv - ban kinh anh huong va danh sach test can chay.

Cong cu nay tra loi cau hoi "sua cho nay thi gay o dau", nen sai o day
dan toi bo sot test - dung loai hong ma test sach khong bat duoc. Moi
khang dinh di kem mot phep BOM LOI co hau qua biet truoc.

Do thi mau:
    svc.run  ->  goi  ->  util.helper
    api.go   ->  goi  ->  svc.run
    web.top  ->  goi  ->  api.go
    deep.x   ->  goi  ->  web.top          (tang 4 - PHAI bi cat)
    test_svc.py  import  svc.py
    test_util.py goi thang util.helper
"""

import json
import sys

from _tkv_arbiter import run_both



def edge(src, tgt, typ):
    return '  {"source":"%s","target":"%s","type":"%s","weight":0.8},' % (src, tgt, typ)


F = "function:app/%s.py:%s"
CALLS = "\n".join(['{ "edges": ['] + [
    edge("file:app/util.py", F % ("util", "helper"), "contains"),
    edge("file:app/svc.py", F % ("svc", "run"), "contains"),
    edge("file:app/svc.py", F % ("svc", "phu"), "contains"),
    edge(F % ("svc", "run"), F % ("util", "helper"), "calls"),
    edge(F % ("api", "go"), F % ("svc", "run"), "calls"),
    edge(F % ("web", "top"), F % ("api", "go"), "calls"),
    edge(F % ("deep", "x"), F % ("web", "top"), "calls"),
    edge("function:tests/test_util.py:t_helper", F % ("util", "helper"), "calls"),
] + [' ]}'])

IMPORTS = "\n".join(['{ "edges": ['] + [
    edge("file:tests/test_svc.py", "file:app/svc.py", "imports"),
    edge("file:app/api.py", "file:app/svc.py", "imports"),
] + [' ]}'])

LAYERS = "\n".join([
    '{', ' "layers": [',
    '  {"name":"core","nodeIds":[',
    '   "file:app/svc.py",',
    '   "file:app/util.py"',
    '  ]},',
    '  {"name":"test","nodeIds":[',
    '   "file:tests/test_svc.py",',
    '   "file:tests/test_util.py"',
    '  ]},',
    '  {"name":"isolated","nodeIds":[',
    '   "file:app/lonely.py"',
    '  ]}',
    ' ]}',
])


def run_case(target, calls=CALLS, imports=IMPORTS, layers=LAYERS):
    # 2026-08-04: qua _tkv_arbiter — truoc do test nay khong bien dich gi.
    res = run_both("impact.tkv", "run",
                   files={"C": calls, "I": imports, "L": layers},
                   args=["C", "I", "L", target, "O"], out_files=["O"])
    line = res.line
    doc = json.loads(res.written["O"])
    by_lv = {l["level"]: set(l["nodes"]) for l in doc["levels"]}
    return line, doc, by_lv


def main():
    fails = []

    def check(cond, msg):
        if not cond:
            fails.append(msg)

    # ---------- 1. lan nguoc dung tang ----------
    line, doc, lv = run_case(F % ("util", "helper"))
    print("RESULT:", line)
    check(lv.get(1) == {F % ("svc", "run"), "function:tests/test_util.py:t_helper"},
          "tang 1 phai la nguoi goi truc tiep: %s" % lv.get(1))
    check(lv.get(2) == {F % ("api", "go")}, "tang 2 sai: %s" % lv.get(2))
    check(lv.get(3) == {F % ("web", "top")}, "tang 3 sai: %s" % lv.get(3))
    # Bom loi: deep.x o tang 4 - neu no lot vao thi gioi han tang khong chay.
    allnodes = set().union(*lv.values()) if lv else set()
    check(F % ("deep", "x") not in allnodes,
          "nut o tang 4 khong duoc lot vao (gioi han 3 tang khong chay)")

    # ---------- 2. test can chay ----------
    tests = set(doc["tests"])
    check("file:tests/test_util.py" in tests,
          "test goi THANG ham do phai co mat: %s" % tests)
    check("file:tests/test_svc.py" in tests,
          "test IMPORT file bi anh huong phai co mat: %s" % tests)

    # ---------- 3. bom loi: dao chieu canh calls ----------
    # Neu cong cu lan XUOI thay vi lan NGUOC thi ket qua khong doi.
    rev = CALLS.replace('"source":"function:app/svc.py:run","target":"function:app/util.py:helper"',
                        '"source":"function:app/util.py:helper","target":"function:app/svc.py:run"')
    _, _, lv2 = run_case(F % ("util", "helper"), calls=rev)
    check(F % ("svc", "run") not in set().union(*lv2.values()) if lv2 else True,
          "dao chieu canh: svc.run khong con la nguoi goi util.helper")

    # ---------- 4. muc tieu la FILE -> lay moi def ben trong ----------
    _, doc4, lv4 = run_case("file:app/svc.py")
    check(doc4["stats"]["nodes"] >= 3,
          "muc tieu file phai gom ca def ben trong (contains): %s" % doc4["stats"])
    check("file:tests/test_svc.py" in set(doc4["tests"]),
          "test import file do phai duoc liet ke")

    # ---------- 5. bom loi: bo nhan test khoi layers ----------
    # Neu danh sach test KHONG doi khi xoa tang test thi no khong doc layers.
    no_test = LAYERS.replace('"name":"test"', '"name":"khac"')
    _, doc5, _ = run_case(F % ("util", "helper"), layers=no_test)
    check(doc5["tests"] == [],
          "xoa tang test ma van liet ke test: %s" % doc5["tests"])

    # ---------- 6. chu trinh khong duoc treo ----------
    cyc = "\n".join(['{ "edges": [',
                     edge(F % ("a", "one"), F % ("b", "two"), "calls"),
                     edge(F % ("b", "two"), F % ("a", "one"), "calls"),
                     ' ]}'])
    _, doc6, _ = run_case(F % ("a", "one"), calls=cyc, imports='{ "edges": [ ]}')
    check(doc6["stats"]["nodes"] == 2, "chu trinh: moi nut chi dem 1 lan")

    # ---------- 7. muc tieu khong co trong graph ----------
    _, doc7, _ = run_case("function:khong/co.py:ai")
    check(doc7["stats"]["files"] == 1 and doc7["tests"] == [],
          "muc tieu la, khong duoc bia: %s" % doc7["stats"])

    if fails:
        print("FAIL: %d loi" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: lan nguoc dung tang, cat o tang 4, test qua goi-thang va qua "
          "import, chu trinh khong treo, muc tieu la khong bia")
    return 0


if __name__ == "__main__":
    sys.exit(main())

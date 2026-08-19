# -*- coding: utf-8 -*-
"""Kiem tra graphreview.tkv bang cach BOM GRAPH HONG co chu dich.

Mot bo kiem tra chi chay tren du lieu SACH khong chung minh duoc gi -
no se xanh ke ca khi moi phep kiem tra deu hong. Moi ca duoi day dam bao
dung 1 phep kiem tra phai kich hoat."""

import json
import sys

from _tkv_arbiter import run_both

MANIFEST = "app/a.py\napp/b.py\napp/lonely.py\n"

GOOD_IMPORTS = """{
 "edges": [
  {"source":"file:app/a.py","target":"file:app/b.py","type":"imports","weight":0.7}
 ]
}"""

GOOD_CALLS = """{
 "edges": [
  {"source":"file:app/a.py","target":"function:app/a.py:f","type":"contains","weight":1.0},
  {"source":"function:app/a.py:f","target":"function:app/b.py:g","type":"calls","weight":0.8}
 ]
}"""


GOOD_LAYERS = "\n".join([
    '{ "layers": [',
    '  {"name":"foundation","nodeIds":[',
    '   "file:app/b.py"',
    '  ]},',
    '  {"name":"entry","nodeIds":[',
    '   "file:app/a.py"',
    '  ]},',
    '  {"name":"isolated","nodeIds":[',
    '   "file:app/lonely.py"',
    '  ]}',
    ' ]}',
])


GOOD_TOUR = "\n".join([
    '{ "tour": [',
    '  {"order":1,"title":"foundation - app","nodeIds":[',
    '    "file:app/b.py"',
    '   ]},',
    '  {"order":2,"title":"entry - app","nodeIds":[',
    '    "file:app/a.py"',
    '   ]}',
    ' ]}',
])


def run_case(imports_doc, calls_doc, layers_doc=GOOD_LAYERS, tour_doc=GOOD_TOUR):
    files = {"M": MANIFEST, "I": imports_doc, "C": calls_doc}
    # layers_doc/tour_doc = None nghia la file KHONG TON TAI - cong cu phai
    # tu xu ly qua file_exists. Harness chi ghi nhung file duoc dua vao, nen
    # 'khong ton tai' o day la khong ton tai THAT tren dia, ca hai phia.
    if layers_doc is not None:
        files["L"] = layers_doc
    if tour_doc is not None:
        files["T"] = tour_doc
    # 2026-08-04: qua _tkv_arbiter — truoc do test nay khong bien dich gi.
    res = run_both("graphreview.tkv", "run", files=files,
                   args=["M", "I", "C", "R", "L", "T"], out_files=["R"])
    return res.line, json.loads(res.written["R"])


def main():
    fails = []

    # Ca 0 - graph SACH phai duoc duyet
    line, rep = run_case(GOOD_IMPORTS, GOOD_CALLS)
    if not rep["approved"]:
        fails.append("graph sach bi tu choi: %s" % rep["issues"])
    if rep["stats"]["orphan_files"] != 1:
        fails.append("phai phat hien dung 1 file mo coi (app/lonely.py), got %s"
                     % rep["stats"]["orphan_files"])
    if rep["warnings"] and not rep["approved"]:
        fails.append("warning khong duoc lam tu choi graph")

    # Cac ca HONG - moi ca phai bi tu choi
    broken = {
        "canh tro toi file khong co trong manifest":
            (GOOD_IMPORTS.replace("file:app/b.py", "file:app/ghost.py"), GOOD_CALLS),
        "loai canh ngoai enum":
            (GOOD_IMPORTS.replace('"imports"', '"teleports"'), GOOD_CALLS),
        "weight ngoai [0,1]":
            (GOOD_IMPORTS.replace("0.7", "7.0"), GOOD_CALLS),
        "canh trung lap":
            (GOOD_IMPORTS.replace(
                '{"source":"file:app/a.py","target":"file:app/b.py","type":"imports","weight":0.7}',
                '{"source":"file:app/a.py","target":"file:app/b.py","type":"imports","weight":0.7},\n'
                '  {"source":"file:app/a.py","target":"file:app/b.py","type":"imports","weight":0.7}'),
             GOOD_CALLS),
        "calls noi tu file thay vi function":
            (GOOD_IMPORTS, GOOD_CALLS.replace('"function:app/a.py:f","target":"function:app/b.py:g"',
                                              '"file:app/a.py","target":"function:app/b.py:g"')),
        "contains bac cau sang file khac":
            (GOOD_IMPORTS, GOOD_CALLS.replace('"target":"function:app/a.py:f","type":"contains"',
                                              '"target":"function:app/b.py:f","type":"contains"')),
        "tien to id la rac":
            (GOOD_IMPORTS.replace("file:app/a.py", "widget:app/a.py"), GOOD_CALLS),
        "graph rong":
            ('{"edges": []}', '{"edges": []}'),
    }
    for label, (idoc, cdoc) in broken.items():
        line, rep = run_case(idoc, cdoc)
        if rep["approved"]:
            fails.append("KHONG bat duoc: %s" % label)
        elif not rep["issues"]:
            fails.append("tu choi nhung khong neu ly do: %s" % label)

    # --- check vung phu TANG (truoc day reviewer khong co) ---
    layer_cases = {
        "file thuoc 2 tang": GOOD_LAYERS.replace(
            '   "file:app/a.py"', '   "file:app/a.py",\n   "file:app/b.py"'),
        "file khong thuoc tang nao": GOOD_LAYERS.replace(
            '   "file:app/lonely.py"', '   "file:app/khong_co_that.py"'),
        "tang chua file ngoai manifest": GOOD_LAYERS.replace(
            "file:app/lonely.py", "file:app/ghost.py"),
        "nhieu id tren mot dong (doc thieu am tham)": GOOD_LAYERS.replace(
            '   "file:app/b.py"', '   "file:app/b.py","file:app/lonely.py"'),
    }
    for label, doc in layer_cases.items():
        line, rep = run_case(GOOD_IMPORTS, GOOD_CALLS, doc)
        if rep["approved"]:
            fails.append("KHONG bat duoc loi phan tang: %s" % label)

    # khong co file phan tang -> canh bao, KHONG duoc tu choi
    line, rep = run_case(GOOD_IMPORTS, GOOD_CALLS, None)
    if not rep["approved"]:
        fails.append("thieu file phan tang khong duoc lam tu choi graph")
    if not any("phan tang" in w for w in rep["warnings"]):
        fails.append("thieu file phan tang ma khong canh bao")

    # --- check LO TRINH ---
    tour_cases = {
        "order khong lien tuc": GOOD_TOUR.replace('"order":2', '"order":5'),
        "buoc rong": GOOD_TOUR.replace('    "file:app/a.py"\n', ''),
        "tro toi file khong co that": GOOD_TOUR.replace("file:app/a.py", "file:app/ghost.py"),
    }
    for label, doc in tour_cases.items():
        line, rep = run_case(GOOD_IMPORTS, GOOD_CALLS, GOOD_LAYERS, doc)
        if rep["approved"]:
            fails.append("KHONG bat duoc loi lo trinh: %s" % label)

    line, rep = run_case(GOOD_IMPORTS, GOOD_CALLS, GOOD_LAYERS, None)
    if not rep["approved"]:
        fails.append("thieu file lo trinh khong duoc lam tu choi graph")

    print("da thu %d ca hong + %d ca phan tang + %d ca lo trinh + 1 ca sach"
          % (len(broken), len(layer_cases), len(tour_cases)))
    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: bat dung ca 8 kieu hong, khong bao dong gia tren graph sach")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# -*- coding: utf-8 -*-
"""Kiem tra ctxpack.tkv - goi ngu canh theo nhiem vu, cat theo han muc token.

Sai o day khong lam chuong trinh do, no lam TOI DOC NHAM VUNG CODE - loai
hong khong ai bao. Nen moi khang dinh di kem mot phep BOM LOI co hau qua
biet truoc.

Do thi mau (kich thuoc file dat sao cho ranh gioi han muc roi dung cho
minh muon kiem):
    goal.py   <- muc tieu
    near1.py, near2.py  dinh truc tiep (vong 1)
    far.py    dinh voi near1 (vong 2)
    xa.py     khong dinh gi ca - PHAI khong co mat
"""

import json
import sys

from _tkv_arbiter import run_both



def body(n_tokens):
    """File co do dai xap xi n_tokens (1 token ~ 4 ky tu)."""
    return "x = 1\n" * max(1, (n_tokens * 4) // 6)


FILES = {
    "goal.py": body(100),
    "near1.py": body(200),
    "near2.py": body(200),
    "far.py": body(100),
    "xa.py": body(50),
}

NODES = "\n".join(['{ "nodes": ['] + [
    '  {"id":"file:%s","type":"file","summary":"tom tat cua %s","tags":["python"]},' % (f, f)
    for f in FILES
] + [' ]}'])

IMPORTS = "\n".join(['{ "edges": [',
    '  {"source":"file:near1.py","target":"file:goal.py","type":"imports","weight":0.7},',
    '  {"source":"file:far.py","target":"file:near1.py","type":"imports","weight":0.7},',
    ' ]}'])

CALLS = "\n".join(['{ "edges": [',
    '  {"source":"function:goal.py:g","target":"function:near2.py:n","type":"calls","weight":0.8},',
    '  {"source":"file:goal.py","target":"function:goal.py:g","type":"contains","weight":1.0},',
    ' ]}'])

LAYERS = "\n".join(['{', ' "layers": [',
    '  {"name":"core","nodeIds":[',
    '   "file:goal.py",',
    '   "file:near1.py"',
    '  ]},',
    '  {"name":"test","nodeIds":[',
    '   "file:near2.py"',
    '  ]}',
    ' ]}'])


def run_case(target, budget, nodes=NODES, imports=IMPORTS, calls=CALLS,
             layers=LAYERS, files=None):
    store = dict(files or FILES)
    store.update({"N": nodes, "I": imports, "C": calls, "L": layers})
    # 2026-08-04: qua _tkv_arbiter — truoc do test nay khong bien dich gi.
    res = run_both("ctxpack.tkv", "run", files=store,
                   args=["N", "I", "C", "L", target, str(budget), "O"],
                   out_files=["O"])
    line = res.line
    doc = json.loads(res.written["O"])
    by = {e["file"][5:]: e for e in doc["files"]}
    return line, doc, by


def main():
    fails = []

    def check(cond, msg):
        if not cond:
            fails.append(msg)

    # ---------- 1. chon dung vong ----------
    line, doc, by = run_case("file:goal.py", 100000)
    print("RESULT:", line)
    check(by.get("goal.py", {}).get("vong") == 0, "muc tieu phai la vong 0")
    check(by.get("near1.py", {}).get("vong") == 1, "near1 phai la vong 1")
    check(by.get("near2.py", {}).get("vong") == 1,
          "near2 noi qua canh `calls` cung phai la vong 1")
    check(by.get("far.py", {}).get("vong") == 2, "far phai la vong 2")
    # Bom loi: xa.py khong dinh canh nao - lot vao la sai.
    check("xa.py" not in by, "file khong dinh canh nao khong duoc dua vao goi")

    # ---------- 2. summary lay tu nodes_full ----------
    check(by.get("goal.py", {}).get("summary") == "tom tat cua goal.py",
          "summary phai lay tu nodes_full: %r" % by.get("goal.py", {}).get("summary"))

    # ---------- 3. han muc cat dung ----------
    _, doc3, by3 = run_case("file:goal.py", 260)
    check(by3["goal.py"]["doc"] == "day-du", "muc tieu luon doc day du")
    full = [k for k, v in by3.items() if v["doc"] == "day-du"]
    check(len(full) < len(by3), "han muc 260 phai cat bot, khong the doc het")
    check(doc3["stats"]["token"] <= 260, "khong duoc vuot han muc khi muc tieu nho")
    # File bi cat VAN PHAI co ten + summary, khong duoc bien mat im lang.
    cut = [v for v in by3.values() if v["doc"] == "tom-tat"]
    check(all(v["summary"] for v in cut),
          "file bi cat van phai kem summary de biet la co ma chua doc")

    # ---------- 4. bom loi: muc tieu MOT MINH da vuot han muc ----------
    big = dict(FILES)
    big["goal.py"] = body(5000)
    _, doc4, by4 = run_case("file:goal.py", 100, files=big)
    check(by4["goal.py"]["doc"] == "day-du",
          "muc tieu phai doc day du KE CA khi mot minh no vuot han muc")
    check(doc4["stats"]["vuot_han_muc"] == 1,
          "vuot han muc ma khong bao: %s" % doc4["stats"])

    # ---------- 5. bom loi: doi tang de doi thu tu ----------
    # near1 (core) va near2 (test) cung 1 canh noi -> tang la tieu chi pha the.
    _, _, byA = run_case("file:goal.py", 100000)
    order_A = [e for e in [x["file"][5:] for x in
                            sorted([v for v in byA.values()], key=lambda z: 0)]]
    _, docA, _ = run_case("file:goal.py", 100000)
    seq_A = [e["file"][5:] for e in docA["files"]]
    swapped = LAYERS.replace('"file:near1.py"', '"file:TAM"').replace(
        '"file:near2.py"', '"file:near1.py"').replace('"file:TAM"', '"file:near2.py"')
    _, docB, _ = run_case("file:goal.py", 100000, layers=swapped)
    seq_B = [e["file"][5:] for e in docB["files"]]
    check(seq_A != seq_B,
          "doi tang cua 2 file ma thu tu khong doi -> tang khong duoc dung de pha the")

    # ---------- 6. bom loi: bo canh calls ----------
    no_calls = '{ "edges": [ ]}'
    _, _, by6 = run_case("file:goal.py", 100000, calls=no_calls)
    check("near2.py" not in by6,
          "near2 chi noi qua canh calls - bo canh do thi no phai bien mat")

    if fails:
        print("FAIL: %d loi" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: dung vong, loai file khong lien quan, cat theo han muc, "
          "muc tieu luon day du va bao khi vuot, tang dung de pha the")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# -*- coding: utf-8 -*-
"""Kiem tra domain.tkv tren mot do thi nho da biet truoc dap an.

Test SACH khong bat duoc gi: cong cu nao cung chay tron tru tren du lieu
dep. Nen moi khang dinh o day di kem mot phep BOM LOI - sua dau vao theo
mot cach da biet truoc hau qua, roi doi hoi ket qua phai doi dung nhu the.
Neu bom loi ma ket qua khong doi, phep do thua nhan la khong do gi ca."""

import json
import sys

from _tkv_arbiter import run_both

#   app/main.py  -> app/svc.py  -> app/util.py      (trong mien 'app')
#   app/svc.py   -> lib/core.py                     (app -> lib)
#   tests/t.py   -> app/svc.py                      (tests -> app)
#   setup.py     nam ngay goc -> mien '(goc)'
MANIFEST = "app/main.py\napp/svc.py\napp/util.py\nlib/core.py\ntests/t.py\nsetup.py\n"


def edges(rows):
    return "\n".join(['{ "edges": ['] + rows + [' ]}'])


def imp(src, tgt):
    return ('  {"source":"file:%s","target":"file:%s","type":"imports","weight":0.7},'
            % (src, tgt))


BASE = [
    imp("app/main.py", "app/svc.py"),
    imp("app/svc.py", "app/util.py"),
    imp("app/svc.py", "lib/core.py"),
    imp("tests/t.py", "app/svc.py"),
    imp("setup.py", "lib/core.py"),
]


def run_case(manifest, edge_rows):
    # 2026-08-04: qua _tkv_arbiter — CA HAI phia (CPython + ban bien dich)
    # phai nhat tri truoc khi cac khang dinh ben duoi duoc chay.
    res = run_both("domain.tkv", "run",
                   files={"M": manifest, "E": edges(edge_rows)},
                   args=["M", "E", "O"], out_files=["O"])
    line = res.line
    doc = json.loads(res.written["O"])
    by_name = {d["name"]: d for d in doc["domains"]}
    return line, doc, by_name


def deps(dom):
    return {p["domain"]: p["edges"] for p in dom["depends_on"]}


def users(dom):
    return {p["domain"]: p["edges"] for p in dom["used_by"]}


def main():
    fails = []

    def check(cond, msg):
        if not cond:
            fails.append(msg)

    line, doc, base = run_case(MANIFEST, BASE)
    print("RESULT:", line)

    # --- dap an da biet truoc ---
    check(set(base) == {"app", "lib", "tests", "(goc)"},
          "ten mien sai: %s" % sorted(base))
    check(base["(goc)"]["files"] == 1, "file o goc repo phai vao mien '(goc)'")
    check(base["app"]["files"] == 3, "app phai co 3 file")
    check(base["app"]["internal"] == 2, "app co 2 canh noi bo")
    check(base["app"]["out"] == 1 and base["app"]["in"] == 1,
          "app: 1 canh ra (lib), 1 canh vao (tests)")
    check(base["app"]["cohesion"] == 66, "cohesion app = 2*100/3 = 66")
    check(deps(base["app"]) == {"lib": 1}, "app phu thuoc lib")
    check(users(base["app"]) == {"tests": 1}, "tests dung app")
    check(base["lib"]["cohesion"] == 100, "lib khong import ra ngoai -> 100")

    # `api` la be mat bi mien KHAC import. app/util.py chi bi app import
    # nen KHONG phai api - day la khac biet giua 'api' va 'duoc import'.
    check(base["app"]["api"] == ["file:app/svc.py"],
          "api cua app chi gom svc.py, khong gom util.py: %s" % base["app"]["api"])
    check(base["app"]["entry"] == ["file:app/main.py"],
          "entry cua app la main.py: %s" % base["app"]["entry"])

    # --- bom loi 1: dao chieu mot canh ---
    # Neu cong cu lan lon source/target thi ket qua se KHONG doi.
    rev = [r for r in BASE if "app/svc.py" not in r or "lib/core.py" not in r]
    rev.append(imp("lib/core.py", "app/svc.py"))
    _, _, d1 = run_case(MANIFEST, rev)
    check(deps(d1["app"]) == {}, "dao chieu canh: app khong con phu thuoc lib")
    check(deps(d1["lib"]) == {"app": 1}, "dao chieu canh: lib phai phu thuoc app")
    check(d1["app"]["cohesion"] == 100, "dao chieu canh: cohesion app phai len 100")

    # --- bom loi 2: canh xuyen mien bien thanh canh noi bo ---
    inner = [r for r in BASE if "lib/core.py" not in r]
    inner.append(imp("app/svc.py", "app/util.py"))
    _, _, d2 = run_case(MANIFEST, inner)
    check(d2["app"]["out"] == 0, "khong con canh ra khoi app")
    check(deps(d2["app"]) == {}, "khong con phu thuoc mien khac")
    check(d2["lib"]["in"] == 0, "lib khong con ai dung")
    check(d2["lib"]["api"] == [], "lib khong con be mat cong khai")

    # --- bom loi 3: canh KHONG phai 'imports' phai bi bo qua ---
    noise = list(BASE) + [
        '  {"source":"file:tests/t.py","target":"file:lib/core.py","type":"calls","weight":0.5},'
    ]
    _, _, d3 = run_case(MANIFEST, noise)
    check(deps(d3["tests"]) == {"app": 1},
          "canh 'calls' khong duoc tinh vao quan he import: %s" % deps(d3["tests"]))

    # --- bom loi 4: file khong dinh canh nao ---
    lone = MANIFEST + "app/lonely.py\n"
    _, _, d4 = run_case(lone, BASE)
    check(d4["app"]["files"] == 4, "file moi phai duoc dem")
    check("file:app/lonely.py" not in d4["app"]["entry"],
          "file khong import gi ca thi KHONG phai entry")
    check("file:app/lonely.py" not in d4["app"]["api"],
          "file khong ai import thi KHONG phai api")

    # --- bom loi 5: doi mien cua mot file bang cach doi duong dan ---
    moved = MANIFEST.replace("lib/core.py", "vendor/core.py")
    moved_edges = [r.replace("lib/core.py", "vendor/core.py") for r in BASE]
    _, _, d5 = run_case(moved, moved_edges)
    check("lib" not in d5, "mien 'lib' phai bien mat khi doi thu muc")
    check(deps(d5["app"]) == {"vendor": 1}, "app phai phu thuoc 'vendor'")

    if fails:
        print("\nFAIL: %d loi" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: dap an dung, ca 5 phep bom loi deu lam ket qua doi dung nhu du kien")
    return 0


if __name__ == "__main__":
    sys.exit(main())

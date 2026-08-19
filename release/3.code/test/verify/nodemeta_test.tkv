# -*- coding: utf-8 -*-
"""Kiem tra nodemeta.tkv - nut FILE: summary / tags / complexity.

Cong cu nay la cong cu cuoi cung cua CodeGraph chua co test. No chay tron
tru suot nhieu thang, nhung "chay tron tru" khong phai bang chung: no doc
docstring bang cach quet dong, dung dung lop bay da tung cat cut summary
that o cho khac (`C#`, docstring mot dong, nhay don).

Moi khang dinh o day di kem mot phep BOM LOI: sua dau vao theo mot cach da
biet truoc hau qua, roi doi hoi ket qua phai doi dung nhu the."""

import json
import sys

from _tkv_arbiter import run_both


Q3 = '"""'
S3 = "'''"


def run_case(files):
    """files = {duong_dan: noi_dung}. Tra ve (dong ket qua, nodes, need)."""
    store = dict(files)
    store["M"] = "\n".join(files.keys())
    # 2026-08-04: qua _tkv_arbiter — truoc do test nay khong bien dich gi.
    res = run_both("nodemeta.tkv", "run", files=store,
                   args=["M", "N", "L"], out_files=["N", "L"])
    line = res.line
    written = res.written
    doc = json.loads(written["N"])
    by = {n["id"][5:]: n for n in doc["nodes"]}
    need = [x for x in written["L"].split("\n") if x]
    return line, by, need, doc["stats"]


def main():
    fails = []

    def check(cond, msg):
        if not cond:
            fails.append(msg)

    # ---------- 1. docstring cac dang ----------
    files = {
        # docstring MOT DONG: dau dong nam ngay tren cung dong
        "a/one.py": Q3 + "Cong cu chuan hoa duong dan cho toan bo du an." + Q3 + "\nimport os\nX = 1\n",
        # nhieu dong: chi lay CAU DAU
        "a/multi.py": Q3 + "Bo nap cau hinh tu dia.\nDong thu hai khong duoc lot vao summary." + Q3 + "\n",
        # nhay don cung phai nhan
        "a/single.py": S3 + "Bo dinh tuyen yeu cau toi cac provider." + S3 + "\n",
        # chu thich + dong trong DUNG TRUOC docstring
        "a/after_cmt.py": "# -*- coding: utf-8 -*-\n\n" + Q3 + "Bo dem su kien cho tang van chuyen." + Q3 + "\n",
        # KHONG co docstring -> missing, phai nam trong danh sach can LLM
        "a/none.py": "import os\n\n\n" + Q3 + "Chuoi nay KHONG phai module-docstring." + Q3 + "\n",
        # docstring qua ngan (<16 ky tu) -> coi nhu khong co
        "a/tiny.py": Q3 + "Tam." + Q3 + "\n",
    }
    line, by, need, stats = run_case(files)
    print("RESULT:", line)

    check(by["a/one.py"]["summary"] == "Cong cu chuan hoa duong dan cho toan bo du an.",
          "docstring mot dong: %r" % by["a/one.py"]["summary"])
    # Bay cu: nuot dau dong roi doc lan xuong code ben duoi.
    check("import os" not in by["a/one.py"]["summary"],
          "docstring mot dong doc lan sang code ben duoi")
    check(by["a/multi.py"]["summary"] == "Bo nap cau hinh tu dia.",
          "nhieu dong phai lay cau dau: %r" % by["a/multi.py"]["summary"])
    check(by["a/single.py"]["summary"] == "Bo dinh tuyen yeu cau toi cac provider.",
          "nhay don ''' khong duoc nhan: %r" % by["a/single.py"]["summary"])
    check(by["a/after_cmt.py"]["summary"] == "Bo dem su kien cho tang van chuyen.",
          "docstring sau chu thich khong duoc nhan: %r" % by["a/after_cmt.py"]["summary"])

    for rel in ("a/none.py", "a/tiny.py"):
        check(by[rel]["summary_source"] == "missing", "%s phai la 'missing'" % rel)
        check(by[rel]["summary"] == "", "%s khong duoc bia summary" % rel)
        check(rel in need, "%s phai nam trong danh sach can LLM" % rel)
    check(stats["can_llm"] == 2 and stats["summary_tu_docstring"] == 4,
          "thong ke sai: %s" % stats)

    # ---------- 2. bom loi: '#' giua cau ----------
    # Lop chan cua mergemeta tung cat cut 5 summary that chua "C#". O day
    # phai chac nodemeta KHONG lap lai loi do khi doc docstring.
    _, by2, _, _ = run_case({"a/sharp.py": Q3 + "Dich ma nguon sang C# roi bien dich lai." + Q3 + "\n"})
    check(by2["a/sharp.py"]["summary"] == "Dich ma nguon sang C# roi bien dich lai.",
          "'#' giua cau bi coi la mo dau chu thich: %r" % by2["a/sharp.py"]["summary"])

    # ---------- 3. bom loi: ky tu phai thoat trong JSON ----------
    # Neu json_escape hong thi json.loads o run_case NEM ngay, khong can assert.
    _, by3, _, _ = run_case({"a/esc.py": Q3 + 'Doc file c:\\tmp\\x va tra ve chuoi "raw" cho tang tren.' + Q3 + "\n"})
    check('"raw"' in by3["a/esc.py"]["summary"] and "c:\\tmp\\x" in by3["a/esc.py"]["summary"],
          "thoat chuoi lam mat noi dung: %r" % by3["a/esc.py"]["summary"])

    # ---------- 4. bom loi: complexity theo so dong THUC ----------
    body = "\n".join("x = %d" % i for i in range(60))
    noise = "\n".join(["# chu thich", "", "   ", "# nua"] * 40)
    _, by4, _, _ = run_case({
        "a/code60.py": body + "\n",                   # 60 dong ma  -> moderate
        "a/code49.py": "\n".join("x = %d" % i for i in range(49)) + "\n",   # -> simple
        "a/cmt.py": noise + "\nx = 1\n",              # 1 dong ma   -> simple
        "a/big.py": "\n".join("x = %d" % i for i in range(200)) + "\n",     # -> complex
    })
    check(by4["a/code60.py"]["complexity"] == "moderate", "60 dong ma phai la moderate")
    check(by4["a/code49.py"]["complexity"] == "simple", "49 dong ma phai la simple")
    check(by4["a/big.py"]["complexity"] == "complex", "200 dong ma phai la complex")
    # Bom loi: 160 dong chu thich/trong khong duoc lam file thanh phuc tap.
    check(by4["a/cmt.py"]["complexity"] == "simple",
          "chu thich va dong trong bi dem la ma: %s" % by4["a/cmt.py"]["complexity"])

    # ---------- 5. bom loi: tags suy tu duong dan ----------
    _, by5, _, _ = run_case({
        "pkg/tests/helper.py": "x = 1\n",
        "pkg/test_thing.py": "x = 1\n",
        "pkg/thing_test.py": "x = 1\n",
        "pkg/__init__.py": "x = 1\n",
        "setup.py": "x = 1\n",
        "prj/tools/gen.py": "x = 1\n",
        "prj/compiler/il.py": "x = 1\n",
        "prj/plain.py": "x = 1\n",
    })
    want_tags = {
        "pkg/tests/helper.py": {"python", "test"},
        "pkg/test_thing.py": {"python", "test"},
        "pkg/thing_test.py": {"python", "test"},
        "pkg/__init__.py": {"python", "entry-point", "barrel"},
        "setup.py": {"python", "build-system"},
        "prj/tools/gen.py": {"python", "tooling"},
        "prj/compiler/il.py": {"python", "compiler"},
        "prj/plain.py": {"python"},
    }
    for rel, want in want_tags.items():
        got = set(by5[rel]["tags"])
        check(got == want, "tags cua %s = %s, mong doi %s" % (rel, sorted(got), sorted(want)))

    # ---------- 6. bom loi: doi ten file phai doi tags ----------
    # Neu tags KHONG doi khi doi ten thi phep do o tren khong do gi ca.
    _, by6, _, _ = run_case({"pkg/thing.py": "x = 1\n"})
    check("test" not in by6["pkg/thing.py"]["tags"],
          "file thuong bi gan nhan test")

    if fails:
        print("FAIL: %d loi" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: docstring 4 dang, '#' giua cau, thoat JSON, complexity theo dong that, tags")
    return 0


if __name__ == "__main__":
    sys.exit(main())

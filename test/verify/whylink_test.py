# -*- coding: utf-8 -*-
"""Kiem tra whylink.tkv - noi ghi chu Obsidian voi file/mien trong graph.

Sai o day dan toi doc NHAM ly do cua mot doan code - ton kem hon la khong
co lien ket nao. Nen moi khang dinh di kem mot phep BOM LOI."""

import json
import sys

from _tkv_arbiter import run_both


CODE = "app/svc.py\napp/util.py\nlib/core.py\n"


def run_case(notes):
    store = {"M": "\n".join(notes.keys()), "C": CODE}
    store.update(notes)
    # 2026-08-04: qua _tkv_arbiter — truoc do test nay khong bien dich gi.
    # Luu y: ban cu dung `store.get(p, "")`, tuc doc file KHONG TON TAI thi
    # tra chuoi rong. Ban bien dich dung System.IO.File::ReadAllText, NEM
    # FileNotFoundException - giong het open() cua Python. Nen shim cu dang
    # che mot cho co the sap that. Nay ca hai phia deu doc file that.
    res = run_both("whylink.tkv", "run", files=store,
                   args=["M", "C", "O"], out_files=["O"])
    line = res.line
    doc = json.loads(res.written["O"])
    pairs = {(l["note"], l["target"], l["kieu"]) for l in doc["links"]}
    return line, doc, pairs


def main():
    fails = []

    def check(c, m):
        if not c:
            fails.append(m)

    line, doc, p = run_case({
        "v/a.md": "Quyet dinh: doi app/svc.py sang co che moi.",
        "v/b.md": "Ghi chu ve mien lib noi chung.",
        "v/c.md": "Khong nhac gi den ma nguon.",
        "v/d.md": "Ten gan giong: app/svc_old.py va app/svcx.py",
    })
    print("RESULT:", line)

    check(("v/a.md", "file:app/svc.py", "path") in p, "duong dan nguyen van phai thanh lien ket")
    check(("v/b.md", "domain:lib", "domain") in p, "ten mien phai thanh lien ket")
    check(not [x for x in p if x[0] == "v/c.md"], "ghi chu khong nhac gi khong duoc co lien ket")

    # Bom loi: `app/svc_old.py` CHUA chuoi `app/svc` nhung KHONG chua
    # `app/svc.py` - neu cong cu doi sanh long leo thi no se bat nham.
    check(("v/d.md", "file:app/svc.py", "path") not in p,
          "ten gan giong bi coi la trung: doi sanh khong con nguyen van")

    # Bom loi: doi ten file trong ghi chu -> lien ket phai BIEN MAT.
    _, _, p2 = run_case({"v/a.md": "Quyet dinh: doi app/KHAC.py sang co che moi."})
    check(not [x for x in p2 if x[2] == "path"],
          "doi ten file ma lien ket khong doi -> khong doi sanh gi ca")

    # Thong ke phai dem DUNG so ghi chu co lien ket, khong dem so lien ket.
    _, doc3, _ = run_case({"v/a.md": "app/svc.py va app/util.py va lib/core.py"})
    check(doc3["stats"]["ghi_chu_co_lien_ket"] == 1 and doc3["stats"]["lien_ket_path"] == 3,
          "thong ke sai: %s" % doc3["stats"])

    if fails:
        print("FAIL: %d loi" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: doi sanh nguyen van, khong bat ten gan giong, thong ke dung")
    return 0


if __name__ == "__main__":
    sys.exit(main())

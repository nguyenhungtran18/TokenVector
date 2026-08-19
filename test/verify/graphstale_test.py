# -*- coding: utf-8 -*-
"""Kiem tra graphstale.tkv: phai phat hien dung SUA / THEM / XOA.

Khong chi test 'khong doi thi bao khong doi' - phai chung minh no BAT
duoc tung loai thay doi, neu khong thi mot graph cu se bi coi la con moi."""

import sys

from _tkv_arbiter import ArbiterSession, run_both

# 2026-08-04: chuyen sang _tkv_arbiter. Truoc do test nay khong bien dich
# gi ca. Cong cu nay chay NHIEU BUOC noi tiep (ghi van tay o buoc 'save'
# roi doc lai chinh file do o buoc 'check') nen buoc dau dung ArbiterSession
# de giu trang thai; cac ca sau dung run_both voi van tay da thu duoc.


def check(files, fp=None):
    """Chay mot lan 'check', tra ve (dong ket qua, noi dung file CH)."""
    store = dict(files)
    if fp is not None:
        store["FP"] = fp
    res = run_both("graphstale.tkv", "run", files=store,
                   args=["M", "FP", "check", "CH"], out_files=["CH"])
    return res.line, res.written["CH"]


def main():
    fails = []
    base = {"M": "a.py\nb.py\n", "a.py": "print(1)\n", "b.py": "print(2)\n"}

    # 1. save roi check ngay -> phai bao CON DUNG
    session = ArbiterSession("graphstale.tkv", base)
    try:
        saved = session.run("run", ["M", "FP", "save", "CH"], out_files=["FP"])
        fp = saved.written["FP"]
    finally:
        session.close()

    line, ch = check(base, fp)
    if "CON DUNG" not in line:
        fails.append("khong doi gi ma bao da cu: %s" % line)
    if ch.strip():
        fails.append("khong doi gi ma van liet ke file: %r" % ch)

    # 2. SUA noi dung 1 file
    f2 = dict(base)
    f2["a.py"] = "print(999)\n"
    line, ch = check(f2, fp)
    if "sua,them,xoa=1,0,0" not in line or "SUA a.py" not in ch:
        fails.append("khong bat duoc SUA: %s | %r" % (line, ch))

    # 3. THEM file moi
    f3 = dict(base)
    f3["M"] = "a.py\nb.py\nc.py\n"
    f3["c.py"] = "print(3)\n"
    line, ch = check(f3, fp)
    if "sua,them,xoa=0,1,0" not in line or "THEM c.py" not in ch:
        fails.append("khong bat duoc THEM: %s | %r" % (line, ch))

    # 4. XOA file
    f4 = dict(base)
    f4["M"] = "a.py\n"
    line, ch = check(f4, fp)
    if "sua,them,xoa=0,0,1" not in line or "XOA b.py" not in ch:
        fails.append("khong bat duoc XOA: %s | %r" % (line, ch))

    # 5. chua co van tay -> moi file deu la THEM, phai bao DA CU
    line, ch = check(base, fp=None)
    if "DA CU" not in line or "sua,them,xoa=0,2,0" not in line:
        fails.append("thieu van tay ma khong bao da cu: %s" % line)

    # 6. DOI KIEU XUONG DONG (LF -> CRLF) ma noi dung y nguyen: KHONG
    #    duoc bao la da sua. Da do that: repo dat core.autocrlf=true nen
    #    `git checkout` doi het LF thanh CRLF, bam theo byte tho se bao
    #    ca 874 file deu "da sua" du khong ai dung vao.
    #    Ca nay gio con la phep kiem THAT cho ban sua read_file 2026-08-04
    #    (chuan hoa xuong dong): harness ghi file nguyen van, nen phia bien
    #    dich thuc su nhan CRLF tu dia chu khong phai chuoi da xu ly san.
    f6 = dict(base)
    f6["a.py"] = base["a.py"].replace("\n", "\r\n")
    f6["b.py"] = base["b.py"].replace("\n", "\r\n")
    line, ch = check(f6, fp)
    if "CON DUNG" not in line:
        fails.append("bao dong gia khi chi doi LF/CRLF: %s | %r" % (line, ch))

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: bat dung SUA/THEM/XOA/thieu-van-tay, khong bao dong gia")
    return 0


if __name__ == "__main__":
    sys.exit(main())

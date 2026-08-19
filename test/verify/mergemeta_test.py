# -*- coding: utf-8 -*-
"""Kiem tra mergemeta.tkv bang cac summary XAU co chu dich.

Summary do LLM sinh khong co chuan doi chieu, nen lop chan nay la thu duy
nhat ngan rac lot vao graph - phai chung minh no chan that."""

import sys

from _tkv_arbiter import run_both


NODES = "\n".join([
    '{',
    ' "nodes": [',
    '  {"id":"file:app/good.py","type":"file","summary":"","tags":["python"],"complexity":"simple","summary_source":"missing"},',
    '  {"id":"file:app/short.py","type":"file","summary":"","tags":["python"],"complexity":"simple","summary_source":"missing"},',
    '  {"id":"file:app/md.py","type":"file","summary":"","tags":["python"],"complexity":"simple","summary_source":"missing"},',
    '  {"id":"file:app/echo.py","type":"file","summary":"","tags":["python"],"complexity":"simple","summary_source":"missing"},',
    '  {"id":"file:app/preface.py","type":"file","summary":"","tags":["python"],"complexity":"simple","summary_source":"missing"},',
    '  {"id":"file:app/quote.py","type":"file","summary":"","tags":["python"],"complexity":"simple","summary_source":"missing"},',
    '  {"id":"file:app/tick.py","type":"file","summary":"","tags":["python"],"complexity":"simple","summary_source":"missing"},',
    '  {"id":"file:app/kept.py","type":"file","summary":"Da co san tu docstring that.","tags":["python"],"complexity":"simple","summary_source":"docstring"}',
    ' ]',
    '}',
])

TSV = "\n".join([
    "app/good.py\tDieu phoi cac tac vu nen va ghi log ket qua vao co so du lieu chung.",
    "app/short.py\tNgan qua.",
    "app/md.py\t**Quan ly** cac ket noi `socket` cho tang truyen tai du lieu chinh.",
    "app/echo.py\techo.py",
    "app/preface.py\tFile nay dung de quan ly vong doi cua tien trinh nen trong he thong.",
    # dau nhay kep trong summary phai duoc thoat, neu khong ca file JSON hong
    'app/quote.py\tThuc hien cac bai kiem tra "smoke test" cho toan bo tang API.',
    # backtick chi la dinh dang - phai GO RA va giu lai cau, khong duoc vut
    "app/tick.py\tXay dung thu vien dinh dang chuoi `fmt` dung cho tang ghi log.",
    # summary cho file da co docstring -> khong duoc ghi de
    "app/kept.py\tKhong duoc phep ghi de len summary da co.",
])


def run_case(nodes, tsv):
    # 2026-08-04: qua _tkv_arbiter - truoc do test nay khong bien dich gi.
    res = run_both("mergemeta.tkv", "run",
                   files={"N": nodes, "T": tsv},
                   args=["N", "T", "O", "R"], out_files=["O", "R"])
    line = res.line
    written = res.written
    return line, written["O"], written["R"]


def main():
    fails = []
    line, out, rej = run_case(NODES, TSV)
    print("RESULT:", line)

    # 1. summary tot phai duoc nhan, va doi nguon thanh 'llm'
    if '"summary":"Dieu phoi cac tac vu nen' not in out:
        fails.append("summary tot khong duoc nhan")
    if out.count('"summary_source":"llm"') != 3:
        fails.append("phai co dung 3 nut nguon 'llm', got %d" % out.count('"summary_source":"llm"'))

    # 2-5. tung loai rac phai bi tu choi
    for path, label in [("app/short.py", "qua ngan"), ("app/md.py", "ky tu markdown"),
                        ("app/echo.py", "chep lai ten file"), ("app/preface.py", "mo dau thua")]:
        if path not in rej:
            fails.append("KHONG chan duoc: %s (%s)" % (path, label))
        if '"id":"file:%s","type":"file","summary":""' % path not in out:
            fails.append("bi tu choi ma van ghi vao graph: %s" % path)

    # 6. khong duoc ghi de summary da co tu docstring
    if "Khong duoc phep ghi de" in out:
        fails.append("da ghi de len summary co san tu docstring")
    if "Da co san tu docstring that." not in out:
        fails.append("lam mat summary co san")

    # 7. dau nhay kep phai duoc thoat, va ket qua phai la JSON HOP LE
    if '\\"smoke test\\"' not in out:
        fails.append("dau nhay kep trong summary khong duoc thoat")
    try:
        import json
        json.loads(out)
    except Exception as e:
        fails.append("ket qua khong phai JSON hop le: %s" % e)

    # 8. backtick phai bi go ra, cau van duoc giu
    if "`" in out:
        fails.append("con backtick trong ket qua")
    if "Xay dung thu vien dinh dang chuoi fmt" not in out:
        fails.append("cau chi vuong backtick da bi vut thay vi go dinh dang")

    # 9. so luong nut khong doi
    if out.count('"id":"file:') != 8:
        fails.append("so nut thay doi: %d" % out.count('"id":"file:'))

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: nhan summary tot, chan 4 loai rac, khong ghi de docstring")
    return 0


if __name__ == "__main__":
    sys.exit(main())

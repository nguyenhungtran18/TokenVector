# -*- coding: utf-8 -*-
"""Kiem tra mergedefs.tkv bang cac summary XAU co chu dich.

Khac mergemeta_test o cho khoa la ID NUT dai, co nhieu dau hai cham, va
hai nut co the TRUNG TEN HAM o hai file khac nhau - gan nham summary la
lo hong that su cua bai nay."""

import json
import sys

from _tkv_arbiter import run_both


DEFS = "\n".join([
    '{',
    ' "nodes": [',
    '  {"id":"function:app/a.py:run","type":"function","name":"run","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/b.py:run","type":"function","name":"run","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:tiny","type":"function","name":"tiny","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:md","type":"function","name":"md","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:echo","type":"function","name":"echo","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:preface","type":"function","name":"preface","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:quote","type":"function","name":"quote","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:tick","type":"function","name":"tick","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:sharp","type":"function","name":"sharp","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:heading","type":"function","name":"heading","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"function:app/x.py:formula","type":"function","name":"formula","summary":"","complexity":"simple","summary_source":"missing"},',
    '  {"id":"class:app/x.py:Kept","type":"class","name":"Kept","summary":"Da co san tu docstring that.","complexity":"simple","summary_source":"docstring"}',
    ' ]',
    '}',
])

TSV = "\n".join([
    # hai ham CUNG TEN o hai file: moi cai phai nhan dung summary cua no
    "function:app/a.py:run\tDieu phoi cac tac vu nen va ghi log ket qua vao co so du lieu.",
    "function:app/b.py:run\tKhoi dong may chu HTTP va lang nghe tren cong da cau hinh.",
    "function:app/x.py:tiny\tNgan qua.",
    "function:app/x.py:md\t**Quan ly** cac ket noi `socket` cho tang truyen tai du lieu.",
    "function:app/x.py:echo\techo",
    "function:app/x.py:preface\tHam nay dung de quan ly vong doi cua tien trinh nen trong he thong.",
    'function:app/x.py:quote\tThuc hien cac bai kiem tra "smoke test" cho toan bo tang API.',
    "function:app/x.py:tick\tXay dung thu vien dinh dang chuoi `fmt` dung cho tang ghi log.",
    # '#' GIUA cau la noi dung that ("C#"), khong duoc chan
    "function:app/x.py:sharp\tDich cac dong Python sang C# roi ghi ra file ma nguon tuong ung.",
    # '#' DAU cau moi la tieu de markdown -> chan
    "function:app/x.py:heading\t# Tao va ghi ma nguon ra file dich theo cau hinh da nap.",
    # '*' trong cong thuc la noi dung; chi '**' in dam moi la markdown
    "function:app/x.py:formula\tTinh uoc chung lon nhat roi suy ra boi chung nho nhat qua a*b/gcd.",
    # nut da co summary tu docstring -> khong duoc ghi de
    "class:app/x.py:Kept\tKhong duoc phep ghi de len summary da co.",
])


def run_case(defs, tsv):
    # 2026-08-04: qua _tkv_arbiter - truoc do test nay khong bien dich gi.
    res = run_both("mergedefs.tkv", "run",
                   files={"N": defs, "T": tsv},
                   args=["N", "T", "O", "R"], out_files=["O", "R"])
    line = res.line
    written = res.written
    return line, written["O"], written["R"]


def main():
    fails = []
    line, out, rej = run_case(DEFS, TSV)
    print("RESULT:", line)

    nodes = json.loads(out)["nodes"] if out.strip().startswith("{") else []
    by_id = {n["id"]: n for n in nodes}

    # 1. hai ham trung ten phai nhan dung summary CUA MINH
    a = by_id.get("function:app/a.py:run", {}).get("summary", "")
    b = by_id.get("function:app/b.py:run", {}).get("summary", "")
    if not a.startswith("Dieu phoi"):
        fails.append("a.py:run nhan nham summary: %r" % a)
    if not b.startswith("Khoi dong may chu"):
        fails.append("b.py:run nhan nham summary: %r" % b)

    # 2. dung 6 nut nguon 'llm' (a.run, b.run, quote, tick, sharp, formula)
    n_llm = out.count('"summary_source":"llm"')
    if n_llm != 6:
        fails.append("phai co dung 6 nut nguon 'llm', got %d" % n_llm)

    # 2b. '#' GIUA cau la noi dung, khong duoc chan; '#' DAU cau thi phai chan
    if "sang C#" not in out:
        fails.append("chan nham summary chua 'C#' - day la noi dung, khong phai markdown")
    if "function:app/x.py:heading" not in rej:
        fails.append("khong chan duoc tieu de markdown dau cau")
    if "a*b/gcd" not in out:
        fails.append("chan nham cong thuc chua '*' - day la noi dung, khong phai markdown")

    # 3. tung loai rac phai bi tu choi VA khong lot vao graph
    for nid, label in [("function:app/x.py:tiny", "qua ngan"),
                       ("function:app/x.py:md", "ky tu markdown"),
                       ("function:app/x.py:echo", "chep lai ten ham"),
                       ("function:app/x.py:preface", "mo dau thua"),
                       ("function:app/x.py:heading", "tieu de markdown")]:
        if nid not in rej:
            fails.append("KHONG chan duoc: %s (%s)" % (nid, label))
        if by_id.get(nid, {}).get("summary", "x") != "":
            fails.append("bi tu choi ma van ghi vao graph: %s" % nid)

    # 4. khong ghi de summary co san tu docstring
    if "Khong duoc phep ghi de" in out:
        fails.append("da ghi de len summary co san tu docstring")
    if by_id.get("class:app/x.py:Kept", {}).get("summary") != "Da co san tu docstring that.":
        fails.append("lam mat summary co san")

    # 5. dau nhay kep phai duoc thoat va ket qua phai la JSON HOP LE
    if '\\"smoke test\\"' not in out:
        fails.append("dau nhay kep trong summary khong duoc thoat")
    try:
        json.loads(out)
    except Exception as e:
        fails.append("ket qua khong phai JSON hop le: %s" % e)

    # 6. backtick go ra, cau giu lai
    if "`" in out:
        fails.append("con backtick trong ket qua")
    if "Xay dung thu vien dinh dang chuoi fmt" not in out:
        fails.append("cau chi vuong backtick da bi vut thay vi go dinh dang")

    # 7. so nut khong doi
    if len(nodes) != 12:
        fails.append("so nut thay doi: %d" % len(nodes))

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: khoa id dai chinh xac, chan 4 loai rac, khong ghi de docstring")
    return 0


if __name__ == "__main__":
    sys.exit(main())

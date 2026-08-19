# -*- coding: utf-8 -*-
"""Kiem tra defmeta.tkv: summary cua ham/lop phai lay dung docstring THAT.

Cac bay da biet: docstring mot dong, docstring nhieu dong, chu ky ham
xuong nhieu dong, `def` nam trong chuoi ba nhay (khong phai dinh nghia),
va hai method trung ten o hai lop khac nhau PHAI la hai nut rieng
(id co ten lop: `function:<file>:<Lop>.<ten>`)."""

import json
import sys

from _tkv_arbiter import run_both


SRC = '\n'.join([
    '"""Docstring cua module - KHONG phai cua ham nao."""',
    '',
    'def one_line():',
    '    """Tra ve mot gia tri co dinh."""',
    '    return 1',
    '',
    'def multi(',
    '    a,',
    '    b,',
    '):',
    '    """Cong hai so lai voi nhau.',
    '    Dong thu hai khong duoc lot vao cau dau."""',
    '    return a + b',
    '',
    'def no_doc():',
    '    return 2',
    '',
    'def sharp():',
    '    """Dich sang C# roi bien dich lai."""',
    '    return 5',
    '',
    'class Thing:',
    '    """Mot thu gi do co ich."""',
    '',
    '    def method(self):',
    '        """Method cua Thing."""',
    '        return 3',
    '',
    'TEMPLATE = """',
    'def fake_in_string():',
    '    """',
    '',
    'class Other:',
    '    def method(self):',
    '        """Trung ten voi Thing.method - phai la nut RIENG."""',
    '        return 4',
    '',
    '    def with_nested(self):',
    '        """Co mot lop dinh nghia ngay trong than ham."""',
    '        class Inner:',
    '            def deep(self):',
    '                """Method cua lop long."""',
    '                return 6',
    '        return Inner',
    '',
    '    def after_nested(self):',
    '        """Dinh nghia SAU lop long - van phai thuoc Other."""',
    '        return 7',
])

MANIFEST = "app/x.py"


def run_case(src):
    # 2026-08-04: qua _tkv_arbiter — truoc do test nay khong bien dich gi.
    res = run_both("defmeta.tkv", "run",
                   files={"M": MANIFEST, "app/x.py": src},
                   args=["M", "O"], out_files=["O"])
    return res.line, res.written["O"]


def main():
    fails = []
    line, out = run_case(SRC)
    print("RESULT:", line)
    doc = json.loads(out)
    by = {n["id"]: n for n in doc["nodes"]}
    for k in sorted(by):
        print("   %-28s %-9s %s" % (k, by[k]["summary_source"], by[k]["summary"][:60]))

    want = {
        "function:app/x.py:one_line": "Tra ve mot gia tri co dinh.",
        "function:app/x.py:multi": "Cong hai so lai voi nhau.",
        "class:app/x.py:Thing": "Mot thu gi do co ich.",
        "function:app/x.py:Thing.method": "Method cua Thing.",
        # '#' trong docstring KHONG duoc coi la mo dau chu thich
        "function:app/x.py:sharp": "Dich sang C# roi bien dich lai.",
    }
    for nid, summ in want.items():
        if nid not in by:
            fails.append("thieu nut %s" % nid)
        elif by[nid]["summary"] != summ:
            fails.append("%s summary = %r, mong doi %r" % (nid, by[nid]["summary"], summ))

    if by.get("function:app/x.py:no_doc", {}).get("summary_source") != "missing":
        fails.append("ham khong co docstring phai duoc danh dau 'missing'")
    if by.get("function:app/x.py:no_doc", {}).get("summary"):
        fails.append("ham khong co docstring khong duoc bia summary")

    if "function:app/x.py:fake_in_string" in by:
        fails.append("'def' nam trong chuoi ba nhay bi coi la dinh nghia that")

    # Id co ten lop: hai method trung ten la HAI nut, khong con va cham.
    # KHONG duoc ghi de summary cua cai dau
    if doc["stats"]["collisions"] != 0:
        fails.append("khong duoc con va cham nao, got %d" % doc["stats"]["collisions"])
    for nid, want in [("function:app/x.py:Thing.method", "Method cua Thing."),
                      ("function:app/x.py:Other.method", "Trung ten voi Thing.method - phai la nut RIENG.")]:
        if nid not in by:
            fails.append("thieu nut %s" % nid)
        elif by[nid].get("summary") != want:
            fails.append("%s co summary sai: %r" % (nid, by[nid].get("summary")))
    # Lop LONG trong than method: lop dang mo phai duoc TRA VE, khong bi xoa
    # trang. Bo qua dieu nay thi moi def dinh nghia sau do mat ten lop trong
    # id, va canh cua typegraph tro toi mot nut khong ton tai.
    if "function:app/x.py:Inner.deep" not in by:
        fails.append("method cua lop long phai co id 'Inner.deep'")
    if "function:app/x.py:Other.after_nested" not in by:
        fails.append("def sau lop long van phai thuoc Other, khong duoc mat ten lop")
    if "function:app/x.py:after_nested" in by:
        fails.append("def sau lop long bi ghi id KHONG co ten lop")

    # ten tran van phai giu nguyen de doc duoc
    if by.get("function:app/x.py:Thing.method", {}).get("name") != "method":
        fails.append("truong 'name' phai la ten tran, khong phai ten day du")

    # docstring nhieu dong: chi lay CAU DAU
    if "Dong thu hai" in by.get("function:app/x.py:multi", {}).get("summary", ""):
        fails.append("lay ca dong thu hai cua docstring nhieu dong")

    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: docstring cac dang / chu ky nhieu dong / def trong chuoi / id co ten lop")
    return 0


if __name__ == "__main__":
    sys.exit(main())

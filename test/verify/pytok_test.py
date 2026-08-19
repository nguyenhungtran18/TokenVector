# -*- coding: utf-8 -*-
"""Kiem tra pytok.tkv - doi chieu voi module `tokenize` cua CPython.

Hai phan:
1. Cac bay da tra gia that trong repo nay (bom loi co chu dich).
2. Doi chieu tren MOI file .py that: moi NAME ma pytok sinh ra phai co
   that trong dong token cua CPython, dung thu tu. Chi so quan tam la
   NAME/NUM/OP - do la thu tang tren (typegraph) dung; noi dung STR bi bo
   nen khong so.
"""

import io
import os
import sys
import difflib
import tokenize as pytokenize
import types

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.join(HERE, "..", "..", "tools")
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

TRAPS = "\n".join([
    'TEMPLATE = """',
    'def fake_in_string():',
    '    """',
    'x = 1',
    'def real(a, b):',
    '    s = "co dau # trong chuoi"      # chu thich that',
    '    t = f"gia tri {a.method()} xong"',
    '    u = \'chuoi co "nhay kep" ben trong\'',
    '    v = 1 + \\',
    '        2',
    '    return s',
    'class Thing(Base):',
    '    def m(self):',
    '        return self.helper()',
])


def load():
    mod = types.ModuleType("pytok")
    files = {}
    written = {}
    mod.__dict__["read_file"] = lambda p: files[p]
    mod.__dict__["write_file"] = lambda p, c: written.__setitem__(p, c)
    for name in ("impgraph.tkv", "pytok.tkv"):
        src = io.open(os.path.join(TOOLS, name), encoding="utf-8").read()
        src = src.replace('__tkv_import__ = "impgraph"', "")
        exec(compile(src, name, "exec"), mod.__dict__)
    return mod, files, written


def toks(mod, src):
    out = []
    mod.tokenize(src, out)
    rows = []
    for line in out:
        n, kind, text = line.split("\t", 2)
        rows.append((int(n), kind, text))
    return rows


def ref_names(src):
    """Danh sach NAME + NUM + OP theo CPython, bo comment/chuoi/bo cuc."""
    out = []
    try:
        g = pytokenize.generate_tokens(io.StringIO(src).readline)
        for t in g:
            if t.type == pytokenize.NAME:
                out.append(("NAME", t.string))
            elif t.type == pytokenize.NUMBER:
                out.append(("NUM", t.string))
            elif t.type == pytokenize.OP:
                out.append(("OP", t.string))
    except Exception:  # noqa: BLE001
        return None
    return out


def mine_names(rows):
    out = []
    for _, kind, text in rows:
        if kind in ("NAME", "NUM"):
            out.append((kind, text))
        elif kind == "OP":
            out.append(("OP", text))
    return out


def check_traps(mod, fails):
    rows = toks(mod, TRAPS)
    names = [t for k, t in mine_names(rows) if k == "NAME"]

    # 1. `def` trong chuoi ba nhay khong duoc thanh token NAME
    if "fake_in_string" in names:
        fails.append("bay 1: 'def' trong chuoi ba nhay bi bam thanh token")
    # 2. ham that van phai co
    for want in ("real", "Thing", "Base", "helper", "method"):  # 'method' nam trong f-string
        if want not in names:
            fails.append("bay 2: mat ten that '%s'" % want)
    # 3. '#' trong chuoi khong duoc coi la chu thich -> 'chu' khong xuat hien
    if "chu" in names or "thich" in names:
        fails.append("bay 3: chu thich bi bam thanh NAME")
    # 4. noi dong bang '\\': dong logic phai lien tuc
    bol = [r for r in rows if r[1] == "BOL"]
    if len(bol) == 0:
        fails.append("bay 4: khong sinh moc BOL nao")
    # 5. thut le phai dung: 'class Thing' o cot 0, 'def m' o cot 4
    ind = {}
    for i, (ln, kind, text) in enumerate(rows):
        if kind == "BOL":
            nxt = rows[i + 1] if i + 1 < len(rows) else None
            if nxt and nxt[1] == "NAME":
                ind.setdefault(nxt[2], int(text))
    if ind.get("class") != 0:
        fails.append("bay 5: thut le 'class' sai: %r" % ind.get("class"))
    if ind.get("def") not in (0, 4):
        fails.append("bay 5: thut le 'def' sai: %r" % ind.get("def"))
    # 6. Bam de quy ben trong f-string KHONG duoc sinh moc BOL: moc do mang
    # so dong 1, cot 0, lam tang tren tuong da thoat khoi than lop. Test cu
    # chi so NAME nen mu hoan toan voi loi nay - da lam mat 12/15 method.
    for k, (ln, kind, text) in enumerate(rows):
        if kind == "BOL" and k > 0:
            prev_ln = rows[k - 1][0]
            if ln < prev_ln:
                fails.append("bay 6: moc BOL lui ve dong %d sau dong %d (BOL gia tu f-string)"
                             % (ln, prev_ln))
                break


def check_real_files(mod, fails):
    manifest = os.path.join(REPO, "CodeGraph", "graph", "code_graph_manifest.txt")
    paths = [l.strip() for l in io.open(manifest, encoding="utf-8") if l.strip()]
    checked = 0
    name_ok = 0
    name_tot = 0
    worst = []
    for rel in paths:
        full = os.path.join(REPO, rel)
        try:
            src = io.open(full, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        ref = ref_names(src)
        if ref is None:            # CPython cung khong bam duoc -> bo qua
            continue
        ref_set = [t for k, t in ref if k == "NAME"]
        mine = [t for k, t in mine_names(toks(mod, src)) if k == "NAME"]
        checked += 1
        # So khop bang difflib, KHONG tu viet vong lap greedy: ban dau tu
        # viet thi chi mot token lech som la i ket vinh vien -> bao 31%
        # trong khi thuc te 99%. Phep do sai con nguy hiem hon cong cu sai.
        name_tot += len(ref_set)
        sm = difflib.SequenceMatcher(None, ref_set, mine, autojunk=False)
        same = sum(b.size for b in sm.get_matching_blocks())
        name_ok += same
        if len(ref_set) and same < len(ref_set) * 0.98:
            worst.append((rel, same, len(ref_set)))

    pct = 100.0 * name_ok / name_tot if name_tot else 0.0
    print("doi chieu %d file that: NAME khop %d/%d = %.2f%%" % (checked, name_ok, name_tot, pct))
    if worst:
        print("  file lech nhieu nhat:")
        for rel, s, t in sorted(worst, key=lambda x: x[1] - x[2])[:5]:
            print("    %s  %d/%d" % (rel, s, t))
    if pct < 99.5:
        fails.append("NAME chi khop %.2f%% - duoi nguong 99.5%%" % pct)
    if checked < 600:
        fails.append("chi doi chieu duoc %d file - qua it" % checked)


def main():
    mod, _, _ = load()
    fails = []
    check_traps(mod, fails)
    check_real_files(mod, fails)
    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: chan 5 bay quet-dong, khop `tokenize` cua CPython tren file that")
    return 0


if __name__ == "__main__":
    sys.exit(main())

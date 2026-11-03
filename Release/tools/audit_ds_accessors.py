# -*- coding: utf-8 -*-
"""Ra soat moi call site `ea_ds`/`eb_ds`/`ec_ds` trong compiler: co bang chung
kind dung truoc khi doc o khong.

BOI CANH (2026-11-03): `_p6_co_f64_cay` trong `il_features/control_flow.tkv`
dung `eb_ds` lam ham duyet cay tong quat. Tren node `var` o 2 la TEN BIEN, nen
no goi `int("ctx")` va nem `FormatException` khong noi duoc node/kind nao; loi
nam im tu 2026-10-29 va phai bisect ca cay tu-host moi tim ra. Tu commit
`131942d` (`expr_row.tkv`) ba accessor tu kiem `KHUON` va nem `SyntaxError` co
ten kind, nen loai loi nay khong con im lang. Cong cu nay de RA soat CHU DONG:
no chi ra nhung cho ma kind khong duoc bao dam o bat ky tang nao.

Ba tang phan loai, tu manh den yeu:

  GUARDED_ARG   trong CHINH ham do co `ekind(<arg>) == '<kind>'` (hoac `!=`),
                hoac `<arg> = ekind(...)` roi alias duoc so sanh, hoac `<arg>`
                den tu `mkN('<kind>'...)` ngay phia tren.
  GUARDED_FN    ham co dispatch theo kind (`ekind(` xuat hien trong than) nhung
                khong thay tren dung tham so nay - thuong la `tag = ekind(node)`
                roi `elif tag == 'index': eb_ds(node)`.
  REGISTERED    ham duoc DANG KY theo kind (`register_stmt_codegen(reg,
                'call_stmt', fn)`, `EXPR_CODEGEN['dict_lit'] = fn`, `'kind': fn`
                trong dict literal) nen no chi duoc goi khi node dung kind.
  MANUAL        khong co bang chung nao o tren -> phai doc tay.

Thu tu uu tien: REGISTERED thang GUARDED_ARG (dang ky la bao dam manh hon),
va mot cho co the vua REGISTERED vua GUARDED_ARG - bao cao ghi ca hai.

DAY LA CONG CU TRIAGE, KHONG PHAI GATE: no la phan tich TINH tren van ban
nguon, khong phai trinh phan tich AST, nen co the bo sot cach kiem kind la
(vd kiem qua bien trung gian long nhau, qua `KHUON` lookup dong). Nguoc lai no
khong bao gio bao "AN TOAN" - mot danh sach MANUAL rong chi co nghia la moi
cho deu co bang chung tinh.

Cach dung (chay tu `Release/`):

    python tools/audit_ds_accessors.py            # tong ket + danh sach MANUAL
    python tools/audit_ds_accessors.py -v         # in ca tung call site
    python tools/audit_ds_accessors.py --stage    # chi dem theo tang

Bang chung dong thoi (manh hon nhieu): guard trong accessor (commit 131942d)
bien moi vi pham con lai thanh SyntaxError co ten kind khi compiler tu bien
dich - xem `tools/vong.exe` (fixpoint IL_IDENTICAL) va `tools/testkit_gate.ps1`.
"""
import argparse
import glob
import re

CALL_RE = re.compile(r"\b(ea_ds|eb_ds|ec_ds)\(")
DEF_RE = re.compile(r"^def\s+(\w+)\s*\(")

# Bang chung kiem kind ngay tren DUNG tham so.
EKIND_CMP = r"ekind\(\s*%s\s*\)\s*(==|!=)\s*'[a-z_0-9]+'"
MKN_HEAD = re.compile(r"mk[234]\('([a-z_0-9]+)'")

# Dang ky dispatch theo kind: register_xxx(reg, 'kind', fn) / TABLE['kind'] = fn
# / 'kind': fn trong dict literal.
REG_PATTERNS = [
    # register_xxx(reg, 'kind', fn)
    re.compile(r"register_\w+\(\s*reg\s*,\s*'([a-z_0-9]+)'\s*,\s*(\w+)"),
    # register_xxx(reg, 'kieu_nhan', 'ten_method', fn[, ...])
    re.compile(r"register_\w+\(\s*reg\s*,\s*'([a-z_0-9]+)'\s*,\s*'[a-z_0-9]+'\s*,\s*(\w+)"),
    re.compile(r"[A-Z_]+\[\s*['\"]([a-z_0-9]+)['\"]\s*\]\s*=\s*(\w+)"),
    re.compile(r"['\"]([a-z_0-9]+)['\"]\s*:\s*(\w+)\s*[,}]"),
]


def arg_of(line, start):
    """Tham so trong ngoac (tinh long nhau). '' neu ngoac khong kin tren dong."""
    depth = 1
    i = start
    while i < len(line):
        c = line[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return line[start:i].strip()
        i += 1
    return ""


def functions_of(src):
    """[(ten, dong_bat_dau, dong_ket_thuc)] theo moc `def ` o cot 0."""
    marks = []
    for ln, line in enumerate(src, 1):
        m = DEF_RE.match(line)
        if m:
            marks.append((m.group(1), ln))
    return [(name, ln, marks[i + 1][1] - 1 if i + 1 < len(marks) else len(src))
            for i, (name, ln) in enumerate(marks)]


def owner_of(ln, funcs):
    for name, a, b in funcs:
        if a <= ln <= b:
            return name
    return "<module>"


def registration_map(paths):
    """func -> set(kind) tu cac bang dang ky dispatch trong toan compiler."""
    f2k = {}
    for p in paths:
        for line in open(p, encoding="utf-8", errors="replace"):
            if line.lstrip().startswith("#"):
                continue
            for pat in REG_PATTERNS:
                for m in pat.finditer(line):
                    f2k.setdefault(m.group(2), set()).add(m.group(1))
    return f2k


def classify():
    paths = sorted(set(glob.glob("compiler_bootstrap/**/*.tkv", recursive=True)))
    f2k = registration_map(paths)
    rows = []
    for p in paths:
        src = open(p, encoding="utf-8", errors="replace").read().split("\n")
        funcs = functions_of(src)
        for ln, line in enumerate(src, 1):
            if DEF_RE.match(line):
                continue  # chinh dong dinh nghia khong phai call site
            for cm in CALL_RE.finditer(line):
                arg = arg_of(line, cm.end())
                if arg == "":
                    continue  # ngoac mo qua nhieu dong - bo qua
                owner = owner_of(ln, funcs)
                start, end = 1, len(src)
                for name, a, b in funcs:
                    if name == owner:
                        start, end = a, b
                        break
                body = "\n".join(src[start - 1:end])
                head = "\n".join(src[start - 1:ln])
                esc = re.escape(arg)

                guarded_arg = bool(re.search(EKIND_CMP % esc, body)) \
                    or bool(MKN_HEAD.search(head))
                if not guarded_arg:
                    am = re.search(r"(\w+)\s*=\s*ekind\(\s*%s\s*\)" % esc, body)
                    if am and re.search(r"\b%s\s*(==|!=)" % re.escape(am.group(1)), body):
                        guarded_arg = True

                kinds = f2k.get(owner, set())
                if kinds:
                    verdict = "REGISTERED"
                elif guarded_arg:
                    verdict = "GUARDED_ARG"
                elif "ekind(" in body:
                    verdict = "GUARDED_FN"
                else:
                    verdict = "MANUAL"
                rows.append({
                    "verdict": verdict,
                    "path": p.replace("\\", "/"),
                    "line": ln,
                    "fn": cm.group(1),
                    "arg": arg,
                    "owner": owner,
                    "kinds": ",".join(sorted(kinds)),
                })
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="in tung call site, khong chi tong ket")
    ap.add_argument("--stage", action="store_true",
                    help="chi in so luong theo tung tang phan loai")
    ap.add_argument("--show", type=int, default=0, metavar="N",
                    help="in N dong ngu canh quanh moi call site MANUAL (de doc tay)")
    args = ap.parse_args()

    rows = classify()
    order = ["REGISTERED", "GUARDED_ARG", "GUARDED_FN", "MANUAL"]
    counts = {k: 0 for k in order}
    for r in rows:
        counts[r["verdict"]] += 1

    print("TONG %d call site ea_ds/eb_ds/ec_ds trong compiler_bootstrap/" % len(rows))
    for k in order:
        print("  %-13s %4d" % (k, counts[k]))
    if args.stage:
        return

    manual = [r for r in rows if r["verdict"] == "MANUAL"]
    if manual:
        print()
        print("--- MANUAL: khong thay bang chung kiem kind (%d) - doc tay ---" % len(manual))
        cache = {}
        for r in manual:
            print("%s:%d  %s(%s)  in %s()" % (r["path"], r["line"], r["fn"], r["arg"], r["owner"]))
            if not args.show:
                continue
            if r["path"] not in cache:
                cache[r["path"]] = open(r["path"], encoding="utf-8", errors="replace") \
                    .read().split("\n")
            src = cache[r["path"]]
            lo = max(0, r["line"] - 1 - args.show)
            hi = min(len(src), r["line"] + args.show)
            for k in range(lo, hi):
                mark = ">>" if k == r["line"] - 1 else "  "
                print("   %s %5d| %s" % (mark, k + 1, src[k].rstrip()))
            print()
    else:
        print("\nKhong con call site MANUAL: moi cho deu co bang chung tinh.")

    if args.verbose:
        for verdict in ("GUARDED_FN", "GUARDED_ARG", "REGISTERED"):
            sel = [r for r in rows if r["verdict"] == verdict]
            print("\n--- %s (%d) ---" % (verdict, len(sel)))
            for r in sel:
                tail = ("  kinds=" + r["kinds"]) if r["kinds"] else ""
                print("%s:%d  %s(%s)  in %s()%s"
                      % (r["path"], r["line"], r["fn"], r["arg"], r["owner"], tail))


if __name__ == "__main__":
    main()

# -*- coding: utf-8 -*-
"""tkv_guide - CONG CU de harness (agent) viet code TokenVector nhanh va DUNG.

## Vi sao can (2026-10-02)

Tay co 5 file huong dan cho agent, noi dung trung nhau va **nhieu cho sai**:
`.cursorrules`, `.cursor/rules/tokenvector.mdc`, `CODEX.md`, `ANTIGRAVITY.md`,
`CLAUDE.md`. Vi du sai da chung minh: noi "entry point la `def run() -> "str"`"
(trong khi cua Testkit la `-> "i32"`), va khong file nao nhac `list[int]` vs
`list[i32]` - thu sai do da lam mot loi `InvalidProgramException` **luc chay**
trong chinh phien nay.

Bai nay gom phan "nhac" vao MOT noi va lam no **TRA DUOC DUNG**, khong phai de
doc:

    python 3.code\\tools\\tkv_guide.py rules            # the phai nho (ngan)
    python 3.code\\tools\\tkv_guide.py find sorted       # cu phap + tinh nang that
    python 3.code\\tools\\tkv_guide.py find "doc bang khoa"
    python 3.code\\tools\\tkv_guide.py names sorted      # ten da dang ky
    python 3.code\\tools\\tkv_guide.py lint a.tkv         # bat loi BIEN DICH BO QUA
    python 3.code\\tools\\tkv_guide.py check a.tkv        # bien dich, loi gon
    python 3.code\\tools\\tkv_guide.py verify a.tkv       # lint + build + chay

`rules` dung chung cho moi harness nen 5 file huong dan kiem duoc rut gon con
mot dong tro toi day.
"""
import argparse
import ast
import io
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = os.path.join(ROOT, 'docs', 'REFERENCE.md')
FEAT = os.path.join(ROOT, 'compiler', 'il_features')
COMPILER = os.path.join(ROOT, 'dist', 'tkvc.exe')

# --------------------------------------------------------------------------
# 1. THE PHAI NHO
# --------------------------------------------------------------------------
# Moi dong: [bat buoc]/doc + ly do. Tinh huong do **do** trong repo, khong doan.
RULES = [
    ('BUILD XANH KHONG co nghia la DUNG - luon `verify` truoc khi noi "xong"',
     'Ca 3 bug ghi trong REPOSITORY-NOTES deu bien dich thanh cong roi HONG LUC CHAY '
     'va 2 cai tra ve KET QUA SAI ma khong loi gi. Compiler chi chan cai no BIET.'),
    ('LOCAL trong ham KHONG duoc annotate kieu',
     '`x: "i32" = 1` -> loi bien dich. Chi `g: "func(...)->..." = ...`, '
     '`defaultdict[K,V]`, `Counter[K]`, `list[(K,V)]` duoc khai tuong minh. '
     'Local thuong: `x = 1`.'),
    ('CAP MODULE KHONG CO BIEN nao',
     'Chi nham ham, class, hang so va bien `global` co kieu vo huong '
     '(`counter: "i32" = 0`). `xs = [1,2,3]` o cap module bi tu choi '
     '("gap Assign") -> moi thu phai nam trong ham.'),
    ('`str(x)` va `fmt_float(x, n)` chi nhan BIEN',
     '`ToString()` la instance method tren value type nen CIL can DIA CHI, khong lay '
     'duoc dia chi cua gia tri tam. Gán ra bien truoc: `t = a + b; str(t)`.'),
    ('Method chi goi duoc tren BIEN',
     '`",".join(xs)` -> loi. `t = ","; t.join(xs)`.'),
    ('Method container la LENH DOC LAP',
     '`xs.append(v)` mot dong; `y = xs.pop()` -> loi (pop khong phai bieu thuc). '
     'Thay bang `y = xs[len(xs) - 1]`.'),
    ('Chuoi: nhay kep don HOAC 3 nhay kep deu duoc',
     'Ca `"""x"""` nhieu dong cung chay (da probe). Noi bang `+ str(v)`.'),
    ('f-string VA `.format()` cung DUOC ho tro',
     '`f"{n}"`, `f"{n:05d}"`, `f"{v:.2f}"`, `"{}".format(x)`, `"{0}+{1}".format(a,b)` '
     ' deu chay (co test trong Testkit). Dung chung khi tien. Chi `format(v, spec)` '
     'la HAM co rang buoc: spec phai literal, value phai bien/sao literal.'),
    ('`next(it, default)`: default phai CUNG dtype phan tu',
     'Khong tu nang rong kieu nhu Python. `next(list[i32], "")` -> loi bien dich.'),
    ('`StopIteration` va `RuntimeError` LA MOT CLR TYPE',
     'Ca hai la `System.InvalidOperationException`, nen `except RuntimeError:` se BAT '
     'ca `StopIteration`. Muon phan biet het du lieu, dung `next(it, default)`.'),
    ('`sort(key=)` / `sorted(key=)` KHONG on dinh khi trung khoa',
     'Khac Python (stable sort). Neu thu tu phai on dinh, them tieu chi so phu.'),
    ('FIELD CONTAINER cua record: uu tien `list[int]`',
     '`.ctor` bo qua field container nen phai gan ben ngoai (`it = It(0)` roi '
     '`it.src = xs`). Neu khai field `list[i32]` roi gan vao mot list co dtype '
     '`int` (list literal), doc ra co the ra GIA TRI SAI ma build van xanh '
     '(da probe: `a.xs[1]` = 0). Day KHONG phai loi gi can bat duoc hoc - hay '
     'chon `list[int]` cho field do nguon la list literal.'),
    ('`int()` tran o tren int32',
     'Chuoi > 2147483647 nem `OverflowException`. Dung `int64(x)`.'),
    ('`hash()` KHAC Python',
     'FNV-1a tren UTF-8, o dinh giua cac lan chay. Dung duoc lam khoa/kiem tra, '
     'KHONG dung de khop so voi Python (Python dung SipHash co khoa muoi).'),
    ('`iter()` chi o VI TRI GAN',
     '`it = iter(xs)`; `next(iter(xs))` -> loi bien dich. Mac dinh cua `next` phai '
     'cung dtype phan tu. Nguon: list/set/frozenset/dict(khoa)/str(chuoi 1 ky tu).'),
    ('Mo file bang `open(p, mode)` thi PHAI `close()`',
     'Da sua loi khoa file 2026-10-02, nhung handle `open()` tra ve khong tu dong '
     'Dong - `with open(...)` thi tu Dispose.'),
]


def rules():
    print('# TokenVector - the phai nho\n')
    for i, (what, why) in enumerate(RULES, 1):
        print('%2d. %s' % (i, what))
        print('    %s\n' % why)
    print('Cu phap/tinh nang CHI DAT cua tung ham: '
          '`python tools\\tkv_guide.py find <ten>`')
    print('Kiem tra file viet xong: '
          '`python tools\\tkv_guide.py verify <file.tkv>`')


# --------------------------------------------------------------------------
# 2. TRA CUU TAI LIEU
# --------------------------------------------------------------------------
def _read_ref():
    if not os.path.exists(REF):
        sys.stderr.write('THIEU %s\n' % REF)
        return None
    return io.open(REF, encoding='utf-8').read()


def _keywords(q):
    """'doc bang khoa' -> ['doc','bang','khoa']; bo dau cham, giu dau gach."""
    return [w for w in re.split(r'[^0-9A-Za-z_]+', q.lower()) if len(w) > 1]


def find(q, limit=40):
    text = _read_ref()
    if text is None:
        return 2
    words = _keywords(q)
    rows, prose, cur_head, in_table = [], [], '', False
    for line in text.split('\n'):
        if line.startswith('#'):
            cur_head = line.strip('# ').strip()
            in_table = False
            continue
        low = line.lower()
        hit = sum(1 for w in words if w in low)
        if line.startswith('|'):
            cells = [c.strip() for c in line.strip().strip('|').split('|')]
            if len(cells) >= 2 and set(cells[0]) <= set('-: '):
                in_table = True
                continue
            if not in_table:
                continue
            hay = ' '.join(cells).lower()
            score = sum(3 if w == cells[0].strip('`').lower() else (1 if w in hay else 0)
                        for w in words)
            if score:
                rows.append((score, cur_head, cells))
            continue
        if line.strip():
            in_table = False
        # VAN BAN (khong phai dong bang): dung de hoi theo CHU DE,
        # vi bang chi chua ten ham. Cham 1 dong khi no chua HET cac tu khoa.
        if hit == len(words) and hit > 0 and len(line.strip()) > 12:
            prose.append((cur_head, line.strip()))
    rows.sort(key=lambda r: (-r[0], r[1]))
    if not rows and not prose:
        print('KHONG tim thay "%s". Thu `names <tu khoa>` de xem ten da '
              'dang ky co.' % q)
        return 1
    print('# Tim trong REFERENCE.md: %s  (%d dong bang, %d doan van ban)\n'
          % (q, min(len(rows), limit), min(len(prose), limit)))
    for _score, head, cells in rows[:limit]:
        name = cells[0]
        rest = ' | '.join(cells[1:])
        print('## %s\n   [%s]  %s\n' % (head, name, rest))
    for head, line in prose[:limit]:
        print('## %s (van ban)\n   %s\n' % (head, line))
    return 0


def names(filt=None):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import gen_builtin_ref as g
    b = g.all_registered()
    for key in sorted(b):
        ns = sorted(b[key])
        if filt:
            f = filt.lower()
            ns = [n for n in ns if f in n.lower()]
            if not ns:
                continue
        print('## %s (%d)\n' % (key, len(ns)))
        for i in range(0, len(ns), 8):
            print('`%s` ' % ns[i] + ' '.join('`%s`' % n for n in ns[i + 1:i + 8]))
        print()


# --------------------------------------------------------------------------
# 3. LINT - bat loi ma bien dich BO QUA (build xanh nhung hong luc chay)
# --------------------------------------------------------------------------
LINT_HEADER = ('# -*- coding: utf-8 -*-',)


def lint(path):
    """Tra ve danh sach (dong, muc do, loi).

    **KHONG dung `ast.parse` cua Python.** Ngon ngu co cu phap `a ? b : c` -
    Python parse THAT (va cac thu tu toan tu TokenVector khac) se that bai, roi
    bao loi cho nguoi viet ma **dung** (da gap: 1/117 file Testkit bi bao sai).
    Nen chi dung quy tac TAI DONG THEO DONG.

    **Chi bao loi CHUNG MINH DUOC.** Phai hoi dong: bao loi nao doc vao thi
    dung nghiep? Luon chay `verify` de chan ca phan con lai - ke ca loi luc
    CHAY, cai ma moi lan do moi lo ra."""
    try:
        raw = io.open(path, encoding='utf-8').read()
    except OSError as e:
        return [(0, 'LOI', 'khong doc duoc %s: %s' % (path, e))]
    out = []
    lines = raw.split('\n')
    depth = 0            # 0 = cap module, >0 = trong than ham (theo `def`)
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        indent = len(line) - len(line.lstrip())
        if re.match(r'^def\s+\w+', stripped) or re.match(r'^(async\s+)?def\s+\w+', stripped):
            depth = 1
        # (1) LOCAL co annotate kieu vOHUONG -> compiler bat, thong diep day
        #     dich hon loi cua no.
        if depth and indent >= 4:
            m = re.match(r'^\s*(\w+)\s*:\s*"(i32|i64|i32|i64|f32|f64|str|bool|int)"\s*=', line)
            if m:
                out.append((i, 'LOI',
                            '`%s: "%s" = ...` - LOCAL trong ham khong duoc annotate '
                            'kieu. Viet `%s = ...` (compiler tu suy kieu tu ve phai).'
                            % (m.group(1), m.group(2), m.group(1))))
        # (2) `except RuntimeError` cung bat StopIteration - su that, khong phai loi.
        if re.match(r'^\s*except\s+RuntimeError\b', line):
            out.append((i, 'NGHIEM TRONG',
                        '`except RuntimeError:` cung BAT `StopIteration` (cung mot '
                        'CLR type `InvalidOperationException`). Neu muon kiem tra '
                        'het du lieu, dung `next(it, default)` thay vi bat loi.'))
        # (3) `xs.pop()` gan vao bien -> pop la LENH DOC LAP, khong phai bieu thuc.
        m = re.match(r'^\s*\w+\s*=\s*(\w+)\.pop\(\)\s*$', line)
        if m:
            out.append((i, 'LOI',
                        '`%s = %s.pop()` - `pop()` la LEKH DOC LAP khong phai bieu '
                        'thuc. Thay bang `%s = %s[len(%s) - 1]`.'
                        % (m.group(1), m.group(2), m.group(1), m.group(2),
                           m.group(2))))
        # (4) `a[::-1]` - buoc am CHUA ho tro.
        if re.search(r'\[\s*:\s*-\s*\w*\s*\]', line):
            out.append((i, 'LOI',
                        'buoc slice AM khong ho tro (`a[::-1]`) - chi chap nhan '
                        'buoc DUONG.'))
    return out


# --------------------------------------------------------------------------
# 4. CHECK / VERIFY
# --------------------------------------------------------------------------
_NOISE = re.compile(r'^\s*(CategoryInfo|FullyQualifiedErrorId|\+)\s*:', re.M)


def _compiler():
    if not os.path.exists(COMPILER):
        sys.stderr.write('THIEU compiler: %s\n' % COMPILER)
        sys.stderr.write('Build truoc: powershell -File build_tkvc.ps1\n')
        return None
    return COMPILER


def build(path, entry='run', out=None, run=False):
    comp = _compiler()
    if comp is None:
        return 2
    exe = out or os.path.join(
        os.environ.get('TEMP', '.'),
        'tkvguide_%08x.exe' % (abs(hash(os.path.abspath(path))) % 0x7fffffff))
    if os.path.exists(exe):
        os.remove(exe)
    cmd = [comp, 'build', os.path.abspath(path), '--out', exe, '--entry', entry]
    p = subprocess.run(cmd, capture_output=True, text=True, errors='replace')
    if p.returncode != 0:
        txt = _NOISE.sub('', (p.stdout or '') + (p.stderr or ''))
        lines = [l for l in txt.split('\n') if l.strip()]
        print('BIEN DICH THAT BAI (%s)' % path)
        for l in lines[:6]:
            print('  ' + l.strip())
        return 1
    print('BIEN DICH OK -> %s' % exe)
    if run:
        r = subprocess.run([exe], capture_output=True, text=True, errors='replace')
        out_txt = ((r.stdout or '') + (r.stderr or '')).strip()
        for l in out_txt.split('\n')[:12]:
            print('  ' + l)
        if r.returncode != 0:
            print('CHAY THAT BAI (exit %d)' % r.returncode)
            return 1
        print('CHAY OK')
    return 0


def cmd_check(args):
    rc = build(args.file, args.entry, args.out, run=False)
    return rc


def cmd_verify(args):
    bad = lint(args.file)
    hard = [b for b in bad if b[1] == 'LOI']
    soft = [b for b in bad if b[1] != 'LOI']
    for line, lvl, msg in bad:
        print('%s:%d  [%s] %s' % (args.file, line, lvl, msg))
    if hard:
        print('\n%d loi NGHIEM TRONG - compiler se bao loi, sua truoc.' % len(hard))
        return 1
    if soft:
        print('\n%d canh bao (khong chan duoc chay) - doc truoc khi tin ket qua.\n' % len(soft))
    return build(args.file, args.entry, args.out, run=True)


def main():
    ap = argparse.ArgumentParser(
        prog='tkv_guide',
        description='Huong dan + kiem tra code TokenVector cho harness (agent).')
    sub = ap.add_subparsers(dest='cmd')

    sub.add_parser('rules', help='the phai nho (ngan, doc lai duoc)')

    p_find = sub.add_parser('find', help='tra cuu cu phap/tinh nang trong REFERENCE.md')
    p_find.add_argument('query')

    p_names = sub.add_parser('names', help='liet ke ten da dang ky')
    p_names.add_argument('filter', nargs='?', default=None)

    p_lint = sub.add_parser('lint', help='bat loi ma bien dich BO QUA')
    p_lint.add_argument('file')

    p_check = sub.add_parser('check', help='bien dich 1 file, in loi gon')
    p_check.add_argument('file')
    p_check.add_argument('--entry', default='run')
    p_check.add_argument('--out', default=None)

    p_ver = sub.add_parser('verify', help='lint + bien dich + chay (dung truoc khi noi xong)')
    p_ver.add_argument('file')
    p_ver.add_argument('--entry', default='run')
    p_ver.add_argument('--out', default=None)

    args = ap.parse_args()
    if args.cmd == 'rules':
        return rules() or 0
    if args.cmd == 'find':
        return find(args.query)
    if args.cmd == 'names':
        names(args.filter)
        return 0
    if args.cmd == 'lint':
        bad = lint(args.file)
        if not bad:
            print('KHONG bat duoc loi nao. Nhung boi co the CHAY MOI loi - '
                  'dung `verify` de chan ca do.')
            return 0
        for line, lvl, msg in bad:
            print('%s:%d  [%s] %s' % (args.file, line, lvl, msg))
        print('\n%d canh bao.' % len(bad))
        return 1
    if args.cmd == 'check':
        return cmd_check(args)
    if args.cmd == 'verify':
        return cmd_verify(args)
    ap.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main())
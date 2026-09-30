# -*- coding: utf-8 -*-
import io
import sys


def load(path, allow_trailing_exit):
    """Nap 'nhan = gia tri'. BAO LOI NEU NHAN TRUNG - tru day `d[k] = v`
    ghi de im lang nen 2 phep cung ten chi duoc so lan cuoi, phep truoc bi
    bo qua ma khong ai bao (2026-09-30: nhan 'in' va 'isinstance_like' bi
    trung, 119 dong -> 117 nhan duoc so). Ghi de thi doi chieu khong con
    y nghia: bao loi de bat buoc sua nhan trong nguon probe.

    `allow_trailing_exit`: runtime cu in them gia tri tra ve cua ham entry
    (do - xac minh: exe in ra `7` khi entry `return 7`, va process exit
    code van la 0). Cho phep DUNG MOT dong so nguyen o cuoi file ben tv;
    dong khac khong dang ' = ' thi bao loi - de khong quen loai bo qua
    duoc la gi."""
    d = {}
    order = []
    dups = []
    junk = []
    lines = list(io.open(path, encoding='utf-16'))
    for lineno, line in enumerate(lines, 1):
        line = line.rstrip('\n')
        if ' = ' not in line:
            if line.strip():
                junk.append((lineno, line))
            continue
        k, v = line.split(' = ', 1)
        if k in d:
            dups.append((k, lineno))
        else:
            order.append(k)
        d[k] = v
    exit_note = ''
    if allow_trailing_exit and junk:
        # chi chap nhan khi con DUNG MOT dong, no la dong CUOI, va la so nguyen
        if len(junk) == 1 and junk[0][1].strip().lstrip('-').isdigit() \
                and junk[0][0] == len(lines):
            exit_note = junk[0][1].strip()
            junk = []
    return d, order, dups, junk, exit_note


py, porder, pdu, pjunk, pexit = load(sys.argv[1], False)
tv, torder, tdu, tjunk, texit = load(sys.argv[2], True)
print('py: %d dong, tv: %d dong' % (len(py), len(tv)))
if texit:
    print('entry tra ve: %s (doc o runtime, khong so sanh voi py)' % texit)

# (2026-09-30) Cac loai lech duoc BO QUA im lang truoc day. Bai gio bao loi
# ro - neu khong bao thi ket qua "KHOP: N" dem ca nhung phep chua bao gio
# duoc so, tuc con so dep hon no co.
problems = []
if pdu or tdu:
    problems.append('NHAN TRUNG (bi ghi de, khong phai so het):')
    for k, ln in pdu:
        problems.append('  py  dong %d: %s' % (ln, k))
    for k, ln in tdu:
        problems.append('  tv  dong %d: %s' % (ln, k))
if pjunk or tjunk:
    problems.append('DONG KHONG CO DANG "nhan = gia tri" (bi bo qua):')
    for ln, s in pjunk:
        problems.append('  py  dong %d: %s' % (ln, s))
    for ln, s in tjunk:
        problems.append('  tv  dong %d: %s' % (ln, s))

only_tv = [k for k in torder if k not in py]
only_py = [k for k in porder if k not in tv]
if only_tv:
    problems.append('CHI CO O TV: ' + ', '.join(only_tv))
if only_py:
    problems.append('CHI CO O PY: ' + ', '.join(only_py))

same, diff = 0, []
for k in torder:
    if k in py:
        if py[k] == tv[k]:
            same += 1
        else:
            diff.append((k, py[k], tv[k]))
print('KHOP  : %d' % same)
print('KHAC  : %d' % len(diff))
for k, a, b in diff:
    print('  %-16s py=%-26s tv=%s' % (k, a, b))
for p in problems:
    print('CANH BAO: ' + p if p is problems[0] else '            ' + p)
if problems:
    print('=> PROBE KHONG DANG TIN - sua nhan/nguon truoc khi tin so lieu.')
    sys.exit(1)

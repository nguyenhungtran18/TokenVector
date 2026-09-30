# -*- coding: utf-8 -*-
import io
import sys


def load(path):
    d = {}
    order = []
    for line in io.open(path, encoding='utf-16'):
        line = line.rstrip('\n')
        if ' = ' not in line:
            continue
        k, v = line.split(' = ', 1)
        if k not in d:
            order.append(k)
        d[k] = v
    return d, order


py, porder = load(sys.argv[1])
tv, torder = load(sys.argv[2])
print('py: %d dong, tv: %d dong' % (len(py), len(tv)))
only_tv = [k for k in torder if k not in py]
only_py = [k for k in porder if k not in tv]
if only_tv:
    print('CHI CO O TV :', ', '.join(only_tv))
if only_py:
    print('CHI CO O PY :', ', '.join(only_py))
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

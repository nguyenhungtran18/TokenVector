# -*- coding: utf-8 -*-
# Reference cho ilgpt2_qkv_bwd.tkv (dWq/dWk/dWv, dY1 = dQ Wq^T + dK Wk^T + dV Wv^T).
import re
T, H = 4, 8
y1 = [[1.0 + 0.1 * (t + j) for j in range(H)] for t in range(T)]
dq = [[0.01 * (t + j + 1) for j in range(H)] for t in range(T)]
dk = [[0.02 * (t + j + 1) for j in range(H)] for t in range(T)]
dv = [[0.03 * (t + j + 1) for j in range(H)] for t in range(T)]
Wq = [[0.20 + 0.01 * (i + j) for j in range(H)] for i in range(H)]
Wk = [[0.15 + 0.01 * (i + j) for j in range(H)] for i in range(H)]
Wv = [[0.10 + 0.01 * (i + j) for j in range(H)] for i in range(H)]
dwq = [[sum(y1[t][i] * dq[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dwk = [[sum(y1[t][i] * dk[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dwv = [[sum(y1[t][i] * dv[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dy1 = [[sum(dq[t][j] * Wq[i][j] + dk[t][j] * Wk[i][j] + dv[t][j] * Wv[i][j] for j in range(H)) for i in range(H)] for t in range(T)]
out = ''
try:
    out = r.stdout
except NameError:
    pass
print('STDOUT:', out[-300:])
ok = True
for tag, ref in [('GWQ', dwq), ('GWK', dwk), ('GWV', dwv), ('GY1', dy1)]:
    got = {}
    for i, j, v in re.findall(r'^' + tag + r'\s+(\d+)\s+(\d+)\s+([0-9.eE+-]+)$', out, re.M):
        got[(int(i), int(j))] = float(v)
    if not got:
        print(tag, 'KHONG CO OUTPUT')
        ok = False
        continue
    err = max(abs(v - ref[i][j]) for (i, j), v in got.items())
    print('%-4s n=%3d maxerr=%.4e' % (tag, len(got), err))
    if err > 2e-5:
        ok = False
print('KET LUAN:', 'OK' if ok else 'XEM OUTPUT')

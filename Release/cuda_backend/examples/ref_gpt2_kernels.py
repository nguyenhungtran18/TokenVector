# -*- coding: utf-8 -*-
# Reference double cho 4 kernel device-only cua ilgpt2_kernels.tkv:
# LN forward, LN backward dx, causal softmax forward, softmax backward.
import math, re

T, H = 4, 8
x = [[0.1 + 0.03 * (t + j) for j in range(H)] for t in range(T)]
g = [1.0 + 0.05 * j for j in range(H)]
b = [0.01 * j for j in range(H)]
dy = [[0.02 * (t + 1) + 0.01 * j for j in range(H)] for t in range(T)]
q = [[1.0 + 0.1 * (t + j) for j in range(H)] for t in range(T)]
k = [[0.5 + 0.05 * (t - j) for j in range(H)] for t in range(T)]
dp = [[(t + j + 1) * 0.01 for j in range(T)] for t in range(T)]

# LN forward
xh = [[0.0] * H for _ in range(T)]
y = [[0.0] * H for _ in range(T)]
rst = [0.0] * T
for t in range(T):
    mean = sum(x[t]) / H
    var = sum(v * v for v in x[t]) / H - mean * mean
    rstd = 1.0 / math.sqrt(var + 1e-6)
    rst[t] = rstd
    for j in range(H):
        xh[t][j] = (x[t][j] - mean) * rstd
        y[t][j] = xh[t][j] * g[j] + b[j]

# LN backward dx
dx = [[0.0] * H for _ in range(T)]
for t in range(T):
    s1 = sum(dy[t][j] * g[j] for j in range(H)) / H
    s2 = sum(dy[t][j] * g[j] * xh[t][j] for j in range(H)) / H
    for j in range(H):
        dx[t][j] = (dy[t][j] * g[j] - s1 - xh[t][j] * s2) * rst[t]

# S = Q K^T / sqrt(H)
alpha = 1.0 / math.sqrt(H)
S = [[alpha * sum(q[t][d] * k[j][d] for d in range(H)) for j in range(T)] for t in range(T)]
# causal softmax
P = [[0.0] * T for _ in range(T)]
for t in range(T):
    mx = max(S[t][j] for j in range(t + 1))
    e = [math.exp(S[t][j] - mx) if j <= t else 0.0 for j in range(T)]
    s = sum(e)
    P[t] = [v / s for v in e]
# softmax backward (chua nhan scale)
dS = [[0.0] * T for _ in range(T)]
for t in range(T):
    rs = sum(dp[t][j] * P[t][j] for j in range(T))
    for j in range(T):
        dS[t][j] = P[t][j] * (dp[t][j] - rs) if j <= t else 0.0

out = ''
try:
    out = r.stdout
except NameError:
    pass


def parse(tag):
    d = {}
    for i, j, v in re.findall(r'^' + tag + r'\s+(\d+)\s+(\d+)\s+([0-9.eE+-]+)$', out, re.M):
        d[(int(i), int(j))] = float(v)
    return d


pairs = [('LY', y), ('LDX', dx), ('SP', P), ('DS', dS)]
allok = True
for tag, ref in pairs:
    got = parse(tag)
    if not got:
        print(tag, 'KHONG CO OUTPUT')
        allok = False
        continue
    err = max(abs(v - ref[i][j]) for (i, j), v in got.items())
    print('%-4s n=%3d maxerr=%.4e' % (tag, len(got), err))
    if err > 2e-4:
        allok = False
print('KET LUAN:', 'OK' if allok else 'XEM OUTPUT')

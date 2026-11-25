# -*- coding: utf-8 -*-
# Reference double cho ilgpt2_block_fwd.tkv (mot block transformer, forward).
import math, re

T, H = 4, 8
F = 4 * H
x = [[0.1 + 0.02 * (t + j) for j in range(H)] for t in range(T)]
Wq = [[0.20 + 0.01 * (i + j) for j in range(H)] for i in range(H)]
Wk = [[0.15 + 0.01 * (i + j) for j in range(H)] for i in range(H)]
Wv = [[0.10 + 0.01 * (i + j) for j in range(H)] for i in range(H)]
Wo = [[0.30 + 0.01 * (i + j) for j in range(H)] for i in range(H)]
W1 = [[0.2 + 0.005 * (i + j) for j in range(F)] for i in range(H)]
W2 = [[0.2 + 0.005 * (i + j) for j in range(H)] for i in range(F)]
g1 = [1.0 + 0.05 * j for j in range(H)]
b1 = [0.01 * j for j in range(H)]
g2 = [1.1 + 0.04 * j for j in range(H)]
b2 = [0.02 * j for j in range(H)]


def ln(xs, g, b):
    n = len(xs[0])
    out = [[0.0] * n for _ in range(len(xs))]
    for t, row in enumerate(xs):
        mean = sum(row) / n
        var = sum(v * v for v in row) / n - mean * mean
        rstd = 1.0 / math.sqrt(var + 1e-6)
        for j in range(n):
            out[t][j] = (row[j] - mean) * rstd * g[j] + b[j]
    return out


def gelu(v):
    z = 0.79788456 * (v + 0.044715 * v * v * v)
    return 0.5 * v * (1.0 + math.tanh(z))


Y1 = ln(x, g1, b1)
Q = [[sum(Y1[t][d] * Wq[d][j] for d in range(H)) for j in range(H)] for t in range(T)]
K = [[sum(Y1[t][d] * Wk[d][j] for d in range(H)) for j in range(H)] for t in range(T)]
V = [[sum(Y1[t][d] * Wv[d][j] for d in range(H)) for j in range(H)] for t in range(T)]
alpha = 1.0 / math.sqrt(H)
S = [[alpha * sum(Q[t][d] * K[j][d] for d in range(H)) for j in range(T)] for t in range(T)]
P = [[0.0] * T for _ in range(T)]
for t in range(T):
    mx = max(S[t][j] for j in range(t + 1))
    e = [math.exp(S[t][j] - mx) if j <= t else 0.0 for j in range(T)]
    s = sum(e)
    P[t] = [v / s for v in e]
A = [[sum(P[t][i] * V[i][j] for i in range(T)) for j in range(H)] for t in range(T)]
O = [[sum(A[t][d] * Wo[d][j] for d in range(H)) for j in range(H)] for t in range(T)]
X2 = [[x[t][j] + O[t][j] for j in range(H)] for t in range(T)]
Y2 = ln(X2, g2, b2)
Z = [[sum(Y2[t][d] * W1[d][j] for d in range(H)) for j in range(F)] for t in range(T)]
HH = [[gelu(Z[t][j]) for j in range(F)] for t in range(T)]
O2 = [[sum(HH[t][d] * W2[d][j] for d in range(F)) for j in range(H)] for t in range(T)]
OUT = [[X2[t][j] + O2[t][j] for j in range(H)] for t in range(T)]

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


allok = True
for tag, ref in [('Y1', Y1), ('P', P), ('X2', X2), ('Y2', Y2), ('HH', HH), ('OUT', OUT)]:
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

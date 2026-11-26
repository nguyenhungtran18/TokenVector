# -*- coding: utf-8 -*-
# Reference double cho ilgpt2_block_bwd.tkv (mot block transformer, backward).
import math, re

T, H = 4, 8
F = 4 * H
x = [[0.1 + 0.02 * (t + j) for j in range(H)] for t in range(T)]
dout = [[0.01 * (t + j + 1) for j in range(H)] for t in range(T)]
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


def ln_fwd(xs, g, b):
    n = len(xs[0])
    out = [[0.0] * n for _ in range(len(xs))]
    xh = [[0.0] * n for _ in range(len(xs))]
    st = []
    for t, row in enumerate(xs):
        mean = sum(row) / n
        var = sum(v * v for v in row) / n - mean * mean
        rstd = 1.0 / math.sqrt(var + 1e-6)
        st.append((mean, rstd))
        for j in range(n):
            xh[t][j] = (row[j] - mean) * rstd
            out[t][j] = xh[t][j] * g[j] + b[j]
    return out, xh, st


def dgelu(v):
    z = 0.79788456 * (v + 0.044715 * v * v * v)
    th = math.tanh(z)
    return 0.5 * (1 + th) + 0.5 * v * (1 - th * th) * 0.79788456 * (1 + 0.134145 * v * v)


def ln_bwd(dy, xh, st, g):
    n = len(g)
    dx = [[0.0] * n for _ in range(len(dy))]
    dg = [0.0] * n
    db = [0.0] * n
    for t in range(len(dy)):
        s1 = sum(dy[t][j] * g[j] for j in range(n)) / n
        s2 = sum(dy[t][j] * g[j] * xh[t][j] for j in range(n)) / n
        for j in range(n):
            dx[t][j] = (dy[t][j] * g[j] - s1 - xh[t][j] * s2) * st[t][1]
            dg[j] += dy[t][j] * xh[t][j]
            db[j] += dy[t][j]
    return dx, dg, db


# forward
Y1, xh1, st1 = ln_fwd(x, g1, b1)
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
Y2, xh2, st2 = ln_fwd(X2, g2, b2)
Z = [[sum(Y2[t][d] * W1[d][j] for d in range(H)) for j in range(F)] for t in range(T)]
HH = [[0.5 * Z[t][j] * (1 + math.tanh(0.79788456 * (Z[t][j] + 0.044715 * Z[t][j] ** 3))) for j in range(F)] for t in range(T)]

# backward
dW2 = [[sum(HH[t][i] * dout[t][j] for t in range(T)) for j in range(H)] for i in range(F)]
dHH = [[sum(dout[t][j] * W2[i][j] for j in range(H)) for i in range(F)] for t in range(T)]
dZ = [[dHH[t][i] * dgelu(Z[t][i]) for i in range(F)] for t in range(T)]
dW1 = [[sum(Y2[t][i] * dZ[t][j] for t in range(T)) for j in range(F)] for i in range(H)]
dY2 = [[sum(dZ[t][j] * W1[i][j] for j in range(F)) for i in range(H)] for t in range(T)]
dx2ln, dg2, db2 = ln_bwd(dY2, xh2, st2, g2)
dX2 = [[dout[t][j] + dx2ln[t][j] for j in range(H)] for t in range(T)]
dA = [[sum(dX2[t][k] * Wo[k][j] for k in range(H)) for j in range(H)] for t in range(T)]
dWo = [[sum(A[t][k] * dX2[t][j] for t in range(T)) for j in range(H)] for k in range(H)]
dP = [[sum(dA[t][j] * V[u][j] for j in range(H)) for u in range(T)] for t in range(T)]
dV = [[sum(P[t][u] * dA[t][j] for t in range(T)) for j in range(H)] for u in range(T)]
dS = [[P[t][u] * (dP[t][u] - sum(P[t][v] * dP[t][v] for v in range(T))) for u in range(T)] for t in range(T)]
dQ = [[alpha * sum(dS[t][u] * K[u][j] for u in range(T)) for j in range(H)] for t in range(T)]
dK = [[alpha * sum(dS[t][u] * Q[t][j] for t in range(T)) for j in range(H)] for u in range(T)]
dWq = [[sum(Y1[t][i] * dQ[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dWk = [[sum(Y1[t][i] * dK[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dWv = [[sum(Y1[t][i] * dV[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dY1 = [[sum(dQ[t][j] * Wq[i][j] + dK[t][j] * Wk[i][j] + dV[t][j] * Wv[i][j] for j in range(H)) for i in range(H)] for t in range(T)]
dX, dg1, db1 = ln_bwd(dY1, xh1, st1, g1)

out = ''
try:
    out = r.stdout
except NameError:
    pass

print('STDOUT TAIL (last 400):')
print(out[-400:])


def parse2(tag):
    d = {}
    for i, j, v in re.findall(r'^' + tag + r'\s+(\d+)\s+(\d+)\s+([0-9.eE+-]+)$', out, re.M):
        d[(int(i), int(j))] = float(v)
    return d


def parse1(tag):
    d = {}
    for i, v in re.findall(r'^' + tag + r'\s+(\d+)\s+([0-9.eE+-]+)$', out, re.M):
        d[int(i)] = float(v)
    return d


mats = [('GW2', dW2), ('GW1', dW1), ('GY2', dY2), ('GX2', dX2), ('GA', dA),
        ('GWO', dWo), ('GP', dP), ('GV', dV), ('GS', dS), ('GQ', dQ), ('GK', dK),
        ('GWQ', dWq), ('GWK', dWk), ('GWV', dWv), ('GY1', dY1), ('GDX', dX)]
vecs = [('GG1', dg1), ('GB1', db1), ('GG2', dg2), ('GB2', db2)]
allok = True
for tag, ref in mats:
    got = parse2(tag)
    if not got:
        print(tag, 'KHONG CO OUTPUT')
        allok = False
        continue
    err = max(abs(v - ref[i][j]) for (i, j), v in got.items())
    print('%-4s n=%3d maxerr=%.4e' % (tag, len(got), err))
    if err > 3e-4:
        allok = False
for tag, ref in vecs:
    got = parse1(tag)
    if not got:
        print(tag, 'KHONG CO OUTPUT')
        allok = False
        continue
    err = max(abs(v - ref[i]) for i, v in got.items())
    print('%-4s n=%3d maxerr=%.4e' % (tag, len(got), err))
    if err > 3e-4:
        allok = False
print('KET LUAN:', 'OK' if allok else 'XEM OUTPUT')

# -*- coding: utf-8 -*-
# Reference Python (chuan double) cho 5 buoc train cua ilgpu_step_full_gpu.
# Doc stdout cua exe tu bien 'r' trong notebook.
import math, re

T, D, V = 4, 8, 8
W1 = [[0.2 + 0.01 * (i + j) for j in range(D)] for i in range(D)]
W2 = [[0.3 + 0.01 * (i + j) for j in range(V)] for i in range(D)]
b1 = [0.1] * D
b2 = [0.05] * V
X = [[0.1 + 0.02 * (t + j) for j in range(D)] for t in range(T)]
ids = [(t + 1) % V for t in range(T)]


def gelu(x):
    z = 0.79788456 * (x + 0.044715 * x * x * x)
    th = math.tanh(z)
    return 0.5 * x * (1 + th)


def dgelu(x):
    z = 0.79788456 * (x + 0.044715 * x * x * x)
    th = math.tanh(z)
    return 0.5 * (1 + th) + 0.5 * x * (1 - th * th) * 0.79788456 * (1 + 0.134145 * x * x)


lr, bt1, bt2, eps, wd = 0.01, 0.9, 0.999, 1e-8, 0.01
mW1 = [[0.0] * D for _ in range(D)]
vW1 = [[0.0] * D for _ in range(D)]
mW2 = [[0.0] * V for _ in range(D)]
vW2 = [[0.0] * V for _ in range(D)]
mb1 = [0.0] * D
vb1 = [0.0] * D
mb2 = [0.0] * V
vb2 = [0.0] * V
p1, p2 = 0.9, 0.999
losses = []
W1ref = None
W2ref = None


def upd2(W, g, m, v):
    for i in range(len(W)):
        for j in range(len(W[0])):
            gg = g[i][j]
            m[i][j] = bt1 * m[i][j] + (1 - bt1) * gg
            v[i][j] = bt2 * v[i][j] + (1 - bt2) * gg * gg
            W[i][j] = W[i][j] - lr * (m[i][j] / bc1) / (math.sqrt(v[i][j] / bc2) + eps) - lr * wd * W[i][j]


def upd1(W, g, m, v):
    for i in range(len(W)):
        gg = g[i]
        m[i] = bt1 * m[i] + (1 - bt1) * gg
        v[i] = bt2 * v[i] + (1 - bt2) * gg * gg
        W[i] = W[i] - lr * (m[i] / bc1) / (math.sqrt(v[i] / bc2) + eps) - lr * wd * W[i]


for step in range(1, 6):
    Z = [[sum(X[t][k] * W1[k][j] for k in range(D)) + b1[j] for j in range(D)] for t in range(T)]
    H = [[gelu(Z[t][j]) for j in range(D)] for t in range(T)]
    LG = [[sum(H[t][j] * W2[j][v] for j in range(D)) + b2[v] for v in range(V)] for t in range(T)]
    P = []
    for t in range(T):
        mx = max(LG[t])
        e = [math.exp(v - mx) for v in LG[t]]
        s = sum(e)
        P.append([v / s for v in e])
    losses.append(-sum(math.log(P[t][ids[t]]) for t in range(T)) / T)
    dL = [[(P[t][v] - (1.0 if v == ids[t] else 0.0)) / T for v in range(V)] for t in range(T)]
    dW2 = [[sum(H[t][i] * dL[t][j] for t in range(T)) for j in range(V)] for i in range(D)]
    db2 = [sum(dL[t][v] for t in range(T)) for v in range(V)]
    dH = [[sum(dL[t][v] * W2[j][v] for v in range(V)) for j in range(D)] for t in range(T)]
    dZ = [[dH[t][j] * dgelu(Z[t][j]) for j in range(D)] for t in range(T)]
    dW1 = [[sum(X[t][i] * dZ[t][j] for t in range(T)) for j in range(D)] for i in range(D)]
    db1 = [sum(dZ[t][j] for t in range(T)) for j in range(D)]
    bc1 = 1.0 - p1
    bc2 = 1.0 - p2
    upd2(W1, dW1, mW1, vW1)
    upd2(W2, dW2, mW2, vW2)
    upd1(b1, db1, mb1, vb1)
    upd1(b2, db2, mb2, vb2)
    if step == 1:
        W1ref = [W1[i][0] for i in range(D)]
        W2ref = [W2[i][0] for i in range(V)]
    p1 *= 0.9
    p2 *= 0.999

out = ''
try:
    out = r.stdout
except NameError:
    pass
il_loss = [float(v) for v in re.findall(r'^LOSS\s+([0-9.eE+-]+)$', out, re.M)]
g1 = [float(v) for v in re.findall(r'^W1NEW\s+\d+\s+([0-9.eE+-]+)$', out, re.M)]
g2 = [float(v) for v in re.findall(r'^W2NEW\s+\d+\s+([0-9.eE+-]+)$', out, re.M)]
errs = [abs(a - b) for a, b in zip(il_loss, losses)]
print('ref losses =', [round(x, 8) for x in losses])
print('IL  losses =', il_loss)
print('loss maxerr =', max(errs) if errs else None)
e1 = max(abs(a - b) for a, b in zip(g1, W1ref)) if len(g1) == D else None
e2 = max(abs(a - b) for a, b in zip(g2, W2ref)) if len(g2) == V else None
print('W1/W2 step1 maxerr =', e1, e2)
ok = len(il_loss) == 5 and e1 is not None and e2 is not None and max(errs) < 2e-4 and e1 < 2e-4 and e2 < 2e-4
print('KET LUAN:', 'OK' if ok else 'XEM OUTPUT')

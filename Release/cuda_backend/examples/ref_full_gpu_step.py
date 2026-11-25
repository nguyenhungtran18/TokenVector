# -*- coding: utf-8 -*-
# Reference Python (chuan double) cho 5 buoc train cua ilgpu_step_full_gpu.
# Doc stdout cua exe tu bien 'r' trong notebook.
#
# Ngoai viec so sanh loss, script con:
#   - so sanh tham so (W1, W2, b1, b2) theo TUNG step  -> biet sai so tich luy o dau
#   - tinh lai forward bang double TU CHINH tham so IL in ra -> tach loi forward
#     (tanh.approx cua GPU) khoi loi duong cap nhat (backward + AdamW)
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


def forward(W1f, W2f, b1f, b2f):
    Z = [[sum(X[t][k] * W1f[k][j] for k in range(D)) + b1f[j] for j in range(D)] for t in range(T)]
    H = [[gelu(Z[t][j]) for j in range(D)] for t in range(T)]
    LG = [[sum(H[t][j] * W2f[j][v] for j in range(D)) + b2f[v] for v in range(V)] for t in range(T)]
    return Z, H, LG


def loss_of(LG):
    tot = 0.0
    for t in range(T):
        mx = max(LG[t])
        e = [math.exp(v - mx) for v in LG[t]]
        s = sum(e)
        tot += -math.log(e[ids[t]] / s)
    return tot / T


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
W1h, W2h, b1h, b2h = [], [], [], []
# tham so khoi tao (giong het IL ghi vao device)
W1_0 = [row[:] for row in W1]
W2_0 = [row[:] for row in W2]
b1_0 = b1[:]
b2_0 = b2[:]


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
    Z, H, LG = forward(W1, W2, b1, b2)
    losses.append(loss_of(LG))
    P = []
    for t in range(T):
        mx = max(LG[t])
        e = [math.exp(v - mx) for v in LG[t]]
        s = sum(e)
        P.append([v / s for v in e])
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
    W1h.append([row[:] for row in W1])
    W2h.append([row[:] for row in W2])
    b1h.append(b1[:])
    b2h.append(b2[:])
    p1 *= 0.9
    p2 *= 0.999

out = ''
try:
    out = r.stdout
except NameError:
    pass


def parse(tag):
    d = {}
    for st, ix, v in re.findall(r'^' + tag + r'\s+(\d+)\s+(\d+)\s+([0-9.eE+-]+)$', out, re.M):
        d.setdefault(int(st), {})[int(ix)] = float(v)
    return d


def parse1(tag):
    d = {}
    for st, a, b, c in re.findall(r'^' + tag + r'\s+(\d+)\s+([0-9.eE+-]+)\s+([0-9.eE+-]+)\s+([0-9.eE+-]+)$', out, re.M):
        d[int(st)] = (float(a), float(b), float(c))
    return d


il_loss = [float(v) for v in re.findall(r'^LOSS\s+([0-9.eE+-]+)$', out, re.M)]
w1p, w2p, b1p, b2p = parse('W1NEW'), parse('W2NEW'), parse('B1NEW'), parse('B2NEW')
g1p, g2p = parse1('G1'), parse1('G2')

print('ref losses =', [round(x, 8) for x in losses])
print('IL  losses =', il_loss)
errs = [abs(a - b) for a, b in zip(il_loss, losses)]
print('loss maxerr =', max(errs) if errs else None)

if not w1p:
    print('KHONG PARSE DUOC W1NEW (notebook cu?)')
else:
    print('step | dW1max     dW2max     db1max     db2max  | lossIL     lossDouble(W_pre)  | g1(min,max,tiny)   g2(min,max,tiny)')
    for st in sorted(w1p):
        e1 = max(abs(v - W1h[st - 1][p % D][p // D]) for p, v in w1p[st].items()) if st <= len(W1h) else float('nan')
        e2 = max(abs(v - W2h[st - 1][p % D][p // D]) for p, v in w2p[st].items()) if st <= len(W2h) else float('nan')
        eb1 = max(abs(v - b1h[st - 1][p]) for p, v in b1p[st].items()) if st <= len(b1h) else float('nan')
        eb2 = max(abs(v - b2h[st - 1][p]) for p, v in b2p[st].items()) if st <= len(b2h) else float('nan')
        # loss in ra o step st duoc tinh tu tham so TRUOC khi update step st
        # => dung tham so IL in ra o step st-1 (step 1 thi dung tham so khoi tao)
        if st == 1:
            W1f, W2f, b1f, b2f = W1_0, W2_0, b1_0, b2_0
        else:
            W1f = [[0.0] * D for _ in range(D)]
            W2f = [[0.0] * V for _ in range(D)]
            for p, v in w1p[st - 1].items():
                W1f[p % D][p // D] = v
            for p, v in w2p[st - 1].items():
                W2f[p % D][p // D] = v
            b1f = [b1p[st - 1].get(i, float('nan')) for i in range(D)]
            b2f = [b2p[st - 1].get(i, float('nan')) for i in range(V)]
        lrec = loss_of(forward(W1f, W2f, b1f, b2f)[2])
        lil = il_loss[st - 1] if len(il_loss) >= st else float('nan')
        print('%4d | %.3e %.3e %.3e %.3e | %.8f %.8f (d=%.2e) | %s %s' % (
            st, e1, e2, eb1, eb2, lil, lrec, abs(lil - lrec),
            ('%.2e/%.2e/%d' % g1p[st]) if st in g1p else '-',
            ('%.2e/%.2e/%d' % g2p[st]) if st in g2p else '-'))

    emax = max(abs(v - W1h[st - 1][p % D][p // D]) for st in w1p for p, v in w1p[st].items())
    ok = len(il_loss) == 5 and emax < 2e-4 and max(errs) < 2e-4
    print('W1 maxerr toan bo 5 step =', emax)
    print('KET LUAN:', 'OK' if ok else 'XEM OUTPUT')

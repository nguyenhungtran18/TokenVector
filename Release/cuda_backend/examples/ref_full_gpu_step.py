# -*- coding: utf-8 -*-
# Reference Python (double) cho 5 buoc train cua ilgpu_step_full_gpu.
# Doc stdout cua exe tu bien 'r' trong notebook.
#
# Script tra loi 3 cau hoi tach biet:
#   (A) forward + softmax/loss co dung khong?
#       -> tinh lai loss bang double TU CHINH tham so IL in ra, so voi LOSS in ra.
#   (B) gradient (backward) co dung khong?
#       -> so dW1/dW2/db1/db2 IL in ra voi gradient cua reference.
#   (C) sai so quy dao tham so co phai do Adam khuech dai sai so f32 khong?
#       -> ap dung dung cong thuc AdamW cua reference len gradient IL va len gradient ref,
#          chenh lech du doan duoc so voi chenh lech tham so quan sat duoc.
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
G1h, G2h, Gb1h, Gb2h = [], [], [], []
W1_0 = [row[:] for row in W1]
W2_0 = [row[:] for row in W2]
b1_0 = b1[:]
b2_0 = b2[:]


def adam_upd(p, m, v, g, bc1, bc2):
    mm = bt1 * m + (1 - bt1) * g
    vv = bt2 * v + (1 - bt2) * g * g
    return p - lr * (mm / bc1) / (math.sqrt(vv / bc2) + eps) - lr * wd * p


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
    G1h.append([row[:] for row in dW1])
    G2h.append([row[:] for row in dW2])
    Gb1h.append(db1[:])
    Gb2h.append(db2[:])
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
dw1p, dw2p, db1p, db2p = parse('DW1'), parse('DW2'), parse('DB1'), parse('DB2')

print('ref losses =', [round(x, 8) for x in losses])
print('IL  losses =', il_loss)
errs = [abs(a - b) for a, b in zip(il_loss, losses)]
print('loss maxerr =', max(errs) if errs else None)

if not w1p:
    print('KHONG PARSE DUOC W1NEW (notebook cu?)')
else:
    print('')
    print('(A) forward: loss tinh lai bang double tu tham so IL, so voi LOSS in ra')
    print('(B) backward: gradient IL vs gradient reference')
    print('(C) quy dao: |W_IL - W_ref| va chenh lech DO ADAM DU DOAN tu chinh (B)')
    print('')
    print('step | dG1max     dG2max     dGb1max    dGb2max  | predW1     obsW1      predB1     obsB1    | dLossFwd')
    fwd_errs = []
    explained = True
    for st in sorted(w1p):
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
        d_fwd = abs((il_loss[st - 1] if len(il_loss) >= st else float('nan'))
                    - loss_of(forward(W1f, W2f, b1f, b2f)[2]))
        fwd_errs.append(d_fwd)
        # (B) gradient
        e1 = e2 = eb1 = eb2 = float('nan')
        pred_w1 = pred_b1 = 0.0
        if st in dw1p:
            e1 = max(abs(v - G1h[st - 1][p % D][p // D]) for p, v in dw1p[st].items())
            e2 = max(abs(v - G2h[st - 1][p % D][p // D]) for p, v in dw2p[st].items()) if st in dw2p else float('nan')
            eb1 = max(abs(v - Gb1h[st - 1][p]) for p, v in db1p[st].items()) if st in db1p else float('nan')
            eb2 = max(abs(v - Gb2h[st - 1][p]) for p, v in db2p[st].items()) if st in db2p else float('nan')
            # (C) do Adam khuech dai sai so gradient bao nhieu (dung m,v,W cua reference)
            for p, g_il in dw1p[st].items():
                i, j = p % D, p // D
                a = adam_upd(W1h[st - 1][i][j], mW1[i][j], vW1[i][j], G1h[st - 1][i][j], 1.0 - 0.9 ** st, 1.0 - 0.999 ** st)
                b = adam_upd(W1h[st - 1][i][j], mW1[i][j], vW1[i][j], g_il, 1.0 - 0.9 ** st, 1.0 - 0.999 ** st)
                pred_w1 = max(pred_w1, abs(a - b))
            for p, g_il in (db1p[st].items() if st in db1p else []):
                a = adam_upd(b1h[st - 1][p], mb1[p], vb1[p], Gb1h[st - 1][p], 1.0 - 0.9 ** st, 1.0 - 0.999 ** st)
                b = adam_upd(b1h[st - 1][p], mb1[p], vb1[p], g_il, 1.0 - 0.9 ** st, 1.0 - 0.999 ** st)
                pred_b1 = max(pred_b1, abs(a - b))
        obs_w1 = max(abs(v - W1h[st - 1][p % D][p // D]) for p, v in w1p[st].items())
        obs_b1 = max(abs(v - b1h[st - 1][p]) for p, v in b1p[st].items()) if st in b1p else float('nan')
        if st == 2:
            # o step 2, m/v cua IL va reference gan nhu trung nhau (gradient step 1 khop ~1e-9)
            # nen day la phep so sanh sach nhat: Adam co giai thich duoc drift khong?
            explained = (obs_w1 <= 4.0 * pred_w1 + 1e-6)
            ratio = obs_w1 / pred_w1 if pred_w1 > 0 else float('inf')
            print('  -> step2: obsW1/predW1 = %.2f (Adam khuech dai sai so gradient f32)' % ratio)
        print('%4d | %.3e %.3e %.3e %.3e | %.3e %.3e %.3e %.3e | %.2e' % (
            st, e1, e2, eb1, eb2, pred_w1, obs_w1, pred_b1, obs_b1, d_fwd))

    print('')
    print('max dLossFwd (forward+loss, phai ~1e-7) =', max(fwd_errs))
    st1 = 1
    p1e = max(abs(v - W1h[0][p % D][p // D]) for p, v in w1p[st1].items())
    p2e = max(abs(v - W2h[0][p % D][p // D]) for p, v in w2p[st1].items())
    print('step1 param maxerr (phai ~1e-8)      =', p1e, p2e)
    print('quy dao duoc Adam giai thich?         =', explained)
    ok = (len(il_loss) == 5 and max(fwd_errs) < 1e-6 and p1e < 1e-6 and p2e < 1e-6 and explained)
    print('KET LUAN:', 'OK' if ok else 'XEM OUTPUT')

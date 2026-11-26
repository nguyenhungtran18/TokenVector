# -*- coding: utf-8 -*-
# Reference cho ilgpt2_bwd_clean.tkv (block backward, moi input sinh tren host).
import math, re
T, H = 4, 8
F = 4 * H
y1 = [[1.0 + 0.1*(t+j) for j in range(H)] for t in range(T)]
xh1 = [[0.8 + 0.05*(t+j) for j in range(H)] for t in range(T)]
st1 = [(0.3 + 0.01*t, 1.0 + 0.02*t) for t in range(T)]
y2 = [[1.2 + 0.08*(t+j) for j in range(H)] for t in range(T)]
xh2 = [[0.9 + 0.06*(t+j) for j in range(H)] for t in range(T)]
st2 = [(0.4 + 0.01*t, 1.1 + 0.02*t) for t in range(T)]
Z = [[0.5 + 0.02*(t+j) for j in range(F)] for t in range(T)]
HH = [[0.3 + 0.01*(t+j) for j in range(F)] for t in range(T)]
P = [[(1.0/(t+1) if j <= t else 0.0) for j in range(T)] for t in range(T)]
A = [[0.7 + 0.04*(t+j) for j in range(H)] for t in range(T)]
V = [[0.2 + 0.03*(t+j) for j in range(H)] for t in range(T)]
Q = [[1.0 + 0.1*(t+j) for j in range(H)] for t in range(T)]
K = [[0.5 + 0.05*(t-j) for j in range(H)] for t in range(T)]
dout = [[0.01*(t+j+1) for j in range(H)] for t in range(T)]
g1 = [1.0 + 0.05*j for j in range(H)]
g2 = [1.1 + 0.04*j for j in range(H)]
Wq = [[0.20 + 0.01*(i+j) for j in range(H)] for i in range(H)]
Wk = [[0.15 + 0.01*(i+j) for j in range(H)] for i in range(H)]
Wv = [[0.10 + 0.01*(i+j) for j in range(H)] for i in range(H)]
Wo = [[0.30 + 0.01*(i+j) for j in range(H)] for i in range(H)]
W1 = [[0.2 + 0.005*(i+j) for j in range(F)] for i in range(H)]
W2 = [[0.2 + 0.005*(i+j) for j in range(H)] for i in range(F)]
alpha = 1.0/math.sqrt(H)

def dgelu(v):
    z = 0.79788456*(v + 0.044715*v*v*v)
    th = math.tanh(z)
    return 0.5*(1+th) + 0.5*v*(1-th*th)*0.79788456*(1+0.134145*v*v)

def lnbwd(dy, xh, st, g):
    dx = [[0.0]*H for _ in range(T)]
    for t in range(T):
        s1 = sum(dy[t][j]*g[j] for j in range(H))/H
        s2 = sum(dy[t][j]*g[j]*xh[t][j] for j in range(H))/H
        for j in range(H):
            dx[t][j] = (dy[t][j]*g[j] - s1 - xh[t][j]*s2)*st[t][1]
    return dx

dW2 = [[sum(HH[t][i]*dout[t][j] for t in range(T)) for j in range(H)] for i in range(F)]
dHH = [[sum(dout[t][j]*W2[i][j] for j in range(H)) for i in range(F)] for t in range(T)]
dZ = [[dHH[t][i]*dgelu(Z[t][i]) for i in range(F)] for t in range(T)]
dW1 = [[sum(y2[t][i]*dZ[t][j] for t in range(T)) for j in range(F)] for i in range(H)]
dY2 = [[sum(dZ[t][j]*W1[i][j] for j in range(F)) for i in range(H)] for t in range(T)]
dx2ln = lnbwd(dY2, xh2, st2, g2)
dX2 = [[dout[t][j] + dx2ln[t][j] for j in range(H)] for t in range(T)]
dA = [[sum(dX2[t][k]*Wo[k][j] for k in range(H)) for j in range(H)] for t in range(T)]
dWo = [[sum(A[t][k]*dX2[t][j] for t in range(T)) for j in range(H)] for k in range(H)]
dP = [[sum(dA[t][j]*V[u][j] for j in range(H)) for u in range(T)] for t in range(T)]
dV = [[sum(P[t][u]*dA[t][j] for t in range(T)) for j in range(H)] for u in range(T)]
dS = [[P[t][u]*(dP[t][u]-sum(P[t][v]*dP[t][v] for v in range(T))) for u in range(T)] for t in range(T)]
dQ = [[alpha*sum(dS[t][u]*K[u][j] for u in range(T)) for j in range(H)] for t in range(T)]
dK = [[alpha*sum(dS[t][u]*Q[t][j] for t in range(T)) for j in range(H)] for u in range(T)]
dWq = [[sum(y1[t][i]*dQ[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dWk = [[sum(y1[t][i]*dK[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dWv = [[sum(y1[t][i]*dV[t][j] for t in range(T)) for j in range(H)] for i in range(H)]
dY1 = [[sum(dQ[t][j]*Wq[i][j] + dK[t][j]*Wk[i][j] + dV[t][j]*Wv[i][j] for j in range(H)) for i in range(H)] for t in range(T)]
dX = lnbwd(dY1, xh1, st1, g1)

out = ''
try:
    out = r.stdout
except NameError:
    pass
print('STDOUT TAIL:', out[-300:])
ok = True
mats = [('GW2',dW2),('GW1',dW1),('GY2',dY2),('GX2',dX2),('GA',dA),('GWO',dWo),('GP',dP),
        ('GV',dV),('GS',dS),('GQ',dQ),('GK',dK),('GWQ',dWq),('GWK',dWk),('GWV',dWv),('GY1',dY1),('GDX',dX)]
for tag, ref in mats:
    got={}
    for i,j,v in re.findall(r'^'+tag+r'\s+(\d+)\s+(\d+)\s+([0-9.eE+-]+)$', out, re.M):
        got[(int(i),int(j))]=float(v)
    if not got:
        print(tag,'KHONG CO OUTPUT'); ok=False; continue
    err=max(abs(v-ref[i][j]) for (i,j),v in got.items())
    print('%-4s n=%3d maxerr=%.4e' % (tag,len(got),err))
    if err > 3e-4: ok=False
print('KET LUAN:', 'OK' if ok else 'XEM OUTPUT')

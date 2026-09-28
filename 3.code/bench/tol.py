import numpy as np
from fractions import Fraction as F

# 1) Data hien tai cua benchmark matmul32 co bi lam tron khong?
n=32
a=[float((i%7)-3) for i in range(n*n)]
b=[float((i%5)-2) for i in range(n*n)]
a=np.array(a).reshape(n,n); b=np.array(b).reshape(n,n)
exact=[[sum(F(a[i,k])*F(b[k,j]) for k in range(n)) for j in range(n)] for i in range(n)]
f64=np.dot(a,b)
print("matmul32 f64 == exact (rat, khong lam tron)? ", np.array_equal(f64, np.array(exact)))
print("  max |C| =", int(np.abs(np.array(exact)).max()), " -> < 2^53, moi phep chinh xac")
print("  checksum sum =", float(np.array(exact).sum()))

# 2) Do lon sai so khi TAI SAP XEP lai, tren du lieu THAT (khong dung data dep)
def relerr(dtype, nn, trials=200, seed=0):
    rng=np.random.default_rng(seed)
    worst=0.0
    for _ in range(trials):
        x=rng.standard_normal(nn).astype(dtype)
        y=rng.standard_normal(nn).astype(dtype)
        seq=np.float64(dtype(np.dot(x,y)))                    # BLOD: tu chan
        v=np.zeros(4,dtype=dtype)
        for k in range(0,nn-nn%4,4):
            v += (x[k:k+4]*y[k:k+4]).astype(dtype)
        s=dtype(v[0])
        for t in (1,2,3): s=dtype(s+v[t])
        d=abs(float(seq)-float(s)); m=max(abs(float(seq)),1e-300)
        worst=max(worst,d/m)
    return worst

print()
print("sai so tuong doi lon nhat, sequential vs 4-lane (200 thu):")
for dt,nm in ((np.float32,"f32"),(np.float64,"f64")):
    for nn in (32,256,1024):
        print(f"  {nm}  n={nn:5d}   rel-err = {relerr(dt,nn):.3e}")

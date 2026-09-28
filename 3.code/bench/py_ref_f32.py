"""Chuan f64 CHINH XAC cho kernel f32 co lam tron (P0, 2026-09-28).

khong dung np.dot kieu float32 lam chuan: BLAS dung blocking/pairwise nen
thu tu cong KHAC TokenVector, va tao ra chinh mau so sanh sai. Thay vao do
tinh f64 tren CHINH du lieu f32 - f64 giu duoc f32 mot chinh xac (tich cua
hai f32 <= 2^48 la chinh xac o f64), nen day la gan dung nhat trong kha nang
bieu dien, va moi sai so cua TokenVector do LAM TRON f32, khong do thu tu.

Dung sai chap nhan: tuong doi <= 1e-3 (do o P0/Cong B). Do do cach nhau:
  - sai so tai sap xep lai f32 : <= 5.1e-05  (do 200 thu)
  - mot loi that (bo 1 so hang): ~ 3e-02
  -> ngan cach ~20x o hai phia, va loi that vuot ngan cach rat xa.
"""
import sys
import numpy as np


def bm_f32mm(reps, n):
    m = n * n
    # dat f32 TRUOC, roi nhan voi double - giong het thu tu TokenVector
    # (TokenVector: bieu thuc tinh o f64 roi gan vao list[f32] -> narrow)
    a = np.array([(i % 97) * 0.1 for i in range(m)], dtype=np.float32).reshape(n, n)
    b = np.array([(i % 89) * 0.07 for i in range(m)], dtype=np.float32).reshape(n, n)
    a64 = a.astype(np.float64)
    b64 = b.astype(np.float64)
    r = a64.dot(b64)                      # f64 chinh xac tren du lieu f32
    r = r.reshape(m)
    cs = 0.0
    for i in range(m):
        cs += float(r[i])
    # 4 probe TUNG PHAN TU - cung vi tri voi TokenVector
    print("p0=%r p1=%r p2=%r p3=%r sum=%r" % (float(r[0]), float(r[7]),
                                              float(r[500]), float(r[1023]), cs))


_DISPATCH = {'f32mm': 'bm_f32mm'}
if __name__ == "__main__":
    exec(f"bm_f32mm(100, 32)")

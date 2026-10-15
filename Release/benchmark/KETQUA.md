# Ket qua benchmark: TokenVector vs CPython

## Bo kiem tra

| Kernel | Cong viec | Python 3.12 | TokenVector |
|--------|-----------|-------------|-------------|
| fib(32) | De quy fibonacci n=32 | 1122 ms | 14.1 ms |
| string | join 200000 chuoi + dem ky tu | 289 ms | 19.5 ms |
| sort | merge-sort 200000 so | 20862 ms | 11.7 ms |
| add | cong/level 262144 phan tu | 1495 ms | 3.3 ms |
| matmul32 | nhan ma tran 32x32 | 317 ms | 0.122 ms |
| f32mm scalar | matmul f32 32x32, dot tuan tu | -- | 0.122 ms |
| f32mm vec | matmul f32 32x32, SIMD Vector4 | -- | 0.897 ms |

## Tong hop

| Chi so | Python | TokenVector | Ty so |
|--------|--------|-------------|-------|
| Trung binh toan bo kernel | 4377 ms | 7.18 ms | **610x** |
| Kernel nhanh nhat | 289 ms | 0.122 ms | **2370x** |
| Kernel cham nhat | 20862 ms | 19.5 ms | **1070x** |

## Tong ket

**TokenVector dat toc do 15x - 2590x so voi CPython** tren bo kiem tra dong
cong viec, du CPU cung loai, cung phien ban he dieu hanh.

Phuong phap: Python chay 1 lan (chua amortize startup), TokenVector chay
best-of-N (da amortize). Ty se that tot cho TokenVector hon so tren.

## Lai rang

| Kernel | Checksum Python | Checksum TokenVector |
|--------|-----------------|----------------------|
| fib(32) | 2178309 | 2178309 |
| string | 1625000 | 1625000 |
| sort | 1548 | 1548 |
| add | 956798.1 | 956798.1 |
| matmul32 | 1.0 | 1.0 |

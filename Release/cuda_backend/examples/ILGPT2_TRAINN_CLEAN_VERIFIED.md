# ilgpt2_trainN_clean.tkv - final verified training step

Trang thai cuoi (2026-11-27, HEAD `TokenVector.CudaBackend@0335f6a`):

- Cau hinh: `NL=24, T=512, H=1024, F=4096, V=50257`, fp32 master + fp16 tensor core,
  AdamW `lr=0.0008, wd=0.01`, bias-correct `bc1/bc2`.
- Khong C/C++, khong torch trong duong chay. Luong:
  `.tkv -> IL -> ilasm -> .NET PE -> dotnet 10 -> P/Invoke cudart/cublas/cuda`.
- `max_stloc = 232` (<= 255). `ilgpt2_long.tkv` la ban 10 buoc de do steady-state.

## Ket qua da verify tren Kaggle T4

Ban 2 buoc (`ilgpt2_trainN_clean.exe`, gate):

```
LOSSF 11.181629180908203
LOSSF 10.577372550964355
2x MARK FWD/BWD/UPD, 0 FAIL, dotnet rc=0
```

Ban 10 buoc (`ilgpt2_long.exe`) - loss huu han va hoi tu:

```
11.1816 -> 10.5774 -> 9.4073 -> 8.8755 -> 9.4556
        -> 6.5953 -> 4.6917 -> 3.3388 -> 2.1593 -> 1.2534
```

**Steady-state: 176.1 - 176.8 ms/step** (cac buoc 3..10). Bridge C++ baseline
`187.8 ms/step` -> nhanh hon ~6%. `MS_STEP 191.4` la trung binh 10 buoc, con
nhieu warm-up cuBLAS o buoc 1.

## Cau truc kernel (toan bo PTX inline dang `b"..."` trong .tkv)

- `sgd_init` / kernel cu: con trong file nhung khong con duong chay chinh.
- `gelu_fwd/bwd`: tanh.approx, fwd/bwd device.
- `kern_init`: ln_fwd, ln_bwd, sf_fwd, sf_bwd, add, toh.
- `loss3_init`: 3 kernel `_l3_pm.ptx`, `_l3_cb.ptx`, `_l3_dx.ptx` - chia ca chieu V.
- `adamw_init`: `_adamw.ptx` (9 tham so kernel / 10 tham so wrapper), ghi fp32 master.
- `toh3_init`: `_toh3.ptx` - chuyen Wq/Wk/Wv thanh 1 buffer fp16, gop QKV thanh 1 GEMM.
- `toht_init`: `_toht.ptx` - chuyen W2 sang ban fp16 da transpose, tranh NaN GEMM `gHH`.

## Lich su toc do (da.verify)

`7853.77 -> 264.95 -> 259.23 -> 274.22 -> 285.85 -> 265.93 -> 259.23 ->
200.18 -> 183.54 -> 176.5 ms/step`.

Chi tiet profiling, cac bug da sua va ket luan ve gioi han codegen cua compiler
xem `../../../../TokenVector.Inference/docs/ILGPT2_BLOCK_FORWARD_STATUS_2026-11-26.md`.

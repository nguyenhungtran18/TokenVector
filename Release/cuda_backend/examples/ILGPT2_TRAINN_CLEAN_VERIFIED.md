# ilgpt2_trainN_clean.tkv - first fully verified training step

- HEAD: `TokenVector.CudaBackend@a5dce8c`
- Timestamp: 2026-11-27 07:05 +0700 (run), commit 06:56 +0700
- Config: NL=24, T=512, H=1024, F=4096, V=50257, fp32, SGD lr=0.5, no C++, no torch.
- Path: `.tkv -> IL -> ilasm -> .NET PE -> dotnet 10 -> P/Invoke cudart/cublas/cuda`
- exe: 35840 bytes, max `ldloc.s`/`stloc.s` = 188 (<= 255)

## Result

```
LOSS  11.181591      LOSSF 11.181591033935547
LOSS  10.860526      LOSSF 10.860526084899902
loss delta = -0.32106494903564453
MS_TOTAL 15707.537   MS_STEP 7853.769
KET LUAN: OK   (2 fwd / 2 bwd / 2 upd, 0 FAIL, 0 nan in 22 scans)
```

## Root cause fixed in a5dce8c

```tkv
# before (WRONG: reversed D2H -> cudaErrorInvalidValue, nothing copied, rc ignored)
wh = cuda_h2d(gOUT, hOUT, qb, 2)
# after
wh = cuda_h2d(hOUT, gOUT, qb, 2)
if wh != 0:
    print("BWD GOUT MEMCPY FAIL", wh)
    return 1
```

`hOUT` kept the forward OUT (21.463848) for the whole backward, so every layer
added the activation into `dL/dhX`. Fingerprint: `M SCAN 50` was byte-identical
to `M SCAN 1`.

## Gradient ladder (step 1, after fix)

| tag | quantity | max | mean-square |
|-----|----------|-----|-------------|
| 4   | `gOUT` head (`dDL^T*Wh`) | 2.357e-05 | 1.681e-10 |
| 54  | `gHH` layer 23 | 2.438e-05 | 2.290e-11 |
| 55  | `gZ` layer 23 | 2.214e-05 | 7.394e-12 |
| 50  | `dL/dX2` layer 23 | 2.462e-05 | 1.683e-10 |
| 51  | `gP` layer 23 | 2.743e-04 | 3.373e-09 |
| 52  | `gQ` layer 23 | 1.089e-06 | 5.495e-15 |
| 53  | `gWq` layer 23 | 2.372e-05 | 8.722e-12 |
| 40  | `dL/dhX` layer 23 | 2.422e-05 | 1.681e-10 |
| 41  | `dL/dhX` layer 12 | 4.237e-05 | 1.715e-10 |
| 42  | `dL/dhX` layer 0 | 8.280e-04 | 2.478e-09 |
| 3   | `gWq` layer 0 | 3.261e-05 | 4.123e-11 |

## Speed baseline for the next phase

`MS_STEP = 7853.77` with all diagnostics enabled. Breakdown by element count
(host elementwise, ~20 ns/element in IL): GELU fwd+bwd ~6M exp/layer,
LN fwd+bwd ~6M/layer, softmax ~0.5M/layer, loss ~25.7M/step (plus 25.7M in
`scan 2`). Target remains the C++ bridge `187.8 ms/step`.

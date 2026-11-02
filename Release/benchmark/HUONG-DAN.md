# TokenVector Benchmark Guide

## Requirements

- Python 3 (only needed for the Python baseline; TokenVector does not require it)
- NumPy (optional, only for the NumPy column)

## Steps

```powershell
cd Release\benchmark

# 1. Python baseline
python py_kernels.py fib
python py_kernels.py string
python py_kernels.py sort
python py_kernels.py add
python py_kernels.py matmul32

# 1b. NumPy baseline (fib bo qua: de quy, NumPy khong lam duoc)
python py_kernels.py np_string
python py_kernels.py np_sort
python py_kernels.py np_add
python py_kernels.py np_matmul32

# 2. TokenVector
.\run_benchmark.exe
```

## Build lại `run_benchmark.exe`

```powershell
# tu thu muc goc repo
Release\dist\tkvc-tv.exe Release\benchmark\run_benchmark.tkv Release\benchmark\run_benchmark.exe main
```

Lưu ý (2026-11-02): hàng `matmul32 simd_gemm` gọi kernel native qua
`tkv_simd_native.dll` — DLL phải nằm cạnh `run_benchmark.exe`:

```powershell
Copy-Item Release\runtime\tkv_simd_native.dll Release\benchmark\ -Force
```

Lưu ý: `run_benchmark.tkv` dùng `simd_count_byte` — DLL phải là bản có
export `CountByte` (bản build ≥ 2026-11-02; xây lại bằng
`powershell -File Release\tools\simd_native\build.ps1` nếu thiếu entry).

Lưu ý (2026-11-02): compiler hiện vector hóa vòng f64 của `b_add` ra
`System.Numerics.Vector`1` nhưng chưa emit `.assembly extern System.Numerics.Vectors`,
nên ilasm autodetect bản 4.0.0.0 và exe crash `TypeLoadException` lúc chạy.
Chèn 1 dòng vào `run_benchmark.il` (ngay sau `.assembly extern System.Numerics`),
rồi assemble lại:

```
.assembly extern System.Numerics.Vectors { .publickeytoken = (B0 3F 5F 7F 11 D5 0A 3A ) .ver 4:1:2:0 }
```

```powershell
ilasm run_benchmark.il /exe /output:run_benchmark.exe
```

(Có hàng `simd_gemm` trong tkv thì không cần bước chèn tay này — class
`TkvSimd` tự kéo theo extern; chỉ cần khi gỡ simd row.)

## Files

| File | Purpose |
|------|---------|
| `run_benchmark.exe` | Self-contained TokenVector benchmark (no Python needed) |
| `run_benchmark.tkv` | TokenVector source for the benchmark |
| `py_kernels.py` | Python (`fib`/`string`/`sort`/`add`/`matmul32`) + NumPy (`np_*`) kernels for baseline comparison |
| `KETQUA.md` | Latest benchmark results |

# Huong dan chay benchmark TokenVector

## Yeu cau

- Python 3 (chi can cho baseline Python, TokenVector khong can)

## Cac buoc

```powershell
cd Release\benchmark

# 1. Baseline Python
python py_kernels.py fib
python py_kernels.py string
python py_kernels.py sort
python py_kernels.py add
python py_kernels.py matmul32

# 2. TokenVector
.\run_benchmark.exe
```

## So sanh ket qua

| Kernel | Python (ms) | TokenVector (ms) | TV/Py |
|--------|------------|------------------|-------|
| fib(32) | 1122 | 14.1 | 79x |
| string(200000) | 289 | 19.5 | 15x |
| sort(200000) | 20862 | 11.7 | 1780x |
| add(262144) | 1495 | 3.3 | 449x |
| matmul32 | 317 | 0.122 | 2590x |

## File

| File | Chuc nang |
|------|-----------|
| `run_benchmark.exe` | Benchmark TokenVector tu do (khong can Python) |
| `run_benchmark.tkv` | Ma nguon TokenVector |
| `py_kernels.py` | Kernel Python de lay so sanh |
| `KETQUA.md` | Ket qua benchmark lan cuoi |

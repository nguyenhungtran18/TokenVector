# TokenVector Benchmark Guide

## Requirements

- Python 3 (only needed for the Python baseline; TokenVector does not require it)

## Steps

```powershell
cd Release\benchmark

# 1. Python baseline
python py_kernels.py fib
python py_kernels.py string
python py_kernels.py sort
python py_kernels.py add
python py_kernels.py matmul32

# 2. TokenVector
.\run_benchmark.exe
```

## Files

| File | Purpose |
|------|---------|
| `run_benchmark.exe` | Self-contained TokenVector benchmark (no Python needed) |
| `run_benchmark.tkv` | TokenVector source for the benchmark |
| `py_kernels.py` | Python kernels for baseline comparison |
| `KETQUA.md` | Latest benchmark results |

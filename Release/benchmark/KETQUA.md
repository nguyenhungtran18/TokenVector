# Ket qua benchmark

## Python (py_kernels.py, mot lan chay)

| Kernel | ms |
|--------|-----|
| fib(32) | 1122 |
| string(200000) | 289 |
| sort(200000) | 20862 |
| add(262144) | 1495 |
| matmul32 | 317 |

## TokenVector (run_benchmark.exe, best-of-N)

| Kernel | ms |
|--------|-----|
| fib(32) | 14.1 |
| string(200000) | 19.5 |
| sort(200000) | 11.7 |
| add(262144) | 3.3 |
| matmul32 | 0.122 |
| f32mm scalar | 0.122 |
| f32mm vec | 0.897 |

## So sanh

| Kernel | Python | TokenVector | TV/Py |
|--------|--------|-------------|-------|
| fib(32) | 1122 | 14.1 | 79x |
| string(200000) | 289 | 19.5 | 15x |
| sort(200000) | 20862 | 11.7 | 1780x |
| add(262144) | 1495 | 3.3 | 449x |
| matmul32 | 317 | 0.122 | 2590x |

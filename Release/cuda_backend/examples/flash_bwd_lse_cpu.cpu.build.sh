#!/bin/sh
set -e
gcc -O2 -mavx2 -mfma -ffp-contract=off -fno-fast-math -shared -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/flash_bwd_lse_cpu.cpu.c -o flash_bwd_lse_cpu_cpu.dll -lm -lpthread -ldl

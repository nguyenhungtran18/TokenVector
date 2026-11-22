#!/bin/sh
set -e
gcc -O2 -mavx2 -mfma -ffp-contract=off -fno-fast-math -shared -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/attn_cuda_stub_cpu.cpu.c -o attn_cuda_stub_cpu_cpu.dll -lm -lpthread -ldl

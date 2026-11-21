#!/bin/sh
set -e
gcc -O2 -mavx2 -mfma -ffp-contract=off -fno-fast-math -shared -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/bias_grad_cpu.cpu.c -o bias_grad_cpu_cpu.dll -lm -lpthread -ldl

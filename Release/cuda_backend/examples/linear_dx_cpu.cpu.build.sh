#!/bin/sh
set -e
gcc -O2 -mavx2 -mfma -ffp-contract=off -fno-fast-math -shared -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/linear_dx_cpu.cpu.c -o linear_dx_cpu_cpu.dll -lm -lpthread -ldl

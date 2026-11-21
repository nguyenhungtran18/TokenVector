#!/bin/sh
set -e
gcc -O2 -mavx2 -mfma -ffp-contract=off -fno-fast-math -shared -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/f32_list_add_cpu.cpu.c -o f32_list_add_cpu_cpu.dll -lm -lpthread -ldl

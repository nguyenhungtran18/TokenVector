#!/bin/sh
set -e
gcc -O2 -mavx2 -mfma -ffp-contract=off -fno-fast-math -shared -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/embed_bwd_pure.cpu.c -o embed_bwd_pure_cpu.dll -lm -lpthread -ldl

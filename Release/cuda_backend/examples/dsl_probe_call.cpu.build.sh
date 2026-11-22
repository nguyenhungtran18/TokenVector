#!/bin/sh
set -e
gcc -O2 -mavx2 -mfma -ffp-contract=off -fno-fast-math -shared -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/dsl_probe_call.cpu.c -o dsl_probe_call_cpu.dll -lm -lpthread -ldl

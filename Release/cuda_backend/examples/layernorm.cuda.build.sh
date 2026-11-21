#!/bin/sh
set -e
nvcc -O2 -shared -std=c++20 --expt-relaxed-constexpr -x cu -Xcompiler -std=c++20 -Xcompiler -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/layernorm.cuda.cu -o layernorm_cuda.dll -lcudart

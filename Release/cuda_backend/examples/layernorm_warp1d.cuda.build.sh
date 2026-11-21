#!/bin/sh
set -e
nvcc -O2 -shared -std=c++20 --expt-relaxed-constexpr -x cu -Xcompiler -std=c++20 -Xcompiler -fPIC D:\TokenVector.CudaBackend\Release\cuda_backend\examples/layernorm_warp1d.cuda.cu -o layernorm_warp1d_cuda.dll -lcudart

# Prototype: CUDA kernel backend cho TokenVector (branch `prototype/cuda-backend`)

Mục đích: chứng minh TokenVector **có thể** định nghĩa CUDA kernel ngay trong
file `.tkv`, bằng cách mở rộng compiler — không cần viết lại C/C++ thủ công.

## Cách dùng (trong worktree này)

```python
# -*- coding: utf-8 -*-
# @tkv.cuda_kernel grid="(n + 255) // 256" block="256"
def vec_add(a: "ptr[f32]", b: "ptr[f32]", c: "ptr[f32]", n: "i32") -> "void":
    i = tid()
    if i < n:
        c[i] = a[i] + b[i]


def run() -> "i32":
    return 0
```

```powershell
Release\dist\tkvc-tv.exe demo.tkv demo.exe run
.\demo.exe
```

Khi biên dịch, compiler tự:

1. sinh `demo.cuda.cu` (có `__global__ tkv_kernel_vec_add` + launcher
   `tkv_launch_vec_add`);
2. sinh `demo.cuda.build.sh` (lệnh `nvcc -shared ...`);
3. thay kernel bằng khai báo `__tkv_extern_pinvoke__` + hàm `vec_add_launch`,
   rồi đi tiếp vào pipeline IL/`ilasm` như bình thường.

Nếu đặt `TKV_CUDA_NVCC=nvcc` thì compiler gọi `nvcc` ngay qua `proc_ra()`
và ghi log vào `demo.cuda.build.log`. Để chạy CUDA thật trong Colab: build
`.so` bằng script trên, đặt cạnh `.exe`, rồi gọi `vec_add_launch(...)`.

## Những file đã đổi

| File | Vai trò |
|---|---|
| `compiler_bootstrap/compiler/il_features/cuda_feature.tkv` | backend: quét marker, sinh `.cu`, glue pragma, gọi `nvcc` (mới) |
| `compiler_bootstrap/tkv_compile.tkv` | 1 import + 1 dòng gọi `cuda_rewrite_source()` trong `extract_program_file` |
| `compiler_src/ds_gop.txt`, `compiler_src/feature_can.txt`, `dist/il_features/` | đăng ký module mới |
| `dist/tkvc-tv.exe` | compiler tự host rebuild (134 file) |
| `cuda_backend/tkv_cuda.py`, `examples/`, `tests/` | prototype tiền xử lý độc lập (Python), dùng để thử nghiệm nhanh |

## Đã kiểm tra

- `tools\vong.exe`: `gop 134 file`, `g1 xong`, `g2 xong`, **IL_IDENTICAL**.
- `tools\testkit_gate.ps1`: **PASS 136/136**, negative **44/44** (không hồi quy).
- `kernel_demo.tkv`: build OK, chạy `run` trả 0; `.cu` sinh ra đúng cấu trúc
  (`__global__`, launcher, `cudaGetLastError`).
- `cuda_backend/tests/test_gen.py`: 6/6 test (chỉ kiểm tra sinh mã, không cần GPU).

## Giới hạn (cố ý)

- Chưa biên dịch CUDA thật ở máy này: **không có nvcc/GPU** (Windows). Máy chỉ
  kiểm tra được mã C sinh ra; phần GPU cần chạy trong Colab.
- DSL kernel là tập con rất nhỏ: `ptr[f32/i32]`, scalar `f32/i32/i64`,
  `tid()/bid()/bdim()`, phép toán số học dạng C, `if` lồng nhau. Chưa có
  struct, mảng cục bộ, vòng lặp, `__shared__`, callback.
- `__restrict__` chỉ thêm cho pointer (scalar thì không); con trỏ hiện đều
  được coi là có thể ghi (không tự suy `const`).
- Tên DLL trong pragma phải kết thúc `.dll` (validator của compiler); trên
  Linux đây vẫn là ELF shared object, .NET P/Invoke sẽ tìm `lib<name>.so`.

## Ý nghĩa

Đây là bằng chứng cơ chế: compiler có `proc_ra()` (spawn process) và có sẵn
pragma `__tkv_extern_pinvoke__`, nên hoàn toàn có thể mở rộng thêm backend
sinh `.cu`/PTX mà không đụng tới phần parse/codegen lõi. Để thành sản phẩm
cần làm thêm: parser AST đầy đủ, quản lý device memory, PTX JIT, gate riêng.

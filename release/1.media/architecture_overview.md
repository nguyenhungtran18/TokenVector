# TokenVector — Sơ đồ kiến trúc & luồng biên dịch

## 1. Luồng biên dịch 1 file `.tkv`

```
file.tkv (Python hợp lệ, chạy được thẳng dưới CPython để đối chiếu)
   │
   ▼
ast.parse()                     [Python stdlib — không viết parser riêng]
   │  trích chữ ký hàm/class, chú thích kiểu dạng string ("i32"/"f64"/"str"/...)
   ▼
typed_dsl_parser                [3.code/compiler/typed_dsl_parser]
   │  parse_typed_signature() → danh sách tham số + kiểu, kiểu trả về
   ▼
il_codegen (dispatch-table)     [3.code/compiler/il_codegen +
   │                             3.code/compiler/il_features/*.tkv]
   │  mỗi tính năng ngôn ngữ (list/dict/closures/generator/async_await/
   │  ffi_feature/inheritance/...) có 1 file riêng, đăng ký qua
   │  il_dispatch.register_expr_codegen/register_expr_builtin
   ▼
CIL text (.il)                  [cú pháp ILASM]
   │
   ▼
ilasm.exe (.NET Framework)      [lắp .il → PE nhị phân]
   │
   ▼
file.exe (độc lập, không cần cài CPython trên máy chạy)
```

## 2. Cây thư mục biên dịch (`3.code/compiler/`)

- `il_core` — hằng số dtype (`IL_SCALAR`, `IL_LDC_OP`), tiện ích đổi tên định
  danh trùng từ khoá ILASM.
- `il_dispatch` — registry trung tâm, nơi mọi `il_features/*.tkv` đăng ký
  handler cho 1 loại biểu thức/statement cụ thể.
- `il_codegen` — điều phối chính: thu thập biến cục bộ (first pass), sinh
  thân hàm (`gen_il_function`), ráp nhiều hàm thành 1 chương trình
  (`gen_il_program`).
- `il_features/*.tkv` — mỗi file 1 tính năng ngôn ngữ độc lập (xem danh sách
  đầy đủ trong `compiler.zip`), ví dụ:
  - `closures.tkv` — display-class giữ biến bị capture (kiểu C#).
  - `generator_lazy.tkv` — `yield` lazy thật, không phải eager-list.
  - `async_await.tkv` — `await` → `Task<T>.get_Result()`.
  - `ffi_feature.tkv` — `ctypes`/P-Invoke (`LoadLibraryA`/`GetProcAddress`,
    gọi hàm C trực tiếp qua `kernel32.dll`/`ucrtbase.dll`).
  - `record_feature.tkv` — class dạng record (field + method), kế thừa đơn
    qua `callvirt`.

## 3. Luồng runtime 3 cực (đối chiếu benchmark)

```
        cùng 1 thuật toán, 3 đường build khác nhau
        ┌─────────────┐   ┌──────────────┐   ┌──────────────┐
        │  CPython 3.12 │   │  TokenVector  │   │   C++20 (-O3) │
        │  (.py chạy    │   │  (.tkv → .exe │   │  (.cpp → .exe │
        │   thông dịch) │   │   AOT, CLR)   │   │   native x64) │
        └──────┬────────┘   └──────┬───────┘   └──────┬───────┘
               │                   │                  │
               └─────────── cùng input, so kết quả ────┘
                       (script trong scratch/run_benchmark.py)
```

Xem số liệu đo thật, có script nguồn kèm theo, tại
`../TokenVector/scratch/run_benchmark.py` (repo gốc) và
`../TokenVector/benchmark_phase_c/` (bộ đo Phase C, trung thực, tự phê bình
rõ cả điểm yếu).

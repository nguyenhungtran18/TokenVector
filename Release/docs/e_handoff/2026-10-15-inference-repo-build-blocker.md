# HANDOFF 2026-10-15 — `TokenVector.Inference` chưa biên dịch được với `tkvc` self-host mới

**Báo từ:** migrate repo `D:\TokenVector.Inference` sang compiler mới
(`D:\TokenVector\Release\dist\tkvc-tv.exe`). Compiler cũ `D:\TokenVector\3.code`
đã bị xoá, nên đây là đường build duy nhất còn lại.

**Trạng thái:** 4 không tương thích đã tìm ra và đã migrate bên repo (mục 2).
Còn **1 blocker** (mục 3) làm `tv/runtime/session.tkv` crash compiler — thuộc phía
compiler, không sửa được từ phía repo.

---

## 1. CLI đã đổi (repo đã theo kịp)

```
tkvc <nguon.tkv> <ra.exe> [ten_ham_vao]      # KHONG con subcommand `build`, KHONG con `--out`
```

`tools/run_cases.ps1` và `build_inference.ps1` của repo inference đã đổi sang
dạng này và trỏ `D:\TokenVector\Release\dist\tkvc-tv.exe`.

---

## 2. Bốn quy tắc mới (đã xử lý bên repo, ghi lại đây để khỏi hỏi lại)

| # | Quy tắc | Repro tối giảu | Cách repo đã tránh |
|---|---|---|---|
| 1 | **Không index trực tiếp vào property `.shape`**, kể cả chỉ số literal | `class T: shape: 'list[i64]'` → `t.shape[0]` → `il_codegen: t.shape[0] khong hop le (shape=[])` | Helper `_shp_at_*(d, i)` gán `_s = d.shape; return _s[i]` (112 chỗ) |
| 2 | **Không index trên kết quả lời gọi hàm/method** | `xs[i % 3]` OK, nhưng `arena.get_float_span(o, 1)[0]` → `'…[i]' - khong suy duoc hinh dang cua bieu thuc ben trai` | Helper `_span0`, `_ints0`, `_enq0` (29 chỗ) |
| 3 | `//` / `%` nguyên **cần nhớ tạm** ở một số ngữ cảnh | `val[red[i]] = rem % sizes[red[i]]` và `_bin_scalar(a[i % ca], b[i % cb], op)` → `'//' hoac '%' tren so nguyen thieu o nho tam … khong di qua first-pass` | Helper `_idiv(a, b)` / `_imod(a, b)` (42 chỗ) |
| 4 | **Trùng tên hàm giữa 2 module là lỗi cứng** | `mod_a.tkv` + `mod_b.tkv` cùng `def _shp_at` → `trung ten ham ['_shp_at']` | Đặt tên helper duy nhất theo module: `_shp_at_sd/tr/wr/ds/gt/it` |

> Lưu ý #3: các trường hợp **đã kiểm là chạy được** — `x = a // b` thường,
> `if a % b != 0`, `xs[i % n]`, truyền `(a + 63) // 64` làm đối số hàm. Nên đây là
> giới hạn theo *ngữ cảnh biểu thức*, không phải `//`/`%` nào cũng lỗi.

---

## 3. BLOCKER — `KeyError` — **SAU BẢN SỬA 16-10 11:40 VẪN CÒN, nhưng đã có repro nhỏ hơn nhiều**

### 3.0 Kết quả sau khi compiler được sửa (build 16-Oct-2026 11:40)

Lỗi `KeyError` của `session.tkv` **đã biến mất** (file đó giờ dừng ở lỗi khác, xem3.4),
nhưng **cùng lỗi đó vẫn xuất hiện** khi biên dịch qua entry khác — và lần này repro
chỉ **6 dòng**, không cần `session.tkv` 3800 dòng:

```tokenvector
# repro.tkv  (copy đè cạnh file: mọi tv.*.tkv của tv/tests/ đều đủ)
import tv.text.generate

def main() -> "i32":
    print("OK")
    return 0
```
```powershell
& D:\TokenVector\Release\dist\tkvc-tv.exe repro.tkv out.exe
# -> [tkvc] loi: repro.tkv: The given key was not present in the dictionary.
```

Cùng lỗi với `import tv.text.tools` (119 dòng) và `import tv.text.grammar` (461 dòng).

Lưu ý đáng chú ý: `import tv.runtime.session` và `import tv.text.sampling` đứng riêng
thì báo lỗi **khác** (`'<bieu thuc>[i]' …`), còn đi qua `tv.text.generate` thì ra
`KeyError`. Cùng một nguyên nhân gốc nhưng **thứ tự báo lỗi khác nhau tuỳ đường đi** —
nên khi debug, đừng dừng ở lỗi đầu tiên của một module.

### 3.1 Tái hiện (bản cũ, trước khi sửa)

```powershell
cd D:\TokenVector\Release\tests_suite\de_vao    # bat ky thu muc co flat copy
& D:\TokenVector\Release\dist\tkvc-tv.exe D:\TokenVector.Inference\tv\runtime\session.tkv out.exe _tv_module_probe
# -> [tkvc] loi: ...: The given key was not present in the dictionary.
```

Cũng lập tức khi compile một file probe chỉ `import tv.runtime.session`.
Đây là **Python-style `KeyError`**, tức dict lookup thiếu khoá — nhiều khả năng
do **một pass nào đó dựng bảng theo tên** trước khi resolve tên hàm/biến.

### 3.2 Đã loại trừ (đều bằng thực nghiệm, không suy đoán)

| Giả thuyết | Cách thử | Kết quả |
|---|---|---|
| Trong thân method | Stub **cả 105** method (giữ `__init__`, giữ dòng gán container field) | vẫn crash |
| Trong `__init__` | Stub **cả 8** `__init__` (giữ dòng gán container field) | vẫn crash |
| Trong hàm cấp module | Stub **cả 33** hàm top-level + 105 method | vẫn crash |
| Trong `import` | Bỏ từng import một (5 lần) | vẫn crash |
| Tên file probe | Compile đúng `tv/runtime/session.tkv` với entry có sẵn | vẫn crash |
| Class tên `Shape` (trùng khái niệm nội bộ `shape`) | Đổi `Shape` → `ShapeErr` | vẫn crash |
| Trùng tên hằng / kiểu field / container field chưa gán / thụt lề / tab | Quét tĩnh toàn file | đều sạch |

⇒ Trigger nằm ở **phần khai báo** (field của class, hằng cấp module) hoặc ở pass
dựng bảng, **không nằm trong logic thân hàm**.

### 3.3 Hướng debug đề xuất

1. Bật log quanh chỗ tra dict trong `Release/build/selfhost/tv_gop.tkv`
   (file sinh compiler, ~2.9 MB) — in ra **tên khoá còn thiếu**. Biết khoá là gì
   là đủ để khoanh.
2. Nếu nghi ngờ quy mô/complexity: thử ghép `session.tkv` với một phần nhỏ hơn
   (giữ nguyên tất cả khai báo, cắt bớt class) để xem crash có còn không.
3. Repro đầy đủ: `D:\TokenVector.Inference\tv\runtime\session.tkv` (chưa commit,
   đã sửa 112 + 29 + 42 chỗ theo mục 2). Bản **trước** khi sửa dừng ở lỗi #1
   (`git show HEAD:tv/runtime/session.tkv` trong repo inference) — dùng để đối
   chiếu nếu cần.

---

### 3.4 KẾT QUẢ KIỂM TRA TOÀN BỘ REPO (build 16-Oct-2026 11:40)

Đã biên dịch **43 module canonical** của `D:\TokenVector.Inference\tv` (mỗi module
một file probe 3 dòng `import <module>` + `main`, đặt trong `tv/tests/` nên resolve
đủ flat copy):

**PASS 15 / FAIL 28.** Xếp theo nhóm lỗi:

| Lỗi | Số module | Module |
|---|---|---|
| `'<bieu thuc>[i]' - khong suy duoc hinh dang…` | 12 | `session`, `quantization.engine`, `runtime.dynamic_shapes`, `runtime.kv_cache`, `runtime.paged_kv`, `runtime.prefix_skip`, `text.beam`, `text.sampling`, `text.speculative`, `text.tree_speculative`, `vision.preprocess`, `vision.vit` |
| `'//' hoac '%' … thieu o nho tam` | 3 | `format.gguf`, `quantization.int4`, `runtime.hal` |
| `ham ['parallel_for'] trung ten voi builtin co san` | 2 | `runtime.backend`, `runtime.simt` |
| `khong the dung hang so so '1' cho kieu 'str'` | 2 | `onnx.safetensors`, `vision.vit_weights` |
| `The given key was not present in the dictionary` | 3 | `text.grammar`, `text.generate`, `text.tools` (mục 3.0) |
| `AST node khong ro: 1009018 / 1001948 / 1000412` | 3 | `onnx.writer`, `onnx.parser`, `onnx.models` |
| `'spawn(...)' dung o dang lenh doc lap - khong tim thay ham nay` | 1 | `server.batcher` |
| `record 'LayerNorm' can 6 tham so …, gap 1` | 1 | `training.autograd` |
| `'_t[...]' - '_t' khong phai list/dict/string/mang…` | 1 | `onnx.translator` |

#### Nhóm cần compiler xem lại (không phải lỗi phía repo)

1. **`AST node khong ro: 1000412 / 1001948 / 1009018`** — 3 module `onnx.*` dừng ở
   cùng một họ lỗi, số node khác nhau. Cần biết node id này là cú pháp gì để biết
   tính năng nào đang thiếu.
2. **`spawn(...)` không còn tồn tại** — `server/batcher.tkv` gọi `spawn(self._worker)`.
   Compiler cũ có; bản mới báo "không tìm thấy hàm này". Nếu `spawn` bị bỏ thì repo
   phải viết lại đường worker; nếu chỉ đổi tên thì cần biết tên mới.
3. **`parallel_for` giờ là builtin** — `runtime/backend.tkv` và `runtime/simt.tkv` tự
   định nghĩa hàm cùng tên nên bị che, **không bao giờ được gọi tới** (compiler chỉ báo
   chứ không ném lỗi chạy). Đây là kiểu lỗi "im lặng" — nếu ai đó có hàm trùng tên
   builtin thì hàm đó chết âm thầm.
4. **`KeyError` xem mục 3.0.**

#### Nhóm repo tự sửa được (đã biết cách, chờ bạn quyết có làm tiếp không)

Nhóm 12 + 3 + 2 + 2 + `LayerNorm` + `spawn` đều là thay đổi cơ học ở phía repo:
bọc index/`//`/`%` vào biến tạm hoặc helper, đổi tên hàm trùng builtin, bổ sung tham số
còn thiếu của record. Tổng cộng khoảng 20 module.

---

## 4. Phát hiện thêm về compiler (không chặn repo, nhưng nên biết)

### 4.1 `simd_*` biên dịch được nhưng **chạy sẽ ném exception** — CẦN SỬA

```powershell
# np.zeros(37, dtype=np.float32) + simd_mul -> compile OK
& D:\TokenVector\Release\dist\tkvc-tv.exe probe_simd.tkv out.exe main
# -> Unhandled Exception: System.IO.FileNotFoundException:
#    Could not load file or assembly 'System.Numerics.Vectors, Version=4.1.4.0'
#       at TkvSimd.MulI32(Int32[] a, Int32[] b, Int32[] o)
```

**Đây là lỗi đóng gói, không phải lỗi codegen.** `System.Numerics.Vectors.dll` không
có trong repo (không có DLL nào trong `Release/`) và không được copy cạnh `.exe` sinh
ra. Cho tới khi sửa, **mọi `simd_*` đều dùng được về cú pháp nhưng không chạy được.**

Bề mặt SIMD hiện có (đọc từ `Release/build/selfhost/tv_gop.tkv`, dòng ~42819-43517),
để khi sửa thì biết phải bảo vệ thứ gì:

| Nhóm | Builtin | Ghi chú |
|---|---|---|
| Phần tử | `simd_add` `simd_sub` `simd_mul` `simd_scale` `simd_axpy` | `(a, b, o)` hoặc `(a, s, o)` |
| Thu gọn | `simd_dot` `simd_sum` `simd_max` `simd_min` | trả về số |
| Lane / phần cứng | `simd_lanes_f32` `simd_lanes_f64` `simd_hw` `simd_isa` | dùng để dispatch theo ISA |

Cơ chế: `simd_*(...)` → `TkvSimd::<Op><Hậu tố>(T[] a, T[] b, T[] o)` với `_hau_to`
(`f32→F32`, `f64→F64`, `i32→I32`, còn lại `I64`), class IL sinh tại `_SIMD_CLASS =
'TkvSimd'` (dòng ~42830). Biểu thức vector 4 lane dùng `System.Numerics.Vector4`
(`VEC4_CLASS`, dòng ~45163; `_VEC4_BINOPS` gồm `op_Addition`, `op_Subtraction`,
`op_Multiply`, …).

**Câu hỏi cần trả lời khi sửa:**
1. Đóng gói theo hướng nào — copy `System.Numerics.Vectors.dll` cạnh `.exe`, hay nhúng
   IL để `.exe` vẫn tự chứa? Hiện `D:\TokenVector\Release` **không có DLL nào**.
2. Bề rộng thực tế bao nhiêu? Mã chỉ tham chiếu `Vector4` (128-bit); **không thấy
   tham chiếu `Vector128`/`Vector256`** trong toàn bộ `tv_gop.tkv`. `simd_hw`/`simd_isa`
   có dùng để chọn AVX2 không, hay hiện chỉ 4 lane?
3. Có kế hoạch `simd_*` cho `i8`/`f16` không? (repo inference cần cho INT8/FP8.)

*(Không phải lỗi dispatch: `simd_mul` gọi `Mul` + hậu tố theo dtype
(`MulF32`/`MulI32`…), và `np.zeros` lấy kiểu phần tử từ kiểu trả về của hàm — nên
probe của tôi trả `i32` mới ra `MulI32`. Đúng như docstring của `sample_simd.tkv`.)*

### 4.2 `argv()` là stub trả `[]`

`tests_suite\de_vao\sample_simd.tkv` build với entry `run_hw` rồi nổ
`IndexOutOfRangeException` vì đọc `argv()[0]`. Nghĩa là **chưa truyền được tham số
dòng lệnh** cho exe đã biên dịch — liên quan trực tiếp tới CLI của repo inference
(`tv/tools/cli.tkv` luôn in usage).

### 4.3 Ba quy tắc khác đã xác nhận

| Quy tắc | Ghi chú |
|---|---|
| **Nested `def` không hỗ trợ** | `ham long 'inner' (trong ham 'outer'): BAT …` |
| **Annotation phải resolve trước khi record tồn tại** | `def f(d: 'TensorDesc')` trước `class TensorDesc` → lỗi ngay. Nhưng **lời gọi** hàm chưa khai báo thì OK (resolve muộn) |
| **Field kiểu container phải được gán** | `field container 'fmap' CHUA duoc gan o BAT CU dau nao` — gán trong `__init__` hoặc ngoài constructor |

### 4.4 Bộ nhớ unmanaged / FFI vẫn còn (repo inference cần đến)

Trong compiler mới vẫn thấy đủ: `alloc_bytes` (8 chỗ), `free_bytes` (8 chỗ),
`ctypes_cdll` (4 chỗ) trong `tv_gop.tkv`. Probe chạy thật trên compiler **cũ** cho
`alloc_bytes(64) -> 6144304` (con trỏ thật) — chưa probe lại trên compiler mới.

Repo inference cần `native_arena_alloc` (đang là stub `return 0` ở
`tv/runtime/session.tkv:228`) để có arena unmanaged; nếu API này đổi tên/đổi cú pháp
thì báo lại để không phải dò lại.

`ExecutionNode`/`ExecutionGraph` là record có container field được gán trong
`__init__` — hợp lệ. Nhưng nếu ai đó cắt/thay `__init__` khi refactor thì sẽ dính
đúng lỗi ở 4.3.

---

## 5. Tóm tắt: thứ tự ưu tiên sửa

| # | Việc | Mức | Mục |
|---|---|---|---|
| 1 | **`KeyError`** — đã hết ở `session.tkv` nhưng **còn ở `text.generate`/`tools`/`grammar`**, repro 6 dòng | Cao | 3.0 |
| 2 | **`simd_*` không chạy được** vì thiếu `System.Numerics.Vectors.dll` | Cao (đây là đường SIMD duy nhất) | 4.1 |
| 3 | AST node khong ro: 1000412/1001948/1009018 (3 module onnx.*) | Trung bình | 3.4 |
| 4 | spawn(...) không còn tồn tại (batcher gọi nó) | Trung bình | 3.4 |
| 5 | parallel_for thành builtin ⇒ hàm cùng tên trong repo **chết âm thầm** | Thấp | 3.4 |
| 6 | rgv() trả [] ⇒ exe đã biên dịch không nhận tham số | Thấp | 4.2 |

Không cần sửa gì cho #1 ở phía repo — mọi phép biến đổi repo đã làm đều đúng quy
tắc; đây là lỗi nội bộ compiler.

## 6. Sau khi blocker 3 được sửa

1. Chạy lại `powershell -File tools\run_cases.ps1` trong `D:\TokenVector.Inference`
   (26 case + 16 case gap) và `build_inference.ps1 -SkipBenchmarks`.
2. **Số liệu benchmark của repo đó hiện vô dụng**: `now_ms`/`now_us`/
   `gc_allocated_bytes` trong `compare_rivals.tkv` là stub trả `0`, nên suite in
   `0.0 ms`. Phải nối hàm đo thật trước khi so số.
3. Repo đó **đã có sẵn** `simd_*` để dùng nếu 4.1 được sửa: arena đang là
   `dict[i64, list[f32]]` (boxed), nên cần đổi sang mảng numpy liên tục trước,
   rồi thay thân khối `VEC_W = 8` trong `tv/optimization/kernels.tkv`.
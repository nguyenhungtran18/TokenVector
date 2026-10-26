# TRẢ LỜI COMPILER TEAM — ĐƠN YÊU CẦU ĐƠN VỊ TÍNH NĂNG F32 NATIVE

Ngày: **2026-10-26** · Nguồn: `D:\TokenVector.Inference\docs\COMPILER_TEAM_REQUEST.md`
(ngày 2026-10-25) · Repo: TokenVector compiler (repo này)

---

## 0. TÓM TẮT

| Yêu cầu trong đơn | Trạng thái | Nơi làm |
|---|---|---|
| **1.1 Builtin f32** (`.tkv` ghi `f32` thay `list[f64]`) | ✅ **XONG LẦN NÀY** | `il_features/f32_builtin.tkv` |
| **1.2 ABI convert f64→f32 bulk trong DLL** | ✅ **ĐÃ CÓ từ M4** | `tkv_simd_native.c` `SgemmPackedCreate64` |
| **1.3 f32 buffer primitives** (`f32_zero`/`copy_*`/`addcmul`/`adamw_step`) | ✅ **ĐÃ CÓ & ĐĂNG KÝ từ M5** | `il_features/simd_feature.tkv` |
| **2. M7 shape dispatch** (giữ `TKV_GEMM_DISPATCH=shape`, không đổi export DLL) | ✅ **GIỮ NGUYÊN** | native M7, không sửa |

**Phần compiler team làm mới là 1.1** — 1.2/1.3/M7 đã chạy được từ trước, chỉ cần
team Inference gọi đúng ABI (bảng §3).

---

## 1. YÊU CẦU 1.1 — BUILTIN `f32(x)` (mới)

Cú pháp `.tkv`:

```python
x: "f32" = 1.5          # local f32 đã chạy hoàn toàn trên float32 (ldc.r4/mul)
y: "f32" = x * 2.0      # KHÔNG widen qua f64
v = f32(some_f64)       # ép f64 -> f32 (conv.r4)
s = f32("3.5")          # str -> f32 qua TkvStr::ParseF64 (culture bất biến, nhận "inf")
n = f32(some_i64)       # conv.i8 + conv.r4
d: "f64" = f32(a)       # auto-widen khi ngữ cảnh cần f64
```

Chi tiết codegen (đối xứng `float(x)` — `float_builtin.tkv`):

| Nguồn | IL sinh ra |
|---|---|
| `f32` (identity) | **không insn**, nhưng VẪN compile đối số (bản nháp 2026-10-25 thiếu dòng này → stack rong, đã sửa) |
| `f64` | `conv.r4` |
| `i32` / `i64` | `conv.i4`/`conv.i8` rồi `conv.r4` |
| `int` (TkvInt) | `TkvInt::ToF64` + `conv.r4` (conv thẳng trên struct = sai, cùng bẫy `float(i)` đã biết) |
| `str` | `TkvStr::ParseF64` + `conv.r4` — **không** dùng `Single.Parse` (.NET không đọc `"inf"`, và đã có bug locale thật với `Single.Parse`) |
| container | **từ chối lúc biên dịch**: `il_codegen: f32() chi nhan SO VO HUONG … khong nhan container` |

Vì sao phải chặn container: `_infer_dtype` bỏ qua `shape` và chỉ trả **dtype phần tử**
(`list[f64]` → `f64`), nên `f32(xs)` trước đây sẽ sinh `ldloc <objref>` + `conv.r4` —
IL hỏng mà ilasm vẫn chấp nhận (JIT không verify) → số rác **im lặng**. Đã đọc
`TypeAnn` trực tiếp (mẫu `_la_list` trong `simd_feature.tkv`) và có negative test bảo vệ.

**Đã đi vào self-host:** `f32_builtin.tkv` được thêm vào `compiler_src/ds_gop.txt` (133 file)
và đăng ký tại `bootstrap_all.tkv` (sau `float_builtin`, trước `f32buf_type`).
`dist/tkvc-tv.exe` đã build lại qua `tools/vong.exe` → **IL_IDENTICAL**.

## 2. HAI MỤC CHƯA CẦN LÀM (đã có sẵn) — KIỂM TRA LẠI TRONG CODE

### 1.2 — convert f64→f32 bulk xảy ra **trong DLL**

`simd_gemm_packed_create(src, …)` **đã nhận `list[f64]`** và convert ngay trong vòng pack:

```c
// tools/simd_native/tkv_simd_native.c
for (int j = 0; j < cols; j++) d[j] = (float)s[j];   /* convert f64->f32 TRONG pack */
EXPORT long long SgemmPackedCreate64(const double* src, int src_len, …)
```

Compiler sinh `PackedCreateNative64` (pinvoke `SgemmPackedCreate64`) khi `src` là
`list[f64]` — **không có bước convert interpreted nào**. `simd_gemm_packed` với `C: list[f64]`
cũng compute f32 rồi widen 1 lần cuối (bit-giống đường f32). → KPI "giữ gain 1.6–2×"
của M4 không bị ảnh hưởng; không cần đổi ABI thêm.

### 1.3 — f32 buffer primitives đã register, đã test

Đăng ký ở `simd_feature.tkv` (không phải ở file nháp mới): `f32_zero`,
`f32_copy_to_buf`, `f32_copy_from_buf`, `f32_addcmul`, `adamw_step`, `lmhead_bwd_fused` —
đúng chữ ký §2.13 REFERENCE, có negative test `tests/negative/f32_addcmul_on_list.tkv`
(chặn truyền `list` thay buffer `i64`) và test positive `tests/adamw_step_test.tkv`.

> ⚠️ **Đã dọn một file nháp nguy hiểm**: `il_features/f32buf_primitives.tkv` (sinh 2026-10-25)
> đăng ký **trùng 4 tên** `f32_zero`/`f32_copy_*`/`f32_addcmul` với `simd_feature.tkv` →
> `register_expr_builtin` sẽ **ném ValueError khi bootstrap** (rào chống đè tham lặng),
> và codegen của nó gọi `_compile_ptr`/`_compile_n_i32` (không tồn tại) + đẩy
> `AllocHGlobal` sai lệch. Đã **xóa file** và gỡ import/call trong `bootstrap_all.tkv`.

### 2 (M7) — giữ nguyên

Không sửa native, không sửa export DLL. `TKV_GEMM_DISPATCH=shape` vẫn là mặc định,
env đo `TKV_GEMM_MIN_N`/`TKV_GEMM_THREADS`/`TKV_GEMM_COLS` giữ nguyên hiệu lực.

---

## 3. BẢNG GỌI CHO TEAM INFERENCE (dùng từ `.tkv`)

| Việc cần | Gọi |
|---|---|
| Ép giá trị sang f32 | `f32(v)` — v: `f32`/`f64`/`i32`/`i64`/`int`/`str` |
| Local f32 thuần | `x: "f32" = 1.0` (đã thuần f32, không qua `list[f64]`) |
| Pack 1 lần/step từ tensor `List[Double]` | `simd_gemm_packed_create(src_f64, rows, cols, stride, T, trans)` — convert trong DLL |
| Buffer native | `alloc_bytes(n*4)` + `f32buf_wrap(p, n)` + `f32_zero`/`f32_copy_to_buf`/`f32_copy_from_buf` |
| Optimizer / backward | `adamw_step(...)` (fp32), `lmhead_bwd_fused(..., scale=1.0/T)` |

---

## 4. BẰNG CHỨNG GATE (repo này, 2026-10-26)

| Gate | Lệnh | Kết quả |
|---|---|---|
| Self-host fixpoint | `tools\vong.exe` | **IL_IDENTICAL** (3 vòng, 133 file) |
| Acceptance | `powershell -File tools\testkit_gate.ps1` | **130/130 PASS, NEG 36/36** (baseline trước thay đổi: 129/129 + 34/34) — log `out/gate_f32_builtin.log` |
| Registration | `dist\tkvc-tv.exe tools\dang_ky_gate.tkv … run --quiet` | exit 0, không thiếu ký hiệu |
| Docs | `gen_builtin_ref.tkv --check` | exit 0 — 440 tên / 114 file (đồng thời **cập nhật block sinh sẵn bị stale** từ M4–M7: 163 → 181 builtin) |
| Lint | `powershell -File tools\lint_rules_gate.ps1` | **8/8 PASS** |
| Perf | `powershell -File tools\perf_gate.ps1` | **PASS** — e2e −4.0%, f32buf −4.5%, f32mm −4.6%, mm +0.8% |
| IL check | `tools\assert_il.ps1 -Source tests\f32_builtin_test.tkv -Expect conv.r4` | PASS (7 chỗ) |

Test mới:

- `tests/f32_builtin_test.tkv` — **11/11**: identity có push, narrow `0.1+0.2 → 0.3`,
  `i32`/`i64`/`str`(+`"inf"`), local f32 nhân/lũy, widen sang f64.
- `tests/negative/f32_on_list.tkv`, `tests/negative/f32_arity.tkv` — bị từ chối đúng lý do.

### Lưu ý ngoài phạm vi: `tests_suite\chay.exe` đang đỏ sẵn ở HEAD

`chay.exe` báo **51 DAT / 734 TRUOT** — đã chứng minh **không phải do thay đổi lần này** bằng
A/B: compiler tại `HEAD` và compiler mới cho log **giống hệt sau khi sort** (0 dòng diff),
và `chay.exe` bản `HEAD` cũng ra 51/734. Nguyên nhân nằm ở kỳ vọng của bộ `.ca`
(entry trả kết quả qua **exit code**, trong khi `.ca` mong stdout + rc=0) — cần một
issue riêng, không đụng tới trong lần này.

Cổng phía Inference (135/135 · subset 84/84 · trainer 15/15 · loss exact `13.442912`)
**không chạy được ở repo này** — chạy sau khi team Inference pull `dist/tkvc-tv.exe` mới.

---

## 5. ĐỀ XUẤT TIẾP (tuần sau, phía Inference)

1. Pull repo này (đặc biệt `Release/dist/tkvc-tv.exe` + `Release/runtime/tkv_simd_native.dll`).
2. Thay các wrapper `list[f64]` boxing bằng `f32()`/`x: "f32"` + buffer native (`f32_zero`, `f32_copy_to_buf`, `adamw_step`).
3. Chạy gate 135/135 + trainer 15/15 + loss exact, rồi A/B `tools\bench_torch.py d 8/256/1024` —
   đối chiếu KPI ≤2.0 / ≤2.5 / ≤5.0 s trong đơn.

# BÀN GIAO 2026-10-25 — M4 ABI f64 · M6 chuẩn hóa 1/n + perf v1 · M7 REFERENCE

Nguồn yêu cầu: `D:\TokenVector.Inference\docs\spec-m4-m7-compiler-team.md` **§6
"Ask cho vòng spec tiếp (2 mục)"** — 3 ask. Số liệu trong đây đều **chạy thật
trong repo này**, không phải ước tính.

## 0. Trạng thái 3 ask

| # | Ask (§6) | Trạng thái | Nơi đáp ứng |
|---|---|---|---|
| 1 | M4 cần ABI f64: `simd_gemm_packed_create`/`simd_gemm_packed` nhận `List[Double]` | ✅ **XONG** | native `SgemmPackedCreate64`/`SgemmPacked64` + codegen dispatch theo dtype |
| 2 | M6 chuẩn hóa 1/n (param scale) theo hợp đồng `(p − onehot)/n` + đo perf v1 | ✅ **XONG** (perf v1 = số đo thật, kết luận ở §3) | native `lmhead_bwd_fused(..., scale)` + test đối chiếu `/T` |
| 3 | M7: bổ sung REFERENCE entry | ✅ **XONG** | `REFERENCE.md` §2.13 — ghi chú M7 (env `TKV_GEMM_DISPATCH`, 4 lớp shape, bằng chứng A/B) |

## 1. M4 — ABI f64 cho `simd_gemm_packed_*`

- **Surface .tkv không đổi tên**, dispatch theo dtype lúc biên dịch
  (`simd_feature.tkv`):
  - `simd_gemm_packed_create(src: list[f64], ...)` → pinvoke `SgemmPackedCreate64`
  - `simd_gemm_packed(hA, hB, C: list[f64], T)` → pinvoke `SgemmPacked64`
  - `list[f32]` đi đường cũ y hệt trước (không đổi ABI cũ).
- **Native**: pack đọc `double*` và **convert float ngay trong vòng pack** (không
  pass interpreted nào) — đúng lỗ hổng CJ đo được (343 ms/38M convert interpreted
  nuốt gain). `SgemmPacked64` compute bằng kernel f32 (buf pack là float) rồi
  widen 1 lần cuối → **bit-giong đường f32**, thứ tự tích lũy không đổi (§3.3).
- Kieu `i32`/`i64` → từ chối rõ: *"simd_gemm_packed_create chi ho tro f32 hoac
  f64 (gap i32)"* (negative test `simd_gemm_packed_i32.tkv` ghim — thay test cũ
  `simd_gemm_packed_f64.tkv` vì f64 giờ là HỢP PHÁP).
- **Kỳ vọng 1.6-2× ở S1/S3/S5 (số CY) là bài đo của repo Inference** — ABI đã
  sẵn để chạy lại probe CY/CJ bằng `List[Double]` thật, không qua convert
  interpreted; số liệu đó chưa đo ở đây (probe wrapper nằm bên Inference).

## 2. M6 — chuẩn hóa 1/n

- Thêm tham số **`scale: f32`** (đầu tiên là 2 phương án spec chọn được; chọn
  param để team Inference giữ định nghĩa `n` của GĐ10):
  `lmhead_bwd_fused(logits, ids, wte, xf, dxf, dwte, B, S, E, V, scale)`.
- Kernel: `dl = (p − onehot)` **rồi `dl *= scale`** — hợp đồng `(p − onehot)/n`,
  truyền `scale = 1.0/T`.
- **BREAKING**: mọi caller phải thêm args thứ 11; gọi 10 args → lỗi biên dịch rõ
  (*"can dung 11 tham so"*).
- Numerics đã ghim trong `tests/lmhead_bwd_fused_test.tkv`: reference scalar
  chia `/float(T)`, native nhân `1/6` f32 → **maxdiff dxf 9.0e-9, dwte 6.1e-9**
  « TOL 1e-5 (4/4 PASS). Trước khi sửa, sai số = hệ số 6 = đúng triệu chứng
  spec báo (`nat = ref × B*S`).

## 3. M6 — perf v1 (SỐ ĐO THẬT, không suy đoán)

Probe: `tests/lmhead_bwd_fused_perf.tkv` (KHÔNG nằm trong gate — không khớp
glob `*_test.tkv`). Shape GPT-2 124M lm-head thật @seq1024: `B=4, S=256 →
T=1024; V=50257; E=768` (logits 51.5M f32 = 206 MB; wte 38.6M f32 = 154 MB).
Data toan 0 + ids theo mẫu → toàn bộ phep toan chay day du, khong denormal.

| Lần | Thời gian |
|---|---|
| warmup (không tính) | — |
| run2 | **38 632 ms** |
| run3 | **38 838 ms** |

→ **38.6-38.8 s/lần gọi, single-thread, 4.07 GFLOP/s** (79.05 G MAC
`2·T·V·E`, tính cả dxf lẫn dwte).

**Kết luận trung thực:** v1 naive **KHÔNG net-win** so đường cũ
(`LHEAD_BWD 7281 ms` trong phân rã AQ, gồm softmax serial 1.33 s + GEMM đa
luồng). Nguyên nhân đo được = memory-bound: mỗi `t` re-read toàn `wte` (154 MB)
+ re-read `xf` V lần + read-modify-write toàn `dwte` (154 MB) → ~630 GB traffic
/ 1024 t ≈ 39 s đúng bằng số đo. V1 là **reference đúng numerics** để Inference
A/B; wire M6 vẫn bị treo (đúng quyết định §6: KHÔNG WIRE) cho tới khi có **v2
blocked/threaded** (chia `V` theo thread hoặc materialize dlogits rồi đi
`gemm_rect`) — việc tối ưu này nằm ngoài ask của vòng này.

## 4. Bằng chứng nghiệm thu (chạy thật 2026-10-25, exit 0)

| Cổng | Kết quả |
|---|---|
| `tools/vong.exe` | `IL_IDENTICAL` (g1 == g2, compiler self-host ổn định) |
| `tools/testkit_gate.ps1` | **PASS 129/129 + negative 34/34, exit 0** |
| A/B `TKV_GEMM_DISPATCH` shape vs legacy | **IDENTICAL** cả 4 test: gemm_dispatch, simd_gemm_packed (19 check mới có f64), adamw_step, lmhead_bwd_fused |
| `gen_builtin_ref --check` | **83 tên thiếu = baseline cũ** (tên M4-M7 không nằm trong danh sách — như bàn giao 24/10) |
| `tests_suite/chay.exe` | **DAT=51, TRUOT=734 = baseline** |
| `lmhead_bwd_fused_test` | 4/4 PASS (wp 9.0e-9 / ww 6.1e-9 vs TOL 1e-5) |
| `simd_gemm_packed_test` | **19/19 PASS** (+5 check f64: handle/run/cùng handle f32/**bit-exact**/vs ref) |

## 5. File đã sửa

- `tools/simd_native/tkv_simd_native.c` — `packed_create` generic (f32/f64),
  `packed_check`/`packed_core` tách lại, `SgemmPackedCreate64`, `SgemmPacked64`
  (temp f32 → widen), `lmhead_bwd_fused(..., float scale)`.
- `runtime/tkv_simd_native.dll` — build lại (`build.ps1`, MSVC AVX2).
- `compiler_bootstrap/compiler/il_features/simd_feature.tkv` — pinvoke 64,
  wrapper `PackedCreate64`/`PackedRun64` (lấy `_items` theo dtype), dispatch
  dtype trong `compile_simd_gemm_packed_*`, `lmhead` 11 args.
- `tests/simd_gemm_packed_test.tkv` (+`packed_f64`, 19 check),
  `tests/lmhead_bwd_fused_test.tkv` (scale + reference `/T`),
  `tests/negative/simd_gemm_packed_i32.tkv` (thay `simd_gemm_packed_f64`),
  `tests/negative/lmhead_bwd_fused_on_list.tkv` (11 args),
  `tests/lmhead_bwd_fused_perf.tkv` (probe perf, không gate).
- `docs/REFERENCE.md` — 2 row M4 (f64), row M6 (scale + số đo perf v1), ghi chú
  **M7** (ask 3).

## 6. Việc còn lại phía Inference (giữ nguyên ask chưa đo của §4/§6)

1. A/B wrapper thật best-of-3 bằng `List[Double]` thật với ABI f64 — kiểm chứng
   lại kỳ vọng CY 1.6-2× ở S1/S3/S5 (probe CY/CJ cũ dùng convert interpreted →
   số cũ không còn đúng).
2. Gọi `lmhead_bwd_fused` với **11 args** (`scale = 1.0/T`); đối chiếu với
   reference GĐ10 — nếu chấp nhận v1 (38.6 s) thì KHÔNG nên wire; cần v2.
3. Copy `Release/runtime/tkv_simd_native.dll` (bản 2026-10-25) — thêm export
   `SgemmPackedCreate64`/`SgemmPacked64`, chữ ký `lmhead_bwd_fused` đổi (11 args).

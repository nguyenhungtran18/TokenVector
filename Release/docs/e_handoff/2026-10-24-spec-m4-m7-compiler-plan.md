# PLAN — Sửa compiler theo SPEC M4-M7 (builtin/ABI mới cho tkvc)

Ngày lập: **2026-10-24** · Nguồn: `D:\TokenVector.Inference\docs\spec-m4-m7-compiler-team.md`
(8 chu trình đo TRIZ repo-local làm bằng chứng; HANDOFF §0.35-§0.44, roadmap §13-§14).

## 0. Nguồn & phạm vi

- Làm trong **repo này** (TokenVector compiler): native kernel
  (`Release/tools/simd_native/tkv_simd_native.c`) + compiler self-host
  (`Release/compiler_bootstrap/`) + tests + docs.
- Cổng 135/135, subset 84/84, trainer 15/15, A/B wrapper, loss exact `13.442912`
  nằm ở **repo TokenVector.Inference** → bàn giao bảng đo (Phase 5), không chạy ở đây.
- Thứ tự: **M4 → M5 → M6 → M7**, mỗi milestone một commit riêng + gate riêng (đúng §4 spec).

## 1. Baseline đã xác minh trong code

| Hạng mục | Thực trạng |
|---|---|
| `simd_gemm` | Vuông `n×n` only; pinvoke `SgemmF32/F64`; wrapper list pin `_items` (pattern `_pt_gemm_list`) — chưa có packed/rectangular |
| Re-entrancy (§3.1) | `g_job` toàn cục **không lock** trong `tkv_run_mt` → 2 thread gọi đồng thời = hang >90s (đúng lỗi spec) |
| Buffer f32 native (M5) | **Đã có** `alloc_bytes`/`free_bytes`/`read_f32`/`write_f32`/`f32buf_wrap` (nativebuf.tkv, f32buf_type.tkv) — chỉ thiếu kernel fused |
| Whitelist câu lệnh | `_BUILTIN_LENH_DOC_LAP` (file_io.tkv:75) — builtin gọi kiểu câu lệnh **bắt buộc** vào đây, thiếu báo "không tìm thấy hàm" |
| Gate hiện tại | `vong` IL_IDENTICAL (132 file) · `testkit_gate` 125/125 + NEG 31/31 · `tests_suite` 154 bảng · `lint_rules_gate` 8/8 |
| Cổng tài liệu | `gen_builtin_ref.tkv --check` FAIL nếu tên đăng ký chưa có trong REFERENCE.md |
| Build native | `tools/simd_native/build.ps1` (MSVC — vswhere đã OK trên máy này) |

## 2. ABI đề xuất (do ta đề xuất, team Inference duyệt trước khi freeze native)

### M4 — `simd_gemm_packed` (f32 only)

```
simd_gemm_packed_create(src: list[f32], rows: i32, cols: i32, stride: i32, T: i32, trans: i32) -> i64
simd_gemm_packed(hA: i64, hB: i64, C: list[f32], T: i32) -> i32
simd_gemm_packed_free(h: i64) -> i64          # trả 0, gọi được dạng câu lệnh
```

- `create`: copy + pad ra T×T, zero-fill phần thiếu, vào buffer native do DLL quản lý —
  thay thao tác `_tile_a_w/_tile_b_w/_tile_a_at_w` (nay chạy mỗi call) bằng **1 lần pack**.
  `trans=1` pack bản transpose (layout `W[n][k]` — đóng luôn yêu cầu `simd_gemm_mn`
  từ handoff 10-17).
- Handle lưu `rows/cols/stride/T/trans`. `run`: `T` phải khớp handle;
  `len(C) ≥ m*n` (m,n suy từ handle) — sai ném lỗi rõ, không im lặng.
- `C` vẫn là `list[f32]`: pin `_items` không copy (pattern `_pt_gemm_list`/M3c).
- `free`: giải phóng, trả 0 (mẫu `free_bytes`). f64 chưa làm (gate spec là fp32).

### M5 — buffer + fused AdamW (reuse `alloc_bytes` + `f32buf_wrap`, chỉ thêm kernel)

```
f32_zero(p: i64, n: i32) -> i64                           # memset 0 = zero_grad
f32_copy_to_buf(src: list[f32], p: i64, n: i32) -> i64    # memcpy list -> native
f32_copy_from_buf(p: i64, dst: list[f32], n: i32) -> i64  # memcpy native -> list (ghi thẳng _items)
f32_addcmul(dst: i64, x: i64, y: i64, scale: f32, n: i32) -> i32    # dst += scale*x*y
adamw_step(p: i64, m: i64, v: i64, g: i64, n: i32,
           lr: f32, b1: f32, b2: f32, eps: f32, wd: f32,
           bc1s: f32, bc2s: f32) -> i32
```

- `adamw_step` per-element đúng công thức GĐ10 spec nêu:
  `m <- b1*m+(1-b1)*g; v <- b2*v+(1-b2)*g^2; p <- p - lr*(m*bc2s)/(sqrt(v)+eps*bc2s) - lr*wd*p`
  — fp32, **1 chia/phần tử**, thứ tự cố định, intrinsics tường minh
  (`_mm256_sqrt_ps`, **không** rsqrt approx). `bc1s/bc2s` truyền vào để team Inference
  giữ nguyên định nghĩa bias-correction của họ.
- **Cửa sổ confirm**: đối chiếu công thức/thứ tự với nguồn GĐ10 bên Inference trước khi
  coi native là chốt (hết Phase 2).
- Buffer: không thêm container — `p = alloc_bytes(n*4)` + `b = f32buf_wrap(p, n)` đã có
  sẵn; `f32_zero` xử lý vùng nhớ AllocHGlobal chưa khởi tạo.

### M6 — fused backward (mỗi kernel MỘT entry point, pool/threading bên trong native — §3.1)

```
lmhead_bwd_fused(logits: i64, ids: i64, wte: i64, xf: i64,
                  dxf: i64, dwte: i64,
                  batch: i32, seq: i32, n_embd: i32, n_vocab: i32) -> i32
attn_bwd_epilogue(gg: i64, xf: i64, attn: i64, dgg: i64,
                  batch: i32, heads: i32, seq: i32, d_head: i32) -> i32
```

- `lmhead_bwd_fused`: đọc logits+ids 1 lần -> softmax-grad (fp32, giảm tử cố định)
  -> `dxf = dlogits @ W` -> tích luỹ `dwte` tại chỗ — loại bỏ merge serial 1.33s (probe AV).
- `attn_bwd_epilogue`: softmax + gDs + transpose n² thành épilogue của GEMM attention,
  đọc `gg`/`xf` 1 lần, không merge.
- **Dấu `…` trong spec** = shape/layout cụ thể cần team Inference duyệt trước khi code
  native (chữ ký trên là đề xuất; mọi shape truyền tường minh, native không đoán).

### M7 — shape-class dispatch (nội sinh trong native, gộp vào M4/M6)

- Trong `tkv_nthreads`/padded run: phân lớp theo (m,n,k): nhỏ `<96` -> 1 luồng ·
  square lớn -> pattern hiện tại · k=50257 (lm-head/embed) -> chia theo cột mạnh ·
  rectangular grad -> MC/NC riêng.
- Env `TKV_GEMM_DISPATCH=shape|legacy` để A/B kiểu cũ. Không đổi numerics (gate chứng minh).
- Lợi nhuận T-grid tính lại do team Inference đo sau khi BUILD/ACC ra native (§M7)
  → ghi vào bảng bàn giao.

## 3. Phase thực hiện

### Phase 0 — Commit tài liệu plan + baseline
1. Commit tài liệu này.
2. Chạy & ghi số mốc: `tools\vong.exe` (IL_IDENTICAL) · `tools\testkit_gate.ps1`
   (125/125, NEG 31/31) · `tests_suite\chay.exe` · rebuild DLL không đổi + `test_sgemm.exe`.

### Phase 1 — M4 `simd_gemm_packed`
1. **Native** (`tkv_simd_native.c`): struct handle + `SgemmPackedCreate/SgemmPacked/
   SgemmPackedFree`; **thêm SRWLOCK** quanh submit+wait của `tkv_run_mt`
   (serialize entry — sửa luôn lỗ hang >90s của `simd_gemm` cũ).
2. **Compiler** (`simd_feature.tkv`): pinvoke + wrapper IL theo pattern
   `_pt_gemm_pinvoke`/`_pt_gemm_list`, `register_expr_builtin` 3 tên;
   **thêm 3 tên vào `_BUILTIN_LENH_DOC_LAP`** (`file_io.tkv:75`).
3. **Test**: `tests/simd_gemm_packed_test.tkv` — packed vs `simd_gemm` (BIT=0 hoặc ≤1e-4)
   · hình chữ nhật · `trans=1` · pad khi rows/cols không bội T · T-khớp-handle sai → lỗi rõ
   · **2 thread gọi song song phải thoát, không hang**. Negative: `tests/negative/` gọi
   sai dtype (f64) → bị từ chối đúng lý do.
4. **Docs**: REFERENCE.md §2.13 (3 dòng) → chạy `gen_builtin_ref.tkv --check`.
5. **Gate**: `vong` → IL_IDENTICAL · `testkit_gate` PASS · `chay.exe` không regress ·
   rebuild DLL (build.ps1) copy `runtime/` + `benchmark/`. **Commit milestone M4.**

### Phase 2 — M5 native buffer + fused AdamW
1. **Native**: `AdamwStepF32`, `F32Zero`, `F32CopyTo/From`, `F32Addcmul` —
   intrinsics tường minh, 1 chia/phần tử.
2. **Compiler**: 6 builtin ở `nativebuf.tkv` + whitelist `_BUILTIN_LENH_DOC_LAP`.
3. **Test**: `tests/adamw_step_test.tkv` (so công thức scalar trong test, TOL 1e-5;
   case wd-only, betas=0, g=0) · `tests/f32buf_copy_zero_test.tkv` (roundtrip, zero thật).
4. **Confirm công thức/thứ tự với nguồn GĐ10 Inference** trước khi coi native là chốt.
5. Docs + gate như Phase 1. **Commit milestone M5.**

### Phase 3 — M6 fused lm-head/attention
1. **Native**: 2 entry point, pool bên trong + lock chung, softmax-grad fp32 giảm tử cố định.
2. **Compiler**: 2 builtin (cụm kernel) + whitelist + REFERENCE.
3. **Test**: `tests/lmhead_bwd_fused_test.tkv`, `tests/attn_bwd_epilogue_test.tkv` —
   so reference scalar `.tkv` cùng shape nhỏ, maxdiff ≤1e-4; **tách hàm**
   (bẫy main quá lớn → BadImageFormat, §3.4).
4. **Blocker**: chữ ký/shape cần team Inference duyệt trước khi code native.
5. Gate như trên. **Commit milestone M6.**

### Phase 4 — M7 shape dispatch
1. **Native**: phân lớp shape + env `TKV_GEMM_DISPATCH=shape|legacy`.
2. Microbench 4 shape P7b (số liệu thông tin; gate thật ≥250 GFLOP/s chạy Inference-side).
3. **Gate**: toàn bộ test cũ + mới không đổi kết quả. **Commit milestone M7.**

### Phase 5 — Bàn giao
Viết `Release/docs/e_handoff/2026-10-24-m4-m7-compiler-handoff.md`: bảng ABI + env +
ownership handle (free trả 0, không GC) + hợp đồng re-entrancy (native tự serialize) +
**bảng nghiệm thu phía Inference**: 135/135 · subset 84/84 · trainer 15/15 ·
loss 3 seq `13.442912` exact · A/B wrapper best-of-3 mẫu CU/CX (không tin SUM thủ công) ·
`ADAMW_STEP` ≤1.3s · full step 3 seq ~11-13s · P7b 4 shape GEMM ≥250 GFLOP/s ·
đo lại lợi nhuận T sau M4/M6. **Commit bàn giao.**

## 4. Rủi ro & ghi chú kỹ thuật

- **Giữ nguyên `/fp:fast`** của build.ps1 — đổi flags sẽ xê dịch baseline; kernel mới viết
  intrinsics tường minh + thứ tự source cố định, gate loss exact phía Inference quyết định.
- **Handle use-after-free**: `free` trả 0 như `free_bytes`, ghi rõ ownership trong
  REFERENCE + handoff (mẫu C, không GC).
- **`vong` lần đầu "IL KHAC NHAU" là bình thường** → chạy lại tới IL_IDENTICAL.
- **Bẫy §3.4 khi viết test**: tách hàm, gán i64 handle ở top-level hàm (GĐ8),
  không trộn list f32/f64 (B-01 đã chặn — vẫn viết negative test bảo vệ).
- `dist/il_features/*` có thể là bản Python-era stale — kiểm tra có còn được nạp
  trước khi phải port cùng.

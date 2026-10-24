# BÀN GIAO M4-M7 — compiler/native team → team Inference

Ngày: **2026-10-24** · Nguồn yêu cầu: `docs/spec-m4-m7-compiler-team.md` (repo Inference)
· Plan đã duyệt: `Release/docs/e_handoff/2026-10-24-spec-m4-m7-compiler-plan.md`

## 0. Trạng thái từng mục

| Mục | Trạng thái | Commit | Builtin/ABI mới | GATE compiler |
|---|---|---|---|---|
| **M4** packed GEMM | ✅ XONG | `71e0e5d` | `simd_gemm_packed_create` / `simd_gemm_packed` / `simd_gemm_packed_free` (handle i64, pack 1 lần/step, lỗi ném rõ) | gate xanh |
| **M5** fused AdamW + elementwise | ✅ XONG | `c158bae` | `f32_zero`, `f32_copy_to_buf`, `f32_copy_from_buf`, `f32_addcmul`, `adamw_step` (công thức GĐ10, verify 1e-6) | gate xanh · native 19/19 · pos 20/20 |
| **M6** `lmhead_bwd_fused` | ✅ XONG | `68880fa` | `lmhead_bwd_fused(logits, ids, wte, xf, dxf, dwte, B, S, E, V)` — softmax-grad (max-sub) → `dxf = dlogits @ wte` → tích lũy `dwte` tại chỗ; **ids = i32** (đã chốt) | gate 128/128 + neg 34/34 · pos 4/4 |
| **M6** `attn_bwd_epilogue` | ⏳ TREO | — | **chờ team Inference gửi công thức** — spec chỉ ghi "softmax + gDs + transpose n²", chưa xác định `xf` là buffer `(B,H,S,d_head)` hay `(B,H,S,S)`; đoán sai sẽ ghi OOB. Chữ ký đề xuất giữ nguyên: `(gg, xf, attn, dgg, B, H, S, d_head) -> i32` | — |
| **M7** shape dispatch | ✅ XONG | (commit M7) | không thêm builtin — phân lớp `(m,n,k)` nội sinh trong native: `<96`→1 luồng · vocab `50257`→chia cột mạnh + NC 128 · rect (`max≥4×min`)→MC/NC riêng 128/128 · square→pattern hiện tại. Env **`TKV_GEMM_DISPATCH=shape` (mặc định) \| `legacy`** để A/B | gate 129/129 + neg 34/34 |

**Đã chốt trong lúc thực hiện (đề nghị ghi vào HANDOFF §0.x của Inference):**

1. **Công thức `adamw_step` (M5) là final** — đúng dạng spec truyền,
   `bc1s` truyền vào nhưng không dùng trong p-update (đã confirm với chủ sở hữu spec).
2. **`ids` của `lmhead_bwd_fused` là `i32`** — native đọc 4 byte/ptu.
3. **Numerics M4-M7 = bit-giong legacy**: A/B stdout `shape` vs `legacy` = 0 tuyệt đối.

## 1. Numerics & gate (bằng chứng — đã chạy trong repo compiler)

| Cổng | Kết quả |
|---|---|
| `testkit_gate.ps1` | **129/129 positive + 34/34 negative**, exit 0 (baseline 127+33 → +M6 pos +M7 pos) |
| `chay.exe` (tests_suite) | **DAT=51, TRUOT=734** = exact baseline |
| `gen_builtin_ref --check` | 83 tên thiếu tài liệu = baseline cũ (tên M4-M7 **không** nằm trong danh sách thiếu) |
| `tools/vong.exe` (tự-host) | IL_IDENTICAL sau mỗi lần sửa compiler (M4/M5/M6) |
| A/B `TKV_GEMM_DISPATCH` | stdout shape vs legacy **identical** cho: gemm_dispatch + simd_gemm_packed + adamw_step + lmhead_bwd_fused |
| Native M5 (`test_adamw.c`) | 19/19 · positive M5 20/20 · positive M6 4/4 (dxf wp 5.4e-8, dwte ww 4.3e-8, TOL 1e-5) |

## 2. Cổng KPI team Inference cần đo (thuộc máy Inference — spec §4)

Compiler team **không đo được** các mục này (cần `gpt2_ref`/`trainer` + torch):

1. **A/B wrapper thật best-of-3** cùng phiên (mẫu CU/CX): `TKV_GEMM_DISPATCH=shape|legacy`,
   M4 packed vs wrapper BUILD cũ. **Không tin số SUM thủ công** (CX: SUM 1.18-1.33× → wrapper thật 1.01-1.12×).
2. **Full step seq 8/256/1024** không regress (baseline **12.516 / 17.313 / 36.703 s**) +
   **loss khớp exact 7 chữ số** (`13.442912` seq 3).
   Kỳ vọng: M4+M5 → step ~**11-13 s ≈ 1.8×**; M6+M7 → dải **1.1-1.3×**.
3. **Gate Inference 135/135 + trainer 15/15** (subset M3c 84/84).
4. **4 shape P7b**: pha GEMM ≥ 250 GFLOP/s (tham chiếu 552-588 đã đo), FULL-vs-torch theo ms/shape.
5. **T-grid M7**: đo lại `rows×cols`, MC/NC per-class. Giá trị hiện tại là **khởi tạo**:
   VOCAB cols = ước số lớn nhất của nt (≤16, strip ≥8), NC=128; RECT MC=NC=128;
   **KC=64 giữ nguyên** — đổi KC là đổi numerics (grouping của tích lũy k), nếu Inference muốn
   thử KC khác phải chạy lại toàn bộ loss-exact gate. Env `TKV_GEMM_MIN_N`/`TKV_GEMM_THREADS`/
   `TKV_GEMM_COLS` vẫn có hiệu lực để đo.

## 3. Cách nối vào repo Inference

- Copy `Release/runtime/tkv_simd_native.dll` (**bản M7**) vào nơi Inference load DLL — bắt buộc bản mới:
  M5/M6 thêm export (`f32_*`, `adamw_step`, `lmhead_bwd_fused`); M7 giữ nguyên export, đổi dispatch.
- Builtin đã đăng ký REFERENCE.md đầy đủ (M4 `simd_gemm_packed_*`, M5 `f32_*`/`adamw_step`, M6 `lmhead_bwd_fused`).
- Wrapper: M4 → `simd_gemm_packed_create` 1 lần/step thay BUILD lại mỗi call; M5 → `f32_zero` (zero_grad) +
  `adamw_step` fused (bỏ merge serial); M6 → 1 gọi `lmhead_bwd_fused` thay backward tuần tự + merge.
- **M6 attn**: sau khi nhận công thức → implement native, gate lại, commit; dự kiến vòng gate như các mục trên.

## 4. Quy trình đã dùng (cho lần sau)

Sửa compiler: `tools/vong.exe` (đến IL_IDENTICAL) → `tools/testkit_gate.ps1` → `gen_builtin_ref --check`
→ `tests_suite/chay.exe` → commit từng mục. Sửa native: `tools/simd_native/build.ps1` → copy DLL vào
`$env:TEMP\opencode\testkit_gate\` (**gate không tự copy khi DLL đã có** — quên là chạy test cũ với DLL cũ).

# PHẢN HỒI COMPILER TEAM #2 — `simd_gemm_full` (ƯU TIÊN A) ĐÃ GIAO

Ngày: 2026-10-26
Đối tượng: team Inference (người gửi `docs/COMPILER_TEAM_REQUEST2.md`)
Trạng thái: **Ưu tiên A LÀM ĐỦ** (không cần rơi xuống B — 3 bulk builtin không làm)
Gate: vong `IL_IDENTICAL` · testkit xem §4 · `dang_ky` PASS · `lint` PASS

---

## 1. Đã giao: một ABI gọi trọn matmul

```
i32 simd_gemm_full(a, b, c, m, n, k, ndim, trans_b, T, mode)    # 10 tham số
```

| Tham số | Ý nghĩa (đúng §3.1 của đơn) |
|---|---|
| `a`, `b`, `c` | `list[f32]` (`Tensor.data`) — layout **giống wrapper hiện tại**: `a [m][k]`; `b [k][ndim]` nếu `trans_b=0` (`ndim = n`), `b [n][ndim]` nếu `trans_b=1` (`ndim = k`); `c [m][n]` |
| `m, n, k, ndim` | shape như `_smm_core`; `ndim` = stride row của `b` (mọi nhánh đọc `b[p*ndim + j]` — y hệt `_tile_b_w`) |
| `T` | tile size (truyền `256` như hiện tại; native nhận `4..4096`) |
| `mode` | `0` = ghi đè `c = A×B`, `1` = tích lũy `c += A×B` (thay vòng `_acc_f` p-loop) |

**Native chịu trách nhiệm trọn gói** (`SgemmFull` trong `tkv_simd_native.dll`):
build tile A/B (copy + zero-pad `T²`, kể cả nhánh `trans_b`) → GEMM từng tile
qua đúng pool hiện có → acc `c += Ct` — **toàn bộ không quay lại `.tkv`**.
`.tkv` còn đúng **MỘT dòng gọi** cho một block matmul, không còn `while` nào
quanh GEMM.

Sai số → **ném `ArgumentException` rõ ràng** (không im lang), mã native:

| rc | Ý nghĩa |
|---|---|
| `-1` | `a/b/c` NULL |
| `-2` | shape ≤ 0 |
| `-3` / `-4` | `trans_b` / `mode` không phải 0\\|1 |
| `-5` | list quá ngắn (`len(a)<m*k`, `len(b)<k*ndim` (tb=0) hoặc `n*ndim` (tb=1), `len(c)<m*n`) |
| `-6` | hết RAM tạm (tile buffer `3×T²`) |
| `-7` | `T` ngoài `[4, 4096]` |
| `-8` | `ndim` không khớp layout (`tb=0: ndim<n`, `tb=1: ndim<k`) |

Ràng buộc biên dịch: `a/b/c` **bắt buộc `list[f32]`** (reject `list[f64]`,
container, biểu thức ngay lúc dịch với lý do rõ); 10 tham số đúng số.

## 2. Numerics (§3.2 yêu cầu) — BIT = 0.0, không khai báo gì thêm

- Thứ tự vòng **`i0 → p0 → j0`** (y hệt P0.1 của `_smm_core`), tile A build
  1 lần/`(i0,p0)`, tile B build trong `j0` — giống nguyên wrapper.
- Tile build **đầy đủ `T²`** (copy + `0.0f` pad) đúng thứ tự ghi row-major
  của `_tile_a_w`/`_tile_b_w`.
- GEMM mỗi tile gọi **đúng `SgemmF32(At, Bt, Ct, T)`** mà `simd_gemm` wrapper
  gọi → `Ct` cùng bit (cùng pool, cùng dispatch M7).
- Acc `cd[bc] = cd[bc] + Ct[bt]` tăng dần `p0` đúng `_acc_f`.
- `mode=0`: memset region `+0.0f` **tại `p0==0`** trước khi cộng (bit —
  không dùng `= Ct` vì corner case `-0.0f`), tương đương `_smm_cd` zero-fill
  của wrapper; **không cần ALLOC list C trước** (đi luôn chi phí ALLOC bạn đo
  16–422 ms/call — native memset `m*n` ≈ vài ms).

**Đo thật** (`tests/simd_gemm_full_test.tkv`, 7/7 PASS): so `simd_gemm_full`
với bản sao `_smm_core` tiled viết trong test — mọi case `maxdiff = 0.0`:
mode 0 tb0 (20×20×20 T=8, có pre-fill `999` để chắc ghi đè), mode 0 tb1,
mode 1 tb0 (17×13×9 T=4), mode 1 tb1 rect (12×33×17 T=16), rect 40×12×9
(T > min(m,n)), edge 1×1×7. Benchmark 4 shape (§3) cũng `maxdiff = 0.0`.

## 3. Đo A/B (repo này, best-of-3, T=256, cùng phiên)

Wrapper reference = `_smm_core` tiled (i0→p0→j0, tile build interpreted,
`simd_gemm` mỗi tile) vs `simd_gemm_full`, 4 shape bảng CG:

| Shape | wrapper (ms) | **full (ms)** | speedup | maxdiff |
|---|---|---|---|---|
| S1 `1024×768×3072` | 125 | **31** | **4.03×** | 0.0 |
| S3 `1024×768×50257` | 1937 | **563** | **3.44×** | 0.0 |
| S4 `50257×768×1024` | 2046 | **531** | **3.85×** | 0.0 |
| S5 `1024×50257×768` | 1984 | **546** | **3.63×** | 0.0 |

- So với ngưỡng §5 (**< 1.3× = BUST**): mọi shape **3.4–4.0×** — vượt.
- So nhanh absolute với wrapper bảng CG của bạn (S3 969 / S4 1828 / S5 1563 /
  S1 109 ms): full 563 / 531 / 546 / 31 → 1.7× / 3.4× / 2.9× / 3.5× —
  **mọi shape nhanh hơn wrapper cũ, kể cả S1 đạt 31 ms ≤ 40 ms**.
- **Trung thực hai điểm** để bạn không đọc số nhầm:
  1. Wrapper reference trong bench của tôi là `_smm_core` cổ điển, KHÔNG phải
     probe CG của bạn (bạn dùng `t_zeros` indexed + T-dispatch/P0.4) — nên
     số wrapper absolute hai bên không so trực tiếp được. Benchmark bạn cần
     chạy lại với `tv/tests/simd_probe_cg.tkv` + gọi `simd_gemm_full` để chốt
     KPI §5.
  2. `full` absolute 531–563 ms cho S3/S4/S5 vượt ngưỡng ≤350–400 ms trong
     bảng §5. Thành phần còn lại sau GEMM (~140–200 ms ước lượng) là
     build-tile + acc + lock pool theo call. Nếu bạn đo lại với probe thật
     và chưa đạt, phản hồi lại — hướng tối ưu tiếp (B-tile cache theo
     `i0`, gộp lock, `trans_a`) nằm bên phía tôi.

## 4. Gate (log: `out/gate_simd_gemm_full.log`)

- `vong.exe`: **IL_IDENTICAL** (self-host, 133 file) — `dist/tkvc-tv.exe` mới
  đã có builtin.
- `testkit_gate.ps1`: **131/131 + NEG 38/38** (baseline 130/130 + 36/36;
  thêm `simd_gemm_full_test` + 2 negative `simd_gemm_full_arity`,
  `simd_gemm_full_f64`).
  - **Sửa gate**: testkit chạy exe ở `%TEMP%` → pinvoke
    `tkv_simd_native.dll` không tìm thấy cạnh exe (`DllNotFoundException`,
    exit-code lộn xộn). Test `simd_gemm_full_test` là test **chạy native đầu
    tiên** trong gate → `testkit_gate.ps1` giờ copy
    `runtime/tkv_simd_native.dll` sang `$OutDir` (2 dòng, có comment).
- `dang_ky_gate`: PASS (0 vi phạm) · `lint_rules_gate`: PASS (8/8)
- `assert_il` trên `tests/simd_gemm_full_test.tkv`: `TkvSimd::GemmFullM` ×6,
  `as "SgemmFull"` ×1, `float32& pinned` ×29, forbid `ToArray` ×0 → PASS.
- `perf_gate`: PASS — e2e −3.9%, f32buf −3.9%, f32mm −3.0%, mm +3.4% (ok).
- `tests_suite\chay.exe`: **51 DAT / 734 TRUOT = baseline đỏ sẵn ở HEAD**
  (đã A/B compiler HEAD vs mới lần trước: log 0 diff) — không regress.
- `gen_builtin_ref`: đã regenerate block (441 tên / 114 file) + thêm dòng
  doc `` `simd_gemm_full` `` vào REFERENCE.md §bảng builtin. `--check` còn
  83 tên chưa doc **là baseline pre-existing** (bản HEAD thiếu 84 — verify
  trực tiếp bằng `git show HEAD:`; riêng `simd_gemm_full` đã doc → cải thiện
  đúng 1).
- Test C native (`SgemmFull`): 26/26 PASS (5 shape × 2 mode × 2 trans so
  naive + 6 case rc) — scratch, không commit.

## 5. Cách wire ở repo bạn (đề xuất, bạn quyết)

Thay thân `_smm_core` (sau khi đã chốt shape) bằng **1 lời gọi**:

```
rv = simd_gemm_full(a.data, b.data, cd, m, n, k, ndim, trans_b, T, 0)   # C = A×B
rv = simd_gemm_full(a.data, b.data, cd, m, n, k, ndim, trans_b, T, 1)   # cd += A×B (trong p-loop
                                                                         # nếu bạn giữ lặp micro-batch)
```

- `cd` vẫn qua `_smm_cd`/`_smm_pk_c` (mượn `sc`) như cũ — nhưng **không cần
  zero-fill khi `mode=0`** (native tự memset region).
- Env `TKV_GEMM_MIN_N` / `TKV_GEMM_THREADS` / `TKV_GEMM_COLS` /
  `TKV_GEMM_DISPATCH` giữ nguyên tác dụng (tile GEMM vẫn qua
  `SgemmF32`/pool cũ). **Không đổi export nào** — `simd_gemm`,
  `simd_gemm_packed_*`, `f32_*`, `adamw_step`, `lmhead_bwd_fused` nguyên vẹn
  (các probe cũ còn chạy).
- Re-entrancy §3.1: buffer tile là **local theo call** (không global), GEMM
  tile vẫn qua `g_gemm_lock` của pool → 2 thread cùng gọi **không treo**
  (khác bài học `g_job` global). Test 2-thread trên wrapper mới nếu bạn muốn
  tự tay xác nhận thêm.
- Overload `list[f64]` (tiện ích tùy chọn trong đơn) **chưa làm** — Tensor
  production đã `List[Single]` nên không chặn; nếu bạn vẫn cần, phản hồi
  thêm 1 dòng tôi làm nốt theo mẫu M4 (`SgemmPackedCreate64`).

## 6. Bạn cần làm gì tiếp

1. Pull `dist/tkvc-tv.exe` + `runtime/tkv_simd_native.dll` (bắt buộc cả 2 —
   builtin sinh pinvoke xuống DLL mới).
2. Wire vào `_smm_core`, chạy `simd_probe_cg` A/B 4 shape theo §5 của bạn
   (kỳ vọng absolute ≤350/400/400/40 — nếu chưa đạt báo lại tôi tối ưu tiếp).
3. Chạy `parity_tests` / `trainer_tests` 15/15 + loss 3 seq exact — numerics
   tôi cam kết BIT=0.0 với wrapper, nhưng gate của bạn mới là chốt.

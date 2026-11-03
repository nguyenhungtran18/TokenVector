# TRẢ LỜI COMPILER TEAM #10 — Ask B `linear_dx_fused` + Ask C.2 cache scratch 12 head

**Ngày:** 2026-11-02 · **Tiếp:** `docs/COMPILER_TEAM_REQUEST10.md` (Ask A + C.1 đã làm 01/11)
**Kết quả:** seq8 **−25.8%** trong phiên (3687 → 2735 ms), **loss EXACT 3/3**,
gate **135/135**, trainer **15/15**, self-host **`IL_IDENTICAL`**.

---

## 1. Ask B — builtin `linear_dx_fused`

### 1.1 Vì sao tách riêng (đúng đề nghị ở §6 của request)

Hợp đồng `smm_dot` khác `dw`: `dx = smm_dot(gy, w, m, n, k)` là **`trans_b=1`**
(`w` lưu `[n hang][k giam]`), còn `linear_dw_fused` là **`trans_a=1`** (`x` lưu
`[k hang][in_d cot]`). Không nhét chung.

```text
linear_dx_fused(gy, w, dx, m, n, k) -> i32
  dx[m][n] = sum_{p<k} gy[m][p] * w[n][p]
```

`gy`/`w`/`dx` là `list[f32]` (`Tensor.data`), pin tại chỗ, không copy.
`dx` là Tensor **mới** (`gpt2_linear_bwd` trả `r[0]`, không ghi vào `gflat`)
→ **không cần `goff`**, ghi từ chỉ số 0.

### 1.2 Native — cùng translation unit, không nhân bản code

`LinearDxFused` đặt trong **`tkv_simd_native.c`** (cùng TU với các helper `static`),
gọi thẳng:

| thành phần | dùng lại | tại sao |
|---|---|---|
| `full_tile_a` / `full_tile_b` | ✅ | tile `T×T` giống hệt `SgemmFull` |
| `tkv_k_eff(Bt, At, T)` | ✅ | cùng `k_eff` → cùng nhánh dispatch |
| `gemm_rect_f32` / `gemm_rows_f32` | ✅ | **`i1 = m`** thay vì `i1 = T` |
| `SgemmF32` | ✅ | khi `m = T` (không bỏ được hàng) → gọi thẳng reference, có thread |

**Bit-exact mang tính cấu trúc:** `SgemmFull` tính đủ 256 hàng nhưng `_acc_f` chỉ đọc
hàng `< m`. Mỗi output chỉ phụ thuộc hàng `At` của chính nó → bỏ hàng `≥ m` không đổi
hàng được đọc. Threading (`tkv_run_mt*`) chỉ chia `[i0,i1)×[j0,j1)` — không chia `k` —
nên chuỗi FMA theo `pc` (KC=64) của từng phần tử giống hệt đơn luồng.

> **Điểm mấu chốt của yêu cầu trước:** đặt cùng TU thay vì file riêng là để **không có
> hai nguồn sự thật**. Nếu tách `tkv_linear_dx.c`, lần sau ai sửa `micro_f32` trong
> `tkv_simd_native.c` thì bản copy sẽ **im lặng lệch bit** mà không test nào bắt được.

### 1.3 Builtin wiring (đúng mẫu `linear_dw_fused`)

| file | thêm |
|---|---|
| `compiler/il_features/simd_feature.tkv` | `LinearDxFusedNative` (pinvoke) · `_pt_linear_dx_wrapper()` · `compile_linear_dx_fused` · `register_expr_builtin` |
| `compiler/il_features/file_io.tkv` | `'linear_dx_fused'` vào `_BUILTIN_LENH_DOC_LAP` |

### 1.4 Hợp đồng từ chối — caller **bắt buộc** fallback

| rc | điều kiện | lý do |
|---|---|---|
| `-9` | `k < 256` | không đi qua `_smm_full` |
| `-10` | `m > 256` | đi `_smm_pk` (thứ tự cộng khác) |
| `-11` | `m % 4 != 0` | `micro_f32` i-tail scalar → khác FMA |
| **`-12`** | **`k % 256 != 0`** | **xem §1.5** |

### 1.5 Bẫy bit-exact tìm ra bằng ĐO (không phải suy luận)

Probe `_am6` bắt `k=300` (`m=200, n=96`) **lech 1264 ptu**. Hai yếu tố bị confound —
tách ra bằng 3 arm:

| arm | kết quả |
|---|---|
| `k300-onlyA` — m=8, n=96, k=300 (p-tile le, 1 block mc) | **0** |
| `m200-onlyB` — m=200, n=768, k=768 (nhieu block mc, p day) | **0** |
| `k300-both` — m=200, n=96, k=300 | **1264** |

⇒ **p-tile le (`pw < T` → `k_eff < T` → `gemm_rect_f32`) KẾT HỢP với nhiều block `ic`
(`m > GEMM_MC`) mới lệch.** Thêm guard `-12` khi `k % 256 != 0` — khi đó p-tile cuối
luôn đầy (`pw = T`) ⇒ luôn đi `gemm_rows_f32`, không bao giờ vào nhánh lệch.

**Sản phẩm không bị ảnh hưởng:** `out_d` thật luôn ∈ {768, 2304, 3072} = bội của 256.

> **Nguyên tắc:** không chứng minh được bit-exact ⇒ **không nhận shape đó**. Đúng hợp
> đồng của request (loss EXACT không bao giờ phụ thuộc native).

### 1.6 Số đo kernel (`test_dx.c`, best-of-5, native vs `SgemmFull`)

| shape | ref | native | x |
|---|---|---|---|
| m=8, n=768, k=3072 | 13.60 ms | 8.64 ms | **1.58×** |
| m=8, n=3072, k=768 | 9.34 ms | 5.67 ms | **1.65×** |
| m=8, n=768, k=2304 | 7.63 ms | 4.68 ms | **1.63×** |
| m=8, n=768, k=768 | 2.56 ms | 1.57 ms | **1.63×** |
| m=256 | 15.35 ms | 15.70 ms | 0.98× (gọi thẳng `SgemmF32`) |

---

## 2. Ask C.2 — cache 5 scratch của 12 head (repo-side, thuần `.tkv`)

`gpt2_attention_bwd`, nhánh `n < 128` (chính là seq8): mỗi head cấp
`gQ`/`gK`/`gV`/`gDc` (n×hd) + `gDs` (n×n) = **5 `t_zeros` × 12 head = 60 cấp phát/lần gọi**.

**Hoist ra trước vòng `for head`** — an toàn vì mỗi head **ghi đầy đủ trước khi đọc**:

- `gQ/gK/gV/gDc`: vòng `t2 × d` ghi hết `n*hd`;
- `gDs`: mỗi hàng `t2` ghi `u = 0..t2`, rồi `0.0` cho `t2+1..n-1` → đủ `n*n`.

→ **không đổi 1 phép tính nào ⇒ bit-exact.** Áp cho **cả 5 mirror**.

**Phạm vi:** chỉ nhánh `n < 128`. Nhánh worker (`n ≥ 128`) mỗi worker nhận **đúng 1
head** (`hlo..hhi` = 1 head) nên hoisting ở đó là no-op — không làm.

---

## 3. Số đo — cùng phiên 2026-11-02, best-of-3 xen kẽ, .NET 10.0.13

### A/B 1 — `bseq_h4c` (trước B/C.2) vs `bseq_dx` (có B)

| seq | h4c | dx | Δ |
|---|---|---|---|
| 8 | 3687 | **2734** | **−25.9%** |
| 256 | 5547 | 5359 | −3.4% |
| 1024 | 15688 | 15828 | +0.9% (nhiễu) |

### A/B 2 — `bseq_dx` vs `bseq_c2` (có B + C.2), seq8

`2953 → 2859` = **−3.2%**

### Số chốt (build đầy đủ A+B+C.2, best-of-3)

| seq | full-step | torch 14T (cùng phiên) | tỉ lệ |
|---|---|---|---|
| 8 | **2735** | 1079.6 | **2.53×** |
| 256 | **5531** | 1598.8 | 3.46× |
| 1024 | **16500** | 4105.2 | 4.02× |

Torch tier E cùng phiên, `T=1 / T=14`: 1371.7/1079.6 · 4364.8/1598.8 · 15180.8/4105.2 ms.

### seq256/1024 đứng yên — đúng như thiết kế, không phải lỗi

- **seq1024:** `m=1024 > 256` → native từ chối (`-10`) → fallback `smm_dot` → **không đổi**;
  `n=1024 ≥ 128` → đi worker → C.2 không áp dụng.
- **seq256:** `m=256 = T` → không bỏ được hàng nào → gọi thẳng `SgemmF32` (parity x0.98).
- **seq8:** `m=8` → bỏ 248/256 hàng → **đây là nơi có gain**.

---

## 4. Loss EXACT

Mọi lần chạy (cả A/B lẫn số chốt) in đúng 3 chuỗi chuẩn, không đổi 1 chữ số:

```
seq=8     loss=10.572291 -> 7.0119185
seq=256   loss=10.756927 -> 11.807267
seq=1024  loss=10.760399 -> 13.442915
```

---

## 5. Kiểm chứng

| kiểm | kết quả |
|---|---|
| `tools/gate_f32.sh` | **135/135, `TOTAL fails=0`, exit 0** — 2 lần (sau Ask B, sau C.2) |
| Trainer | **15/15 `fails=0`** — 2 lần |
| Self-host `tools/vong.exe` | **`IL_IDENTICAL`** — 2 lần |
| Probe `_am6.tkv` (mới) | **`TOTAL bit_bad=0`**; 4 nhánh từ chối `-9/-10/-11/-12` đúng rc |
| `test_dx.c` (mới) | **`ALL BIT-EXACT`** — 10 shape + 4 reject |

### File đã sửa

| file | nội dung |
|---|---|
| `tools/simd_native/tkv_simd_native.c` | +`LinearDxFused` (cùng TU, gọi static helper) + guard `-12` |
| `tools/simd_native/test_dx.c` | (mới) so bit + 4 reject + timing |
| `compiler_bootstrap/compiler/il_features/simd_feature.tkv` | pinvoke + wrapper IL + codegen + register |
| `compiler_bootstrap/compiler/il_features/file_io.tkv` | `'linear_dx_fused'` vào tập builtin |
| `tv/tests/_am6.tkv` | (mới) probe bit-check vs `smm_dot` |
| `tv/{training,tests}/gpt2_ref*.tkv` ×5 | wire `linear_dx_fused` + fallback · hoist 5 scratch/12 head |

---

## 6. Vấn đề đã ghi nhận (không thuộc thay đổi này)

Self-host thỉnh thoảng **NRE/AV ngắt quãng** khi biên dịch gop 133 file
(`Unhandled Exception ... at TKVApp._fp_walk → fpw_try → _fp_walk`, đôi khi
`0xC0000005`), tỉ lệ ~1/3 lần chạy, **cùng binary + cùng nguồn**. Đã chụp stack bằng
cách tạm thời `raise` lại exception trong `dich_mot` (đã hoàn nguyên). Chưa khoanh được
thủ phạm — tái hiện được cả trước lẫn sau thay đổi này ⇒ **không phải regression của #10**,
nhưng cần điều tra riêng (nghiện thứ tự duyệt container có hash ngẫu nhiên per-process).

# TRẢ LỜI COMPILER TEAM #12 — 4 native kernel BWD non-GEMM (Ask A) + đo Ask C

**Ngày:** 2026-11-06 · **Tiếp:** `D:\TokenVector.Inference\docs\COMPILER_TEAM_REQUEST12.md`
**Kết quả:** Ask A **xong, bit-exact 21/21**. Nhưng tiêu chí `backward ≤ 9000 ms`
**KHÔNG đạt** — best-of-9 **9187 ms** (−13.3% so 10593), median 9782 (−7.7%).
`opt.step` best **860 ms**, median 937 (tiêu chí ≤900 chỉ đạt ở best); **#12 không sửa
đường optimizer** — xem §6.

---

## 1. Ask A — 4 kernel, hợp đồng và cách giữ bit

Đặt trong **`tools/simd_native/tkv_bwd_ops.c`**, TU riêng, `/fp:precise`
(`/fp:fast` cho phép MSVC biến `a + b*c` thành FMA → lệch bit; `/fp:contract-`
không tồn tại trên MSVC này, warning D9002).

| builtin | prototype (list[f32] = `Tensor.data`) | thay cho |
|---|---|---|
| `layernorm_bwd_fused` | `(x, gy, g, n, h, gflat, o_dg, o_db) -> rc` | `gpt2_layernorm_bwd` |
| `gelu_erf_bwd` | `(x, gy, out, lo, hi) -> rc` | `op_gelu_erf_bwd`, segment `_ogb_one` |
| `softmax_causal_bwd` | `(dp, P, dctx, ctx, n, hd) -> rc` (in-place `dp`) | vòng softmax trong `attention_bwd` |
| `bias_grad` | `(gy, gflat, off, n, cols) -> rc` | vòng bias trong `gpt2_linear_bwd` |

Điểm giữ bit (đối chiếu IL `out/bseq_p10.il`, ground truth `_nt.tkv` NT1/NT3):

- Mọi phép hỗn loại `f32 ⊕ f64` được JIT **widen f64**, chỉ thu hẹp tại ranh giới typed
  (call/return/store). Kernel tính `double` rồi `(float)` đúng chỗ đó.
- `layernorm_bwd`: `mu`, `v`, `s1`, `s2` cộng **tuần tự** f64; `rstd = 1/sqrt(v+1e-6)`;
  `gg = gy*g` là **f32 mul** (round f32) rồi mới widen; `dx` f64 → f32;
  `dg += gy*xh` là f64-cộng-rồi-f32; `db += gy` là **f32 + f32**. `dg/db` ghi thẳng
  `gflat[o_dg+j]` / `gflat[o_db+j]` — **không** `t_zeros([h])` mỗi block.
- `gelu_erf_bwd`: `erf(v/√2)` với đối số **ép f32 trước khi gọi** (JIT truncate, `_nt5`
  xác nhận 401/401); Horner f64; `exp((-ax)*ax)` với `ax*ax` tính **trên f32**;
  `out[i-lo] = (float)((double)gy[i] * dgelu)`. `exp` MSVC khớp .NET **3001/3001**
  (`_nt4`, dải −100…+20, input trùng bit).
- `bias_grad`: AVX2 8 lane **theo cột**, vòng `i` tuần tự — mỗi output giữ nguyên chuỗi
  cộng của nó, không split reduction.
- `softmax_causal_bwd`: `dotv` = product f32 → cộng dồn f64 tuần tự `hd`; `u ≤ t`:
  `p * (dp - dotv)` f64 → f32; `u > t` = 0.

**Không có nhánh "gần đúng":** `rc < 0` ⇒ caller chạy vòng `.tkv` nguyên văn.
`rc` dùng: `-1` con trỏ null, `-2` tham số âm/0, `-5` list quá ngắn so với `n*h` / `cols`
/ `hi` / `n*n`.

## 2. Wiring

| file | thêm |
|---|---|
| `compiler_bootstrap/compiler/il_features/simd_feature.tkv` | 4 pinvoke `…Native`, wrapper `…M` (pin `_items`, `ldelema`, `conv.i`, check độ dài, `o_dg/o_db` int64, `rc<0`), `compile_layernorm_bwd_fused` / `compile_bias_grad` / `compile_softmax_causal_bwd` / `compile_gelu_erf_bwd`, `register_expr_builtin` |
| `compiler_bootstrap/compiler/il_features/file_io.tkv` | 4 tên vào `_BUILTIN_LENH_DOC_LAP` |
| `tools/simd_native/build.ps1` | thêm TU thứ 3 (`tkv_bwd_ops.c`) + copy DLL sang runtime |
| `runtime/tkv_simd_native.dll` | **263680** bytes (từ 256000) |

Production `.tkv` (7 file: `tv/training/gpt2_ref*.tkv` ×3 + mirror `tests/` ×3, `ops.tkv` ×2):
LN 1 chỗ (trước alloc `dg/db`), bias 4 chỗ (simd + scalar của `gpt2_linear_bwd`), softmax
2 chỗ (worker `_attn_hb_one` + nhánh `n<128`), gelu 2 chỗ (tuần tự + `_ogb_one`).
Compile với builtin yêu cầu **argument là biến** (`x.data` → `xl = x.data` trước khi gọi).

## 3. Kiểm chứng

| hạng mục | kết quả |
|---|---|
| `tv/tests/_am7.tkv` (mới) | **`AM7 TOTAL bit_bad=0`** — 21/21 ca, `rc=0`; LN/bias/softmax/gelu, gồm lẻ `n=3 h=5`, `n=1 h=1`, `cols=5` tail, offset lẻ `c767 off17`, segment 3.1M `[1M,2M)` |
| `LN n=1024 h=768` timing | interp **15.0 ms** → native **0.0 ms** (<1 quantum) |
| self-host `tools/vong.exe` | **`IL_IDENTICAL`** (`gop 133 file`) |
| `tools/gate_f32.sh` | **9/10 suite PASS** (102 case nhỏ + `gpt2_full` 33); `GATE_EXIT=1` |
| `gap_tests` | FAIL `exit=82` `InvalidProgramException` trong `ConstantFoldingPass.run` — **cùng lỗi §0.72 đã chứng minh pre-existing** (stash 3 tệp simd, build lại từ HEAD vẫn fail). Phiên này không chứng minh lại |
| `trainer_tests` | **15/15 PASS** |
| `loss` 3 seq (mode 0) | **`10.572291` / `10.756927` / `10.760399` — EXACT** |

## 4. Đo lại (seq1024, 14 luồng, `out/bseq_p12_n10.dll` mode 2, 9 run)

| | fwd | bwd | opt | copyback | TỔNG |
|---|---:|---:|---:|---:|---:|
| best | 2969 | **9187** | **860** | 109 | **13468** |
| median | 3328 | **9782** | **937** | ~125 | **14281** |
| §0.72 baseline | 3250 | 10593 | 1188 | 141 | 15266 |

best-vs-best: bwd **−13.3%**, tổng **−11.8%**; median: **−7.7%** / **−6.5%**.
Máy dao động **±7%** (§0.72) — không đọc một lần đo đơn lẻ.

Mode 1: **14266 / 14219 / 14078 ms**, `loss=10.760399 → 13.442915` **EXACT**.
Không regress seq8 (best 2782 vs 2875) / seq256 (best 4875 vs 5297).

Torch cùng phiên (3 lần, xen kẽ): bwd **2359.4 / 2350.8 / 2326.8**, opt **677.6 / 698.7 /
683.4**, tổng **4174.9 / 4206.1 / 4175.3** ⇒ TKV best bwd **3.91×** (trước 4.51×),
tổng **3.23×** (trước 3.7×).

## 5. Vì sao ≤9000 không đạt

4 op này chỉ nằm trong **~0.9–1.2 s** của 11 s chênh lệch (LN ~0.6 s, gelu ~0.3 s,
softmax ~0.2 s, bias <0.05 s) — khớp số đo. Phần còn lại của backward là
`attention_bwd` non-GEMM **~3.5 s không scale** (72 GEMM siêu nhỏ + vòng mask/score/proj
còn interpreted) và lm-head + `op_embed_bwd` ~2.5 s (§0.67); cộng thêm GEMM chỉ scale
3.1× thay vì 4.5×. Đó là nội dung cho **#13**, không phải 4 op của Ask A.

## 6. Ask C — `adamw_step_glm` A/B

`tv/tests/_gl1c.tkv`, n = 124 439 808, idle, best-of-5:

| đường | ms |
|---|---:|
| A `r1 = f32_copy_to_buf(gl, pgl)` + `adamw_step` (production) | **406** |
| B `adamw_step_glm(p, m, v, gl, …)` | **312** |
| B − A | **−94** |
| chỉ `r1` | 78 |

**Chưa wire:**
1. Khi `coef != 1.0` (clip hoạt động) production cần `pgl` làm input `f32_addcmul`
   ⇒ `r1` bắt buộc; glm chỉ bỏ được `r1` ở nhánh `coef == 1.0` ⇒ lợi thực ≲ 78–180 ms,
   **không phải 400 ms** như kỳ vọng §4 của request.
2. Probe so bit `_gl1.tkv` **chết `MissingMethodException: TkvSimd.AdamwGlmM`** — IL có
   `call` nhưng **thiếu `.method`**. `_gl1c.tkv` (không có hàm local) emit đủ ⇒ nghi thứ tự
   `_can_simd(ctx,'m5')` / `_ensure_class_simd` khi module có hàm local. **Lỗi codegen này
   cần khoanh trước khi wire** (xem §8).
3. Bit-exact đúng theo cấu trúc: `AdamwGlmM` pin `_items` rồi gọi **cùng** `AdamwNative`
   (`AdamwStepF32`) với cùng tham số như `AdamwM`; `r1` chỉ là copy f32→f32.

## 7. File đã sửa

| file | nội dung |
|---|---|
| `tools/simd_native/tkv_bwd_ops.c` | (mới) 4 kernel, `/fp:precise` |
| `tools/simd_native/build.ps1` | +TU thứ 3, copy DLL |
| `compiler_bootstrap/compiler/il_features/simd_feature.tkv` | +325 dòng: 4 pinvoke + wrapper + codegen + register |
| `compiler_bootstrap/compiler/il_features/file_io.tkv` | +4 tên builtin |
| `runtime/tkv_simd_native.dll` | build lại (263680 B) |
| `D:\TokenVector.Inference\tv\training\{gpt2_ref,tv.training.gpt2_ref,tv.training.gpt2_ref124}.tkv` + 3 mirror `tests/` | wire LN / bias / softmax |
| `…\tv\training\ops.tkv` + 3 mirror | wire gelu (tuần tự + `_ogb_one`) |
| `…\tv\tests\_am7.tkv` | (mới) probe bit-check 4 op |

**Chưa commit** ở cả 2 repo (dirty sẵn từ #10/#11 — không revert).

## 8. Vấn đề ghi nhận (không thuộc #12)

- **Emit thiếu method `AdamwGlmM`**: module `.tkv` có hàm local gọi cả `adamw_step` và
  `adamw_step_glm` → IL sinh `call` nhưng class `TkvSimd` không có method. `_gl1c.tkv`
  (cùng cặp lệnh, không hàm local) emit đủ. Cần một test tối thiểu để khoanh
  `_can_simd`/`_ensure_class_simd`.
- `gap_tests` `exit=82` (`InvalidProgramException` ở `ConstantFoldingPass.run`) — pre-existing,
  xem §3.

# TRẢ LỜI COMPILER #13 — native `softmax_causal_fwd` cho `attention_bwd`

**Ngày:** 2026-11-06 · **Tiếp:** yêu cầu "đo tách từng vòng non-GEMM trong `attention_bwd`
rồi viết kernel native cho phần lớn nhất, giữ bit-exact" (nối tiếp #12)
**Kết quả:** kernel **bit-exact 7/7** (`_am8`, gồm n=1024), nhanh **~3–4×** khi đo riêng,
nhưng **bwd end-to-end KHÔNG đổi** — vòng này không nằm trên critical path. fwd **−3.4%**.

---

## 1. Đo tách (probe `_at1.tkv`, seq1024, 1 luồng)

`gpt2_attention_bwd` = **344 ms/block**; 12 head chạy song song.

| vòng (12 head, tuần tự) | ms |
|---|---:|
| pack Q/K/V/dctx | <16 |
| **scale + max** | 62 |
| **exp + tổng** | **141** |
| normalize | 15 |
| zero-fill u>t | 31 |
| writeback dq (strided) | 47 |
| merge packed | <16 |
| **Σ non-GEMM** | **296** |
| 6 GEMM/head × 12 (đo lô 8) | 397 |

⇒ mỗi worker: GEMM **33.1 ms**, non-GEMM **24.7 ms** ⇒ GEMM 57%.
Vòng lớn nhất là **softmax-causal forward** = scale+max (62) + exp+tổng (141) +
normalize (15) + zero (31) = **249 ms**, tức 84% non-GEMM. `pack`/`writeback`/`merge`
chỉ là shuffle bộ nhớ nên không đáng kernel.

## 2. Kernel

```text
softmax_causal_fwd(s, n, inv) -> i32     # s = Smat.data (n x n), in-place
  scale+max  -> exp+tổng -> normalize -> zero-fill u>t
```

Bit-exact vì giữ đúng IL của đường `.tkv`:
- `mxv` là **f64 trước khi làm tròn f32** (`m0 = Smat[b0]*inv` chưa store đã gán `mxv`);
- `exp` đọc lại giá trị **f32** đã store, `totv` cộng dồn **f64 chưa làm tròn**;
- `s = s * ivv` là f32 × f64 → f64 → f32;
- `exp` MSVC = .NET `Math.Exp` (đã kiểm 3001/3001 ở `_nt4`; đối số ở đây ≤ 0).

`rc < 0` → 4 vòng `.tkv` nguyên văn (fallback). Wire **4 điểm/file × 5 mirror**:
`_attn_f_one`, `gpt2_attention` (n<128), `_attn_hb_one`, `gpt2_attention_bwd` (n<128).

## 3. Kiểm chứng

| hạng mục | kết quả |
|---|---|
| `tv/tests/_am8.tkv` (mới) | **`AM8 TOTAL bit_bad=0`**: n=1, 2, 5(lẻ hd=5), 8, 127, 128, **1024** |
| `_am8` timing n=1024 | interp **47 ms** → native **< 15.6 ms** (1 quantum) |
| self-host `tools/vong.exe` | **`IL_IDENTICAL`** |
| `tools/gate_f32.sh` | **9/10 suite PASS** (`gap_tests` exit=127, pre-existing) |
| `trainer_tests` | **15/15** |
| `loss` 3 seq | **`10.572291` / `10.756927` / `10.760399` — EXACT** |

## 4. Đo end-to-end — A/B xen kẽ cùng phiên (`bseq_p12` vs `bseq_p13`)

| | p12 (không kernel) | p13 (có kernel) | Δ best |
|---|---|---|---|
| fwd (3 cặp) | 3656 / 3657 / 3782 | **3578 / 3531 / 3562** | **−3.4%** |
| bwd (3 cặp) | 10062 / 9890 / 10109 | 9735 / 9906 / 10157 | −1.6% (không ổn định) |
| tổng | 13718 / 13547 / 13891 | 13313 / 13437 / 13719 | −1.7% |

mode 2 (9 run): p13 bwd best **9672**, median **9766**; p12 best 9187, median 9782
⇒ **không khác biệt trong nhiễu ±7%**.

Không regress seq8 (TỔNG 2766/2797/3000 vs 2782/2782/2812) và seq256
(4953/4984/5015 vs 4875/5030/5078).

## 5. Vì sao bwd không đổi — và việc kế tiếp

12 worker chạy song song trên 14 luồng; mỗi worker bị chi phối bởi 6 GEMM (33 ms) và tranh
chấp luồng. Bỏ 24.7 ms vòng softmax khỏi **một pha** không rút ngắn critical path. Điều này
khớp §0.69/§0.70 của HANDOFF: phần còn lại của `attention_bwd` là **overhead mỗi lời gọi
GEMM phía native** (72 GEMM nhỏ/block), không phải vòng interpreted.

⇒ Giữ kernel (bit-exact, giảm CPU thật, fwd −3.4%), nhưng **#14 nên nhắm vào overhead gọi
GEMM** (gộp 6 GEMM/head thành 1 lời gọi, hoặc batch theo head) thay vì thêm kernel
elementwise.

## 6. File đã sửa

| file | nội dung |
|---|---|
| `tools/simd_native/tkv_bwd_ops.c` | +`SoftmaxCausalFwd` (`/fp:precise`) |
| `compiler_bootstrap/compiler/il_features/simd_feature.tkv` | +pinvoke, wrapper `SoftmaxCausalFwdM`, `compile_softmax_causal_fwd`, register |
| `compiler_bootstrap/compiler/il_features/file_io.tkv` | +`'softmax_causal_fwd'` |
| `runtime/tkv_simd_native.dll` | build lại (265728 B) |
| `…\tv\training\{gpt2_ref,tv.training.gpt2_ref,tv.training.gpt2_ref124}.tkv` + 2 mirror `tests/` | wire 4 điểm/file + fallback |
| `…\tv\tests\_at1.tkv`, `_am8.tkv` | (mới) probe đo tách + bit-check |

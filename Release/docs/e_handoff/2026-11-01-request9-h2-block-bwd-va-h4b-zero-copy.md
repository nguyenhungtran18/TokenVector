# TRẢ LỜI COMPILER TEAM #9 — H2 `block_bwd` (TkvInt → 0) + H4b zero-copy managed data

**Ngày:** 2026-11-01 · **Đáp:** `docs/COMPILER_TEAM_REQUEST9.md`
**Compiler:** `Release/dist/tkvc-tv.exe` self-host 2026-11-01 (sau `tools/vong.exe` → `IL_IDENTICAL`)
**Native:** `Release/runtime/tkv_simd_native.dll` (không đổi trong lần này — entry `lmhead_bwd_fused` tái dùng)

---

## 0. Tóm tắt kết quả

| Hạng mục | Yêu cầu | Kết quả |
|---|---|---|
| **A.1** dọn `TkvInt::` trong `gpt2_block_bwd` | 48 → trong thân vòng = 0 | **48 → 0 trên toàn method** (thân vòng vốn đã 0) ✅ |
| **A.2** hoist vòng `mu` sang byref `_items` | làm | **ĐO TRƯỚC → KHÔNG LÀM** (xem §2.2: sàn `vaddsd`, byref = 0 gain) ⚠️ |
| **A.3** LICM `m1/m2/rstd` + bỏ double-load `gy` | làm | `gy` **đã bỏ double-load** (local lane `gyv`), bit-exact ✅ · LICM broadcast: **đo lại thấy JIT đã ở sàn**, không sửa ⚠️ |
| **B** zero-copy managed data cho fused | fused đọc/ghi thẳng `.data` | **CÓ** — builtin `lmhead_bwd_fused_list` + wrapper pin `_items`; bỏ **3 copy_to + 2 copy_from** ✅ |
| Bucket `12 × block_bwd` | 1617 → ~45 ms/gọi (−67%) | **130.875 ms/gọi = 1570.5 ms** — KHÔNG đổi; bucket không nằm ở ceremony (§2.3) |
| Full-step 3 seq (best-of-3 xen kẽ) | không regress | **−3.6% / −5.1% / −3.8%** so binary trước #9, loss EXACT 9/9 |
| Gate / trainer | 135/135 + 15/15 | ✅ 135/135 fail=0 · ✅ trainer 15/15 |
| Self-host | `IL_IDENTICAL` | ✅ (g1 == g2) |
| Probe `_p6ms` | ≥4×, bit_bad=0 | **A 4.12–4.44× · B 5.98–6.09× · C 5.06–5.47×**, `fails=0` |

---

## 1. Ask A — H2: `TkvInt::` trong `gpt2_block_bwd`

### 1.1 Nơi phát sinh 48 lệnh (đếm trên IL thật, không đoán)

Bắn tỉa `gpt2_block_bwd` trong `out/am.il` (bản trước #9, 1084 dòng):

| vùng | `TkvInt::` | nguồn |
|---|---|---|
| `o_l1g … o_b2 = -1` (12 biến) | **24** (`FromI64` + `Neg` × 12) | literal `-1` là số vô hạn (`TkvInt`) rồi gán vào local suy `int` |
| `o_* = offs[k]` trong `if len(offs) >= 12` | **12** (`FromI64`) | `offs[k]` là `i64` native → nâng lên `TkvInt` để gán |
| biên vòng `range(n * h)` × 4 vòng | **12** (`ToI64`) | `n`, `h` suy `TkvInt` → nhân → hạ về int64 cho `range` |
| **thân 4 vòng vector** (`F5/F7/F8/F9_vstart..vdone`) | **0** | đã sạch từ #8 |
| **tổng method** | **48** | |

⇒ 48 lệnh **không nằm trong vòng nào**: chúng chạy một lần mỗi call (preheader) và 12
lệnh `ToI64` nằm ở preheader của 4 vòng. Sửa bằng **annotation tường minh** ở phía
nguồn (`o_*: "i64"`, `n: "i64"`, `h: "i64"`) — compiler đã có đường narrow cho local
`i64` tường minh, không cần đổi codegen.

### 1.2 Kết quả IL sau khi sửa (compiler 2026-11-01)

```
gpt2_block_bwd: 1046 dòng · TkvInt:: = 0 · _vstart = 8 · stobj Vector4 = 8
gpt2_layernorm_bwd: 2742 dòng · TkvInt:: = 0 · _vstart = 8 · stobj Vector4 = 40
gpt2_linear_bwd:  1193 dòng · TkvInt:: = 0
```

`__p6a*/__p6b*` (byref `float32&`) vẫn được hoist như cũ; `get_Count` = 0, `toArray` = 0
trong thân vòng.

### 1.3 `gy` double-load (A.3 phần nửa)

`gpt2_layernorm_bwd` đổi `gg = gy.data[base+j] * g.data[j]` + 3 chỗ đọc lại
`gy.data[base+j]` → **một local lane** `gyv: "f32" = gy.data[base+j]` dùng cho cả
`gg`, `gflat[o_dg+j]`, và `dg/db`. 4 vòng vector vẫn nổ (`F6/F7/F9/F10`), **bit-exact**
(loss chain 3 seq EXACT, xem §3).

### 1.4 Vì sao KHÔNG làm A.2 (hoist `mu`) và LICM broadcast

Đây là chỗ **báo cáo ngược lại yêu cầu**, kèm số đo — theo luật «đo trước, sửa sau»:

- **Vòng `mu`** (`mu = mu + x.data[base+j]`): §0.56.4 đã đếm Tier-1 = 12 lệnh/phần tử,
  trong đó ~6 lệnh là bounds-check của `List.get_Item`. Nhưng **thời gian không nằm ở
  bounds-check**: chuỗi `vaddsd` phụ thuộc tuần tự (dependency chain) đã chặn ở
  **3.35 cycle/phần tử**, đúng sàn của phép cộng nối tiếp. Đổi `get_Item` → byref
  `_items` chỉ bỏ được 6 lệnh **không nằm trên critical path** ⇒ **0 gain đo được**.
  Muốn nhanh hơn phải **re-associate** (nhiều accumulator) = **đổi thứ tự cộng** = phá
  hợp đồng loss EXACT. ⇒ Không làm; nếu cần vì lý do IL-sạch thì làm được, nhưng xin
  xác nhận trước vì nó **thêm bề mặt rủi ro** cho 0%.
- **LICM `m1/m2/rstd`**: `vbroadcastsd` hằng loop-invariant còn **1 lệnh/vòng**, JIT
  không LICM nó; nhưng A (LN_BWD) hiện đã **4.12–4.44×** (ngưỡng ≥4×) nên không còn
  ngân sách để đánh đổi. Sửa preheader thêm local `Vector<float>` sẽ chỉ đổi 1 lệnh
  của vòng 38 lệnh — dưới nhiễu.

### 1.5 Bucket `12 × block_bwd` — con số thật và thành phần

`tv/tests/simd_probe_am.tkv` (batch 8), compiler 2026-11-01:

```
AM ATTENTION_BWD  = 47.0 ms
AM MLP_BWD        = 78.0 ms
AM SUM_cac_vung   = 125.0 ms
AM BLOCK_BWD      = 130.875 ms/call
AM BUCKET 12 x block_bwd = 1570.5 ms  (baseline 2244, nguong <=1680)
```

⇒ **95% bucket là công việc thật của `gpt2_attention_bwd` + `gpt2_mlp_bwd`** (đã vector
hoá), phần "ceremony" của chính `block_bwd` chỉ còn **~6 ms/call**. Ước lượng "26 ms
ceremony → 45 ms/gọi" trong request **không còn đúng** sau P9/#8: 48 lệnh `TkvInt::`
đúng là còn, nhưng chúng **không nằm trong vòng**. Muốn cắt bucket phải cắt trong 2
hàm con (GEMM/tile/alloc bên trong attention & mlp), không phải dọn ceremony — đề xuất
tách thành request #10 nếu cần.

---

## 2. Ask B — H4b: zero-copy managed tensor data cho fused

### 2.1 Hợp đồng mới

```tkv
lmhead_bwd_fused_list(logits, ids, wte, xf, dxf, dwte, B, S, E, V, scale) -> i32
```
- `logits/wte/xf/dxf/dwte`: **`list[f32]`** (chính `Tensor.data`) — đọc/ghi trực tiếp,
  không `alloc_bytes`, không `f32_copy_to_buf`, không `f32_copy_from_buf`.
- `ids`: vẫn là buffer native i64 (`alloc_bytes` + `write_i32`) — buffer nhỏ (`n*4` B).
- Trả `0` nếu `B*S*E*V <= 0`; ném `ArgumentException` nếu list ngắn hơn shape.
- Số học **giữ nguyên 100%** với `lmhead_bwd_fused` (cùng entry native
  `lmhead_bwd_fused`, cùng tham số, cùng thứ tự) ⇒ bit-exact.

### 2.2 Cơ chế zero-copy (IL sinh ra, không phải ghi chú)

Builtin sinh call tới **wrapper IL** `TkvSimd::LmheadBwdListM` (mới, trong
`_pt_m6_list_wrapper()`):

1. `_items` của từng `List<float32>` lấy bằng reflection **một lần** (`GetField("_items", 36)`);
2. `ldlen` → kiểm `logits >= B*S*V`, `wte >= V*E`, `xf/dxf >= B*S*E`, `dwte >= V*E`
   **trước** khi lấy con trỏ;
3. `ldelema float32` → local **`float32& pinned`** cho cả 5 mảng (GC không di chuyển
   trong suốt lời gọi — cùng khuôn `F32ListAddM`/`GemmFullM` đã dùng);
4. `conv.i` + gọi `LmheadBwdNative(native int × 6, int32 × 4, float32)`.

⚠️ **Bug đã bắt được ở bản trước khi giao:** bản đầu của `compile_lmhead_bwd_fused_list`
đẩy thẳng **object ref `List<float32>`** vào tham số `int64` của `LmheadBwdM` — IL sai
kiểu, native đọc header của `List` (con trỏ `_items`, `_size`, `_version`) như thể là
float ⇒ rác/crash. Bản giao lần này đi qua wrapper pin ở trên; IL đã kiểm:
`call int32 TkvSimd::LmheadBwdListM(class List\`1<float32>, int64, … ×5 …, int32 ×4, float32)`.

### 2.3 IL trước/sau (`gpt2_backward`)

| | trước #9 (`out/am.il`) | sau #9 (`out/r9_am.il`) |
|---|---|---|
| `F32CopyTo` | **3** (3 × 154 MB) | **0** |
| `F32CopyFrom` | **2** (2 × 154 MB) | **0** |
| `LmheadBwdListM` | 0 | **1** |
| dòng IL của method | 3341 | 3253 (−88) |

⇒ Bỏ **770 MB copy/step**.

### 2.4 Số đo full-step (best-of-3, xen kẽ từng lượt, cùng phiên, `.NET 10.0.13`)

`out/r9_ab3.sh` — `out/bseq_p9_n10.dll` (trước #9) ↔ `out/r9_bseq_n10.dll` (sau #9):

| seq | p9: 3 lần (ms) | best | #9: 3 lần (ms) | best | Δ |
|---|---|---|---|---|---|
| 8 | 3937 / 3891 / 3875 | **3875** | 3735 / 3750 / 3797 | **3735** | **−3.6%** |
| 256 | 5890 / 5859 / 5828 | **5828** | 5812 / 5531 / 5625 | **5531** | **−5.1%** |
| 1024 | 16860 / 16515 / 16640 | **16515** | 15891 / 16500 / 16484 | **15891** | **−3.8%** |

**Loss EXACT cả 9/9 lượt:** `10.572291 → 7.0119185` · `10.756927 → 11.807267` ·
`10.760399 → 13.442915` (từng chữ số).

### 2.5 torch cùng phiên (tier E, `T=14`, `out/r9_torch_e.log`)

| seq | torch 14T TOTAL | tkv #9 | **tỉ lệ** | torch 1T TOTAL | tỉ lệ vs 1T |
|---|---|---|---|---|---|
| 8 | **1061.6 ms** | 3735 | **3.52×** | 1366.1 | 2.73× |
| 256 | **1571.7 ms** | 5531 | **3.52×** | 4350.3 | 1.27× |
| 1024 | **4201.4 ms** | 15891 | **3.78×** | 15038.0 | 1.06× |

(torch bwd 1T: 377.8 / 2320.4 / 9384.6 ms; torch bwd 14T: 288.1 / 591.5 / 2387.6 ms.)

---

## 3. Kiểm chứng (chạy lại toàn bộ sau thay đổi)

| kiểm | kết quả | log |
|---|---|---|
| Self-host `tools/vong.exe` | **IL_IDENTICAL** (g1 == g2) | — |
| `bash tools/gate_f32.sh` | **135/135, TOTAL fails=0, exit 0** | `out/r9_gate.log` |
| `tv/tests/trainer_tests.tkv` | **15/15 fails=0** (resume bit-exact) | — |
| Probe `_p6ms` (2 rep) | **A 4.44/4.12× · B 5.98/6.09× · C 5.47/5.06×**, `bit_bad=0`, `fails=0` | — |
| Bucket `12 × block_bwd` | **1570.5 ms** (`BLOCK_BWD` 130.875 ms/call) | `out/r9_am_run.log` |
| Loss chain 3 seq | **EXACT** (9/9 lượt) | `out/r9_ab3.log` |

---

## 4. File đã đổi

| file | đổi |
|---|---|
| `Release/compiler_bootstrap/compiler/il_features/simd_feature.tkv` | `+108` dòng: `compile_lmhead_bwd_fused_list`, `_pt_m6_list_wrapper` (pin `_items`), đăng ký builtin |
| `Release/compiler_bootstrap/compiler/il_features/file_io.tkv` | `_BUILTIN_LENH_DOC_LAP` thêm `lmhead_bwd_fused_list` |
| `Release/dist/tkvc-tv.exe` | self-host 2026-11-01 |
| *(phía Inference)* `tv/training/gpt2_ref.tkv` + 4 mirror | `o_*: "i64"`/`n`/`h` (A.1), `gyv` lane (A.3), call `lmhead_bwd_fused_list` (B) |

---

## 5. Cách lặp lại phép đo

```bash
cd D:/TokenVector/Release && ./tools/vong.exe          # IL_IDENTICAL
cd D:/TokenVector.Inference
/D/TokenVector/Release/dist/tkvc-tv.exe tv/tests/simd_bench_124m_seq.tkv out/r9_bseq.exe main
cp out/r9_bseq.exe out/r9_bseq_n10.dll
cp out/_am.runtimeconfig.json out/r9_bseq_n10.runtimeconfig.json
bash out/r9_ab3.sh                                     # A/B xen kẽ 3 seq
for S in 8 256 1024; do python tools/bench_torch.py e $S; done   # torch cùng phiên
```

## 6. Còn lại / đề xuất

1. **Bucket 130.875 ms/call** = `ATTENTION_BWD` 47 + `MLP_BWD` 78 + glue 6. Muốn −67%
   phải cắt **trong 2 hàm con** (GEMM tile/alloc/elementwise của chúng) — nên là
   request riêng, kèm phân rã theo pha như `_am3` đã làm.
2. **A.2 `mu` byref** và **LICM broadcast**: đã đo là không có gain (sàn `vaddsd` /
   1 lệnh/vòng). Nếu muốn làm vì mục tiêu "IL sạch" chứ không vì tốc độ, xin xác nhận.
3. `lmhead_bwd_fused` (bản handle `alloc_bytes`) **giữ nguyên** để không phá call site
   cũ/probe `_bd2`.

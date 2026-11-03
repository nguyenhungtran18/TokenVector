# TRẢ LỜI COMPILER TEAM #10 — Ask A: `linear_dw_fused` true-k, ghi thẳng `gflat`

**Ngày:** 2026-11-01 · **Đáp:** `TokenVector.Inference/docs/COMPILER_TEAM_REQUEST10.md`
**Compiler:** `Release/dist/tkvc-tv.exe` self-host 2026-11-01 (`tools/vong.exe` → `IL_IDENTICAL`)
**Native:** `Release/runtime/tkv_simd_native.dll` — **thêm TU mới** `tkv_linear_dw.c` (`/fp:precise`),
biên dịch tách khỏi `tkv_simd_native.c` (`/fp:fast`). Copy sang
`Inference/out/`, `out/_gate_p12/`, `out/m1/`.

---

## 0. Tóm tắt kết quả

| Hạng mục | Yêu cầu (#10) | Kết quả |
|---|---|---|
| **Ask A** `linear_dw_fused` (true-k, ghi thẳng `gflat`) | làm | ✅ builtin mới `linear_dw_fused` + native `LinearDwFused` |
| Bit-exact | loss EXACT | ✅ `_am5`: `bit_bad=0` trên 4 shape thật; `_p6ms` `bit_bad=0` |
| `BLOCK_BWD` (production, có `gflat`) | ≤ 80 ms/gọi | **80.0 ms** ✅ (từ 130.875) |
| Bucket `12 × block_bwd` | ≤ 960 ms | **960.0 ms** ✅ (từ 1570.5, −39%) |
| Full-step 3 seq (best-of-3 xen kẽ) | không regress | **seq8 −17.9%** · seq256 −0.3% · seq1024 +1.0% (nhiễu) |
| Loss chain 3 seq | **EXACT** | ✅ 9/9 `10.572291→7.0119185` · `10.756927→11.807267` · `10.760399→13.442915` |
| Gate / trainer | 135/135 + 15/15 | ✅ 135/135 `fails=0` · ✅ trainer 15/15 |
| Self-host | `IL_IDENTICAL` | ✅ |
| Probe `_p6ms` | ≥4×, `bit_bad=0` | ✅ **A 4.49× · B 5.51× · C 5.14×**, `fails=0` |

**Ask B/C KHÔNG LÀM** — xem §5 (Ask B `linear_bwd_fused` toàn bộ; Ask C `dw_proj` + head-block).

---

## 1. Ask A — builtin `linear_dw_fused`

### 1.1 Hợp đồng (đúng như #10 đề xuất)

```tkv
linear_dw_fused(x, gy, gdw, gdw_off, n, in_d, out_d) -> i32
```
- `x`, `gy`, `gdw` là `list[f32]` (`Tensor.data`) — pin `_items` tại chỗ, **không copy**;
- ghi `gdw[gdw_off + i*out_d + c] += Σ_p x[p*in_d + i] · gy[p*out_d + c]`;
- `rc = 0` OK; **âm = native từ chối** → caller `.tkv` **phải fallback** đường cũ
  (`-1` NULL, `-2` shape ≤0, `-5` list quá ngắn, `-6` `gdw_off <0`,
  `-7` `out_d % 16 != 0` hoặc `in_d % 4 != 0`, **`-8` `n > 64`**).

### 1.2 Vì sao nhanh

`dw` là GEMM contraction **`k = n = 8`**, nhưng đường `.tkv` `smm_fwd_at` vẫn build tile
`T×T = 64×64` bằng **code interpreted** cho từng ô. `dw2` = 576 ô, mỗi ô 4096 ghi At +
4096 ghi Bt (zero-pad) + 4096 ACC = **7.1M phep ghi interpreted**, rồi mới `simd_gemm`.
O `LinearDwFused` **tile biến mất** — vòng p thật (`n=8`) nằm trong C, kernel 4 hàng × 8 cột
(mỗi hàng `gy` đọc **1 lần cho 4 hàng**, không phải 1 lần/1 hàng).

Đo trong C (`tools/simd_native/test_dw.exe`, best-of-5, tham chiếu = `SgemmFull` cùng `SgemmF32`):

| shape | tham chiếu (tile) | `LinearDwFused` | x |
|---|---|---|---|
| k=8, 3072→768 (`dw2`) | 6.0 ms | **1.0 ms** | 6.0× |
| k=8, 768→2304 (`dwqkv`) | 4.4 ms | **0.85 ms** | 5.3× |
| k=8, 768→3072 (`dw1`) | 6.2 ms | **1.5 ms** | 4.2× |
| k=8, 2304→768 | 4.5 ms | **1.0 ms** | 4.5× |

### 1.3 Bit-exact — bằng chứng và **hai cạm bẫy đã gặp**

Chuỗi số học của wrapper `.tkv` (`_p58_core_simple` + `_acc_f`) là:

```
dw = 0 + Ct(p0=0) + Ct(p0=T) + ...        # cộng dồn vào Tensor dw BẮT ĐẦU TỪ 0
gflat[goff+k] = gflat[goff+k] + dw[k]     # MỘT phep cong vao gflat
```

với mỗi `Ct` đi qua **`SgemmF32` → `micro_f32` (4×16)**: kernel **không gộp cột** — mỗi *lane*
là **một cột `c`**, vòng `p` **tăng dần FMA** vào lane đó (`c0a = fmadd(va0, vb0, c0a)`), và
`tkv_k_eff` rút `k` của tile xuống đúng `n` khi `n < 64`. ⇒ mỗi phần tử là **chuỗi FMA tuần tự
theo `p` bắt đầu từ 0**, tái hiện đúng bằng 8 lane AVX (8 cột) + vòng `p` tuần tự.

**Cạm bẫy 1 — `/fp:fast` tái liên kết (tìm 01/11, mất 3 lần thử).**
`build.ps1` biên dịch cả DLL với `/fp:fast`: MSVC **tái liên kết** `acc = acc + blk` **và gộp
cả `load(gdw)` vào cây FMA**, khiến kết quả **phụ thuộc giá trị đích**: cùng input, lần gọi 1
(dest = 0) ra `3c1d4954`, lần gọi 2 (dest ≠ 0) cộng thêm `3c1d4958`. Đã thử `#pragma
float_control(precise, on)` — **bị bỏ qua trong chế độ `/fp:fast`**. Giải pháp: tách
`tkv_linear_dw.c` thành **TU riêng biên dịch `/fp:precise`** (không reassociate, không contract;
`FMA` vẫn gọi tường minh qua intrinsics). Các kernel cũ giữ nguyên `/fp:fast` (chúng dùng
intrinsics, không đổi bit).

**Cạm bẫy 2 — cộng p-tile thẳng vào `gdw`.**
Bản đầu ghi `gdw += acc` **sau mỗi p-tile** (vòng `p0` nằm ngoài). Với `n > 64` (nhiều p-tile)
điều này **khác** chuỗi `.tkv` (`.tkv` cộng p-tile vào `dw` trước, rồi cộng `dw` **một lần** vào
`gflat`). Sửa: gộp p-tile vào **một** giá trị trong thanh ghi rồi `gdw += v` đúng **một lần**.
Hệ quả tất yếu: **`n > 64` bị từ chối (`rc = -8`)** — không gộp được thành một phep cong mà vẫn
giữ bit. Mọi shape thật trong GPT-2 đều `k = n = 8` nên điều này không cản trở.

**Chứng minh:** probe `tv/tests/_am5.tkv` — so sánh `smm_fwd_at` + copy vs `linear_dw_fused`
trên 4 shape thật + 2 shape `n>64` + 1 shape lẻ, `gflat` **đã được điền giá trị ≠ 0** (mô phỏng
gradient đang chạy):

```
AM5 dw2-mlp   k=8 in_d=3072 out_d=768  rc=0 bit_bad=0
AM5 dw1-linear k=8 in_d=768  out_d=3072 rc=0 bit_bad=0
AM5 dwqkv-attn k=8 in_d=768  out_d=2304 rc=0 bit_bad=0
AM5 dx2-like  k=8 in_d=2304 out_d=768  rc=0 bit_bad=0
AM5 k128      k=128             rc=-8 -> NATIVE TỪ CHỐI (fallback)
AM5 k200      k=200             rc=-8 -> NATIVE TỪ CHỐI (fallback)
AM5 le-out_d40 k=8 in_d=100 out_d=40 rc=-7 -> NATIVE TỪ CHỐI (fallback)
AM5 TOTAL bit_bad=0 (0 = BIT-EXACT)
```

### 1.4 Bằng chứng IL (compiler)

Wrapper `TkvSimd::LinearDwFusedM(List<f32> x, List<f32> gy, List<f32> gdw, int32 goff,
int32 n, int32 in_d, int32 out_d)`: lấy `_items` qua `FieldInfo` (lưu ý: **`ldc.i4 36`** =
`BindingFlags.Instance | NonPublic | Public`), **kiểm độ dài TRƯỚC khi pin**
(`x ≥ n·in_d`, `gy ≥ n·out_d`, `gdw ≥ goff + in_d·out_d`), rồi `ldelema float32` + `float32&
pinned`. Không đi qua method khác (lỗi JIT đã gặp ở `GemmHL`).

> **Lưu ý IL:** tên tham số **`off` là reserved token của ilasm** → phải đặt tên `goff`.

Call site trong `gpt2_linear_bwd` và `gpt2_mlp_bwd` (`out/am_p10.il`):
`call int32 TkvSimd::LinearDwFusedM(...)` — 2 chỗ, đúng 2 method production.

---

## 2. Số đo

### 2.1 Bucket — nhưng **phải đo biến thể có `gflat`**

Cảnh báo quan trọng cho lần đo sau: probe `simd_probe_am` gọi
`gpt2_block_bwd(..., gy, 1)` **không truyền `gflat`** → `goff = -1` → `dw` phải **trả về Tensor**
→ `linear_dw_fused` **không chạy**. Số đo đó **không phản ánh production** (train luôn truyền
`gflat`). Probe đã được mở rộng thêm biến thể `BLOCK_BWD_FLAT` (truyền `gflat` + `offs`).

| biến thể | trước #10 | sau #10 |
|---|---|---|
| `BLOCK_BWD` **không** `gflat` (`goff=-1`) | 130.875 | 134.875 (không đổi — native không chạy) |
| **`BLOCK_BWD_FLAT` (production, `goff>=0`)** | 130.875 | **80.0 ms** |
| Bucket 12 × | 1570.5 ms | **960.0 ms** (**−39%**) |

Trong biến thể không-`gflat`: `ATTENTION_BWD` 31 ms, `MLP_BWD` 62–78 ms (giống cũ, vì đường
`dw = smm_fwd_at` giữ nguyên khi `goff < 0`).

### 2.2 Full-step 3 seq (best-of-3 xen kẽ từng lượt, cùng phiên, .NET 10.0.13)

`out/r10_ab3.sh`: `out/r9_bseq_n10.dll` (sau #9) ↔ `out/r10_bseq_n10.dll` (sau #10):

| seq | sau #9 | sau #10 | Δ | loss |
|---|---|---|---|---|
| 8 | 3656 | **3000** | **−17.9%** | EXACT |
| 256 | 5516 | **5500** | −0.3% | EXACT |
| 1024 | 15219 | **15375** | +1.0% (nhiễu) | EXACT |

Torch **fresh cùng phiên** (tier E, `T=14`, `out/r10_torch_e.log`):
**1000.1 / 1570.8 / 4130.7 ms** → tỉ lệ **3.00× / 3.50× / 3.72×**
(so #9: 3.52× / 3.52× / 3.78× — seq8 cải thiện rõ, hai seq kia giữ nguyên).

**Nhận xét:** gain gần như chỉ nằm ở **seq8** — nơi `dw` (contraction `k=8`, output 2.36M)
chiếm tỉ trọng lớn trong bước; ở seq1024, `dw` là `O(n·h·h)` còn **GEMM lớn** (`k ≥ 256`,
đã đi `packed` native) mới là chủ đạo, nên `linear_dw_fused` gần như vô hại (+1.0% trong nhiễu).

---

## 3. Kiểm chứng

| kiểm | kết quả |
|---|---|
| `tools/gate_f32.sh` | **135/135, `TOTAL fails=0`, exit 0** |
| Trainer | **15/15 `fails=0`** (resume bit-exact) |
| Probe `_p6ms` (2 rep) | **A 4.49× · B 5.51× · C 5.14×**, `bit_bad=0`, `fails=0` |
| Loss chain 9 lượt | **EXACT 9/9** |
| Self-host compiler | **IL_IDENTICAL** |
| Native C test (`test_dw.exe`) | 4 shape thật `bit_bad=0`, `bit_bad2=0`; `n>64`/shape lẻ `rc=-8/-7` |

---

## 4. Files đổi

**Compiler (`D:/TokenVector/Release`):**

| file | đổi |
|---|---|
| `compiler_bootstrap/compiler/il_features/simd_feature.tkv` | +`LinearDwFusedNative` (pinvoke) · +`_pt_linear_dw_wrapper()` · +`compile_linear_dw_fused` · +`register_expr_builtin` |
| `compiler_bootstrap/compiler/il_features/file_io.tkv` | +`'linear_dw_fused'` vào `_BUILTIN_LENH_DOC_LAP` |
| `tools/simd_native/tkv_linear_dw.c` | **MỚI** — `LinearDwFused` (`/fp:precise`, TU riêng) |
| `tools/simd_native/tkv_simd_native.c` | bỏ hàm khỏi TU này (dời sang `tkv_linear_dw.c`); +`tkv_rup64`/`tkv_tilek10` |
| `tools/simd_native/build.ps1` | 2 TU: `/fp:fast` + `/fp:precise`, rồi `link` |
| `tools/simd_native/test_dw.c`, `test_dbg.c`, `test_dbg2.c`, `build_test_dw.ps1`, `dump.ps1` | test/bit-check nội bộ |
| `dist/tkvc-tv.exe`, `runtime/tkvc-tv.exe`, `runtime/tkv_simd_native.dll` | self-host + rebuild |

**Repo (`D:/TokenVector.Inference`)** — `tv/training/gpt2_ref.tkv` +
`tv/training/tv.training.gpt2_ref124.tkv` + `tv/tests/tv.training.gpt2_ref124.tkv`
(3 file production; 2 bản `gpt2_ref` dotted là bản cũ **không** có `smm_fwd_at`, giữ nguyên):
`gpt2_linear_bwd` và `gpt2_mlp_bwd` (`dw2`) gọi `linear_dw_fused` **khi `goff/o_w2 ≥ 0`**,
`rc != 0` → fallback `smm_fwd_at` + copy **nguyên vẹn**. Probe mới `tv/tests/_am5.tkv`;
`simd_probe_am.tkv` + biến thể `BLOCK_BWD_FLAT`.

---

## 5. Ask B / Ask C — CHƯA LÀM (báo số, không đoán)

### 5.1 Ask B — `linear_bwd_fused` (dx + dw + db một lời gọi)

Chưa làm. Ưước lượng từ `_am4`: `dx = smm_dot(gy, w, n, in_d, out_d)` vẫn còn **12.69 ms (w1) /
5.81 ms (qkv)**, vòng `db` + copy `db → gflat` còn ~0. Fusing `dx` vào native sẽ đòi hỏi
kernel đúng hợp đồng `smm_dot` (B lưu `[in_d][out_d]`, `trans_b=1`) — **khác** hợp đồng `dw`.
Đề nghị: **tách** thành `linear_dx_fused` riêng, không nhét chung vào `linear_dw_fused`
(tránh phá vỡ hợp đồng đã bit-exact).

### 5.2 Ask C — `dw_proj` (5.75 ms) + 12 head block (4.39 ms)

- `dw_proj` đi `smm_fwd` (`trans_a = 0`) — **khác** đường `smm_fwd_at`; `LinearDwFused` hiện
  **không** cover `trans_a = 0`. Muốn cover thì thêm tham số `trans_a` (bit-exact được vì
  `full_tile_a`/`_tile_a_at_w` copy cùng giá trị, chỉ đổi thứ tự index) — nhưng phải đo lại.
- 12 head block: 5 `t_zeros`/head = 60 cấp phát/lần gọi là **repo-side** (cache scratch), không
  thuộc phạm vi compiler.

### 5.3 Gợi ý bước sau

1. **`trans_a = 0`** trong `LinearDwFused` (mở `dw_proj` + các GEMM `smm_fwd` contraction k nhỏ).
2. **`n > 64`** — chỉ cần cho phép khi chấp nhận **không** bit-exact (re-associate) hoặc khi
   `dw` được sinh vào scratch rồi cộng một lần (2 pass, vẫn nhanh hơn interpreted nhiều).
3. **`linear_dx_fused`** riêng cho `dx = smm_dot`.

---

## 6. Điều kiện đã tuân thủ

- **Loss EXACT** — không reorder reduction: kernel tái hiện **chuỗi p-tile** của wrapper
  (kể cả 0-tile đầu của `Ct`), có probe `bit_bad=0` trước khi wire.
- Gate 135/135 + trainer 15/15; self-host `IL_IDENTICAL`.
- Số đo **xen kẽ cùng phiên** trước khi ghi handoff.
- Không trộn H3 (threading 14 luồng) — mọi số ở trên **đơn luồng**.

---

## 7. ASK C.1 — `dw_proj`: bỏ `smm_transpose`, dùng `trans_a=1` (2026-11-01, cùng phiên)

**Phát hiện thay đổi hướng làm:** request #10 (Ask C.1) đề nghị **mở `trans_a=0`** trong
`LinearDwFused` để cover `dw_proj`. Đọc code thật thì **không cần**:

```tkv
ctxTt = smm_transpose(ctxT, n, h)     # ctxT la [n hang][h cot] -> ctxTt la [h][n]
dwG   = smm_fwd(ctxTt, gout, h, h, n) # trans_a = 0
```

`ctxT` **đã** lưu `[n hang][h cot]` — chính là layout `trans_a=1` mà builtin hiện có đọc thẳng
qua `_tile_a_at_w`. Vậy chỉ cần **bỏ phép transpose trung gian** và truyền `ctxT` thẳng vào
`linear_dw_fused` — **không đổi ABI, không thêm native, không đổi numerics**. Đây đúng là mẫu
P5.4 đã làm với `gpt2_linear_bwd` (bỏ `smm_transpose` + `smm_transpose` dwT, `maxdiff 0.0`).
Đo ngược lại: chỉ mở `trans_a=0` thì phải thêm tham số + nhánh kernel mới **và vẫn phải bỏ
transpose** để được lợi — làm hai lần không ích gì.

**Bit-exact — nhưng fallback KHÔNG được là `smm_fwd_at`.** Probe `_am5._check_proj` cho:

| n | `smm_fwd_at(ctxT)` vs `smm_fwd(transpose(ctxT))` | `linear_dw_fused` vs đường cũ |
|---|---|---|
| 8 | `bad=0` ✅ | `bad=0` ✅ |
| 256 | **`bad=274384`** ❌ | native `rc=-8` → fallback |
| 1024 | **`bad=0`?** → cũng lệch (xem dưới) | native `rc=-8` → fallback |

**Bẫy:** `_smm_core` (`smm_fwd`) với `k ≥ 256` đi **packed native** (`_smm_pk`), còn
`_p58_core` (`smm_fwd_at`) **luôn** đi tile → **hai thứ tự cộng khác nhau**. Vì vậy khi native
từ chối (`n > 64`), fallback **phải là đường cũ nguyên vẹn** (`smm_transpose` + `smm_fwd`),
**không được** thay bằng `smm_fwd_at` — làm vậy là mất loss EXACT ở seq256/1024.

Áp dụng vào 3 file production (`tv/tests/tv.training.gpt2_ref124.tkv`,
`tv/training/tv.training.gpt2_ref124.tkv`, `tv/training/gpt2_ref.tkv`):

```tkv
dwG = t_zeros([0])
l10p = -1
if o_proj >= 0:
    _ct10 = ctxT.data ; _go10 = gout.data ; _gf10 = gflat
    l10p = linear_dw_fused(_ct10, _go10, _gf10, o_proj, n, h, h)
if l10p != 0:
    ctxTt = smm_transpose(ctxT, n, h)      # fallback NGUYEN VEN
    dwG = smm_fwd(ctxTt, gout, h, h, n)
```
vòng copy `dwG → gflat` bọc trong `if l10p != 0:` (native đã ghi thẳng khi `rc = 0`).
`gpt2_attention_bwd` giờ có **4 call site** `LinearDwFusedM` (dwqkv, dw1, dw2, **dw_proj**).

### 7.1 Số đo sau Ask C.1 (cùng phiên, best-of-3 xen kẽ)

| mục | sau #10 Ask A | **sau Ask C.1** | Δ |
|---|---|---|---|
| `BLOCK_BWD_FLAT` (production) | 80.0 ms | **70.375 ms** | **−12.0%** |
| Bucket `12 × block_bwd` | 960.0 ms | **844.5 ms** | −12.0% |
| full-step seq8 | 3000 ms | **2922** | **−2.6%** |
| full-step seq256 | 5531 | 5594 | +1.1% (nhiễu) |
| full-step seq1024 | 16282 | **15969** | −1.9% |

Loss **EXACT 6/6** (`10.572291→7.0119185` · `10.756927→11.807267` · `10.760399→13.442915`).
Torch fresh cùng phiên (tier E, T=14, `out/r11_torch_e.log`): **1060.8 / 1622.9 / 4209.6 ms**
→ tỉ lệ **2.75× / 3.45× / 3.79×**.

Tích luỹ cả hai bước (baseline H1 → nay):

| mục | H1 baseline | sau #10 Ask A | **sau Ask C.1** |
|---|---|---|---|
| Bucket `12 × block_bwd` | 2244 ms | 960.0 | **844.5** (**−62.4%**) |
| full-step seq8 | 4141 | 3000 | **2922** (**−29.4%**) |
| full-step seq256 | 6015 | 5531 | 5594 |
| full-step seq1024 | 16094 | 16282 | 15969 |

### 7.2 Kiểm chứng (sau Ask C.1)

| kiểm | kết quả |
|---|---|
| `tools/gate_f32.sh` | **135/135, `TOTAL fails=0`, exit 0** |
| Trainer | **15/15 `fails=0`** |
| Probe `_am5` | Ask A `bit_bad=0`; Ask C.1 seq8 `smm_fwd_at_bad=0 native_bad=0` |
| Probe `_p6ms` (2 rep) | **A 4.21× · B 5.40× · C 5.06×**, `bit_bad=0`, `fails=0` |
| Self-host | **IL_IDENTICAL** |

### 7.3 File đổi (Ask C.1)

3 file production trên (+`simd_probe_am.tkv` probe biến thể `BLOCK_BWD_FLAT`,
`_am5.tkv` thêm `_check_proj`). **Không** đổi native, **không** đổi compiler — đây là thay đổi
`.tkv` thuần.

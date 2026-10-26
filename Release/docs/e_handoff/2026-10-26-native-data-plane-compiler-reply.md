# BIÊN BẢN TRẢ LỜI COMPILER TEAM #3 — NATIVE DATA PLANE (4 BUILTIN) + 2 BUG

- **Ngày:** 2026-10-26
- **Đối tượng:** team Inference (`D:\TokenVector.Inference`)
- **Đơn yêu cầu:** `docs/COMPILER_TEAM_REQUEST3.md`
- **Kèm theo:** `dist/tkvc-tv.exe` (build mới) + `runtime/tkv_simd_native.dll` (**bắt buộc pull cả 2** — 3 builtin mới là pinvoke xuống DLL; thiếu DLL → `DllNotFoundException`) + `tools/simd_native/tkv_simd_native.c`

## 0. Tóm tắt trạng thái

| Ask trong đơn | Trạng thái | Chi tiết |
|---|---|---|
| `i32 f32_list_copy(dst, src, n)` | ✅ giao | §1.1 · test 28/28 |
| `i32 f32_list_add(dst, src, n)` | ✅ giao | §1.2 · test 28/28 |
| `f64 f32_grad_norm(g, n)` | ✅ giao **+ phải đọc §2** | §1.3 · bit-exact vs reference scalar (`d=0.0`) |
| `i32 adamw_step_glm(p, m, v, g, …)` | ✅ giao | §1.4 · bit-giống `adamw_step` từng bit |
| Bug C1 (local át tên global module) | ✅ fix | §3 |
| Bug C2 (`f32_zero` trong `while`) | ✅ fix | §3 — **cùng 1 root cause với C1** |
| Ưu tiên B (f32buf data plane) | 📐 **đề xuất thiết kế**, chưa implement | §5 |

---

## 1. ABI 4 builtin mới

Toàn bộ nằm trong class `TkvSimd` phát sinh tự động (không đổi export DLL cũ, không đổi builtin cũ). Wrapper **pin `_items` + gọi pinvoke ngay trong cùng method** (không `ToArray`, không copy trung gian — đúng pattern `GemmFullM` đã bàn giao), và **kiểm tra độ dài theo `Count` của list, không phải độ dài mảng `_items` (capacity)**.

### 1.1 `f32_list_copy(dst, src, n) -> i32`

| Hạng mục | Hợp đồng |
|---|---|
| `dst`, `src` | `list[f32]` (Tensor.data) — **bắt buộc list**, không nhận mảng handle/biểu thức; `list[f64]` → **lỗi lúc dịch** |
| `n` | `i32`, số phần tử (`0 ≤ n ≤ Count(dst)` và `≤ Count(src)`) |
| Hành vi | `dst[i] = src[i]` với `i = 0..n-1` (memcpy, **bit-exact**); chỉ ghi vùng `[0, n)`, phần còn lại của `dst` giữ nguyên; `n = 0` là nop |
| Trả về | `i32 0` = OK |
| Lỗi | `dst` hoặc `src` ngắn hơn `n` → ném `ArgumentException` đúng câu `f32_list_copy: dst va src phai co it nhat n phan tu` (ném lúc **chạy**, không phải lúc dịch — độ dài list là giá trị runtime) |
| Số liệu | Đọc/ghi thẳng `_items`, không `ToArray`/boxing/alloc mới |

Ví dụ wire (mang tính minh hoạ — tên biến lấy theo code của các bạn; copy-back `gpt2_unflatten` 844 ms/step, đơn §2.2):

```tkv
r = f32_list_copy(opt.p, ps_flat, opt.n)     # thay vòng interpreted ghi từng ptu
```

### 1.2 `f32_list_add(dst, src, n) -> i32`

| Hạng mục | Hợp đồng |
|---|---|
| `dst`, `src` | `list[f32]`, cùng kiểu; `list[f64]` → lỗi lúc dịch |
| Hành vi | `dst[i] += src[i]` (`i = 0..n-1`), tích lũy **1 pass** native AVX2 |
| Numerics | Elementwise fp32, **không gộp tổng** → không đổi thứ tự cộng: mỗi phần tử 1 phép `+` fp32 → **bit-giong** `dst[i] + src[i]` phiên interpreted |
| Trả về | `i32 0` = OK; list ngắn hơn `n` → `ArgumentException` (câu `f32_list_add: dst va src phai co it nhat n phan tu`) |

Thay 2 vòng dense `for k in range(V*h): a[k] = a[k] + b[k]` (38.6M ptu, 1202 ms = 24% BWD — đơn §2.1): mỗi vòng → **1 dòng gọi**.

### 1.3 `f32_grad_norm(g, n) -> f64` — hợp đồng số liệu ⚠

| Hạng mục | Hợp đồng |
|---|---|
| `g` | `list[f32]`; `list[f64]` → lỗi lúc dịch (`f32_grad_norm chi ho tro f32`) |
| Công thức | `sqrt(Σ g[i]²)` |
| **Bình phương** | **trên `float32`**: `float p = g[i]*g[i]` — khớp `s = s + g[i]*g[i]` (với `s: f64`) của `_norm_groups`/`_norm_mlp` |
| **Tích lũy** | **`double`, tuần tự `i = 0..n-1`** — không gộp lại, không song song, không AVX2 (giữ đúng thứ tự cộng như phiên interpreted, parity §2.3) |
| `sqrt` / trả về | `sqrt` trên `f64`, trả `f64` |
| Lỗi | `g.Count < n` → `ArgumentException` (`f32_grad_norm: g phai co it nhat n phan tu`); `n ≤ 0` → `0.0` |

**Kiểm chứng:** `tests/f32_list_ops_test.tkv` so với reference scalar viết đúng kiểu `.tkv` (`s: f64 = 0.0` + `s = s + g[i]*g[i]` + `sqrt`) → **`d = 0.0` (bit-exact)**, cộng với case 3-4-5 = 5.0.

⚠ **Nhưng xem §2 trước khi wire vào `AdamW.grad_norm()`** — phiên bản phẳng chưa bit-giống hàm nhóm của các bạn.

### 1.4 `adamw_step_glm(p, m, v, g, n, lr, b1, b2, eps, wd, bc1s, bc2s) -> i32`

| Hạng mục | Hợp đồng |
|---|---|
| `p`, `m`, `v` | buffer native `i64` (`alloc_bytes`/`f32buf_wrap`) — **giống hệt** `adamw_step` |
| `g` | **`list[f32]`** đọc thẳng `_items` (đây là điểm khác biệt duy nhất) |
| Công thức | Gọi **cùng entry native `AdamwStepF32`** với `adamw_step` → cùng công thức GĐ10, cùng thứ tự, bit-giống |
| Trả về | `i32 0` = OK; `g.Count < n` → `ArgumentException` (`adamw_step_glm: g phai co it nhat n phan tu`) |
| Lợi ích | bỏ được vòng r1 `f32_copy_to_buf(g_list → pgl)` ở nhánh `coef == 1.0` |

Wire vào `step()` (đơn §2.4) — 2 nhánh:

```tkv
if coef != 1.0:
    rzp = f32_zero(ptl, self.n)
    rax = f32_addcmul(ptl, pgl, ponl, coef, self.n)   # pt = coef*g (giữ nguyên)
    stw = adamw_step(ppl, pml, pvl, ptl, self.n, step_size, self.b1, self.b2, self.eps, wde, bc1, bc2s)
else:
    stw = adamw_step_glm(ppl, pml, pvl, gl, self.n, step_size, self.b1, self.b2, self.eps, wde, bc1, bc2s)
    # KHÔNG cần r1 = f32_copy_to_buf(gl, pgl, self.n) ở nhánh này
```

### 1.5 Negative test (biên dịch từ chối)

| File | Lý do bị từ chối |
|---|---|
| `tests/negative/f32_list_copy_arity.tkv` | sai số tham số |
| `tests/negative/f32_list_copy_f64.tkv` | `list[f64]` |
| `tests/negative/f32_grad_norm_f64.tkv` | `list[f64]` |
| `tests/negative/adamw_step_glm_on_buf.tkv` | `g` là buffer `i64` (dùng `adamw_step`) |

Điều kiện **chỉ kiểm tra lúc chạy** (không đoán được lúc dịch): `n` vượt `Count` → ném `ArgumentException` rõ, có try/except trong test (`copy_dst_qua_dai_nem`, `copy_src_qua_ngan_nem`, `add_qua_dai_nem`, `grad_norm_qua_dai_nem`, `glm_g_qua_ngan_nem_n64/n37`) — 5/5 đều bắt được.

---

## 2. ⚠ PHẢI BÁO TRƯỚC (đơn §2.3): `f32_grad_norm` phẳng **không** bit-giống norm theo nhóm

Đơn yêu cầu: *«Nếu bắt buộc đổi thứ tự cộng, báo lại repo trước để đổi tolerance.»* → **đây là báo trước.**

Hàm thật trong `tv/training/trainer.tkv` **không** cộng phẳng:

```tkv
# _norm_groups (serial) / _tn_one (parallel 12 worker) — cùng công thức:
for k in range(ng):                 # từng NHÓM tham số
    s = 0.0
    for i in range(cnt):
        s = s + g[off + i] * g[off + i]
    nrm = sqrt(s)
    tot = tot + nrm * nrm           # gộp theo THỨ TỰ NHÓM, nrm đã sqrt
return sqrt(tot)
```

(`_norm_mlp` làm y hệt với 4 khoảng `W1/B1/W2/B2`.)

Hai đường **bằng nhau về mặt toán** (`√(Σ s_k) = √(Σ (√s_k)²)`) nhưng **khác bit** vì:

1. **Phân rã tích lũy khác:** của các bạn là sum **theo nhóm** rồi gộp; `f32_grad_norm(g, n)` là **một accumulator duy nhất** trên toàn 124M phần tử.
2. **Thứ tự gộp khác:** `tot += sqrt(s_k)*sqrt(s_k)` (sqrt rồi nhân lại) ≠ `tot += s_k` ≠ sum phẳng.

→ Thay trực tiếp sẽ cho `gn` lệch vài ulp → `coef = clip/(gn+1e-6)` lệch → chuỗi 3 seq **không còn EXACT** (gate 15/15 + loss chain). Chênh lệch là cực nhỏ (vài ×1e-7 tương đối) nhưng **không phải 0**.

### Hai phương án để các bạn chọn

**A. Chấp nhận tolerance (nhanh nhất, không cần tôi làm thêm).**
Wire `f32_grad_norm(g, n)` thẳng, đổi parity loss-chain từ EXACT sang TOL (đề nghị `1e-6` trên `gn`, kiểm thực tế bằng gate 15/15 chạy lại). Lợi ích: giữ nguyên 1 ABI, 1 call, ~390 ms → ~100–150 ms.

**B. Giữ EXACT — tôi bổ sung biến thể nhóm (đề nghị nếu muốn giữ nguyên gate).**

```tkv
f64 f32_grad_norm_groups(g, n, groups, ng)
#  g: list[f32], n: i32 tong so ptu
#  groups: list[i64] (kich thuoc tung nhom — chinh la opt.groups hien tai)
#  ng: i32 so nhom
#  Native lap lai DUNG cong thuc tren: sum theo nhom (f64 tuan tu, binh phuong
#  f32) -> nrm = sqrt(s) -> tot += nrm*nrm theo thu tu nhom -> sqrt(tot).
```

Vì worker song song của các bạn cũng tính `s_k` tuần tự trong nhóm rồi main gộp theo thứ tự nhóm → **native 1 luồng này bit-giống cả 2 đường serial/parallel hiện tại** (đúng như kết luận «cùng phép + và thứ tự với serial → BIT-EXACT» trong comment của `_norm_groups`).

Nói một câu: **cần tôi làm B thì báo, tôi wire ngay** (native + wrapper + test bit-exact fixture 8 token); nếu các bạn đổi tolerance thì dùng A, không cần gì thêm.

Ghi chú thêm về numerics đã chọn: `f32_grad_norm` **bình phương trên f32** (khớp `s + g[i]*g[i]`), **tích lũy f64 tuần tự** — đã kiểm chứng bit-exact với reference scalar. Nếu các bạn thay code interpreted sang bình phương trên f64 thì báo, tôi đổi theo.

---

## 3. Hai bug C1/C2 — **cùng một root cause**, đã fix

### 3.1 Chứng minh

Cả hai đều ném:

```text
System.InvalidProgramException: Common Language Runtime detected an invalid program.
   at TKVApp.main()
```

trong khi `tkvc` vẫn in `[tkvc] da dich`. IL phát hiện:

```il
    ldc.i4 1024
    stloc.s -1        ; ← không có local slot nào số -1: đây là bug
```

**Root cause (một, cho cả 2 bug):** gán cho một tên là **hằng số cấp module** (của chính file, hoặc của module `import` vào — `hang_mod` được gộp chung) thì `scope` vẫn giữ binding `kind='const'` với `idx = -1` (const không có slot nhớ). First-pass bỏ qua việc khai local vì tên đã “declared”, còn `_store_var` không có nhánh cho `const` → rơi xuống câu lệnh cuối sinh `stloc.s {idx}` → **`stloc.s -1`**. ilasm assemble được (số âm là hợp lệ với verifier lỏng), CLR ném `InvalidProgramException` khi JIT method.

- **C1**: `MaxPos = 1024` trong `main()` với `MaxPos` là global của module import → đúng kịch bản trên.
- **C2**: mẫu báo cáo là `z = f32_zero(p, 1024)` trong `while`. Tôi tái dựng được **cùng exception** với `f32_zero` trong loop, và **còn tái dựng được cả với `z = 1` thuần** khi `z` là hằng số cấp module — tức **`f32_zero` không phải thủ phạm**: nó chỉ là câu gán chạm phải bug. (Bằng chứng: xóa đúng dòng gán thì chạy — đúng như A/B trong đơn.)

Tôi cũng tái dựng được với gán nằm trong `if`, và với biến loop `q` trùng tên hằng số — tất cả đều cùng một lỗi.

### 3.2 Cách fix (compiler)

1. **First-pass khai local MỚI (shadow, đúng ngữ nghĩa Python)** khi một tên hằng số cấp module bị gán lại trong chính hàm: `_fp_declare_scalar` / `_khai_local` bỏ rang buoc `const` khỏi `declared_names` và khai slot local thật. Loại trừ: tham số (vẫn `starg`), tên bị closure bắt (vẫn ghi cell), `global X` (vẫn `stsfld`).
2. **Làm lưới an toàn:** nếu còn trường hợp gán mà first-pass không thấy, `_store_var` giờ **báo lỗi compile rõ ràng** thay vì sinh `stloc.s -1` (đúng phương án “báo lỗi compile” trong đơn).

Ảnh hưởng: **không đổi hành vi của code đang chạy** — mọi method chứa kiểu gán này trước đây đều *vỡ ngay khi JIT* nên không tồn tại code cũ bị ảnh hưởng; các vị trí đọc hằng số trong hàm không gán thì không đổi.

### 3.3 Hành vi cần biết (khác Python 1 chỗ)

```tkv
X = 1
def f() -> "i32":
    print(str(X))   # Python: UnboundLocalError
    X = 5           # tkv sau fix: local mới → in "0" (giá trị init) rồi ghi 5
```

Tôi chọn **không crash** thay cho ném lỗi unbound (phân tích “đọc trước khi gán” nằm ngoài phạm vi fix này). Nếu các bạn muốn đúng Python (báo lỗi lúc dịch), báo lại tôi bổ sung.

### 3.4 Test

`tests/bug_const_shadow_test.tkv` — **5/5 PASS**: local át tên hằng số (C1), hằng số vẫn đọc được ở hàm khác, gán `f32_zero` trong `while` (C2), gán trong `if`, giá trị trả về đúng. Các probe tái dựng `bug_c1`/`c2g1`/`c2g2`/`c2g3`/`m1`/`m2`/`m3` trong `build/scratch/` đều chạy sạch sau fix (trước fix: `InvalidProgramException`).

Ghi chú nhỏ liên quan: `import <ten_khong_ton_tai>` **không báo lỗi** (compile vẫn thành công) — đó là lý do probe của các bạn chạy được khi đặt trong `out/`. Đây là hành vi riêng, tôi **không đổi** trong lần này; nếu muốn fail-fast thì báo lại.

---

## 4. Gate + đo

Toàn bộ log: **`out/gate_native_data_plane.log`**.

| Gate | Kết quả |
|---|---|
| `vong.exe` (self-host, 133 file) | **IL_IDENTICAL** (chạy 2 lần: sau khi thêm 4 builtin, và sau khi sửa kiểm tra theo `Count`) |
| `testkit_gate.ps1` | **PASS 133/133 + NEG 42/42** (trước: 131/131 + 38/38 → +2 test, +4 negative) |
| `dang_ky_gate` | **PASS** — 133 file / 2149 hàm, VI PHAM 0 (trước: 2141 → +8 hàm compiler) |
| `lint_rules_gate` | **PASS** — 8 cảnh báo = baseline |
| `gen_builtin_ref` | regenerate **445 tên / 114 file** (trước 441 → +4); `--check`: 83 tên thiếu doc = **baseline** (HEAD thiếu 84) |
| `assert_il` (`tests/f32_list_ops_test.tkv`) | **PASS** — `F32ListCopyM x5`, `F32ListAddM x3`, `F32GradNormM x4`, `AdamwGlmM x2`, `float32& pinned x35`, `get_Count x42`, `pinvokeimpl x19` + kiểm tra phạm vi method: **`ToArray = 0` trong cả 4 wrapper** (56 `ToArray` còn lại nằm ở các helper list-generic cũ `AddLF32`/…, không thuộc đường data plane) |
| `perf_gate` | **PASS** — `perf_e2e −3.9%`, `perf_f32buf −4.0%`, `perf_f32mm −3.4%`, `perf_mm +2.5%` (checksum khớp baseline) |
| `chay.exe` (tests_suite) | **51 DAT / 734 TRUOT = baseline** (không regress) |

### 4.1 A/B đo thật (best-of-3, interpreted vs native **cùng máy**, `bench_dp.tkv`)

| Đường | `n` | interpreted (ms) | native (ms) | speedup | đúng số? |
|---|---|---|---|---|---|
| `f32_list_add` (1 vòng dense BWD, §2.1) | 38,600,000 | 1094 | **31** | **35×** | `bit_bad = 0` |
| `f32_list_copy` (copy-back unflatten, §2.2) | 38,600,000 | 1000 | **15** | **67×** | `bit_bad = 0` |
| `f32_grad_norm` (§2.3) | 124,000,000 | 3172 | **46** | **69×** | `absdiff = 0.0` (bit-exact) |

Đối chiếu với ngân sách §3 của đơn (số của các bạn @seq8 — máy/khung đo khác, chỉ so thứ tự):

| bucket | đơn ước (hiện tại → sau native) | đo tại đây (interpreted → native) |
|---|---|---|
| 2 vòng dense BWD | 1202 → ~40 ms | 2×1094 → **2×31 = 62 ms** |
| copy-back unflatten | 844 → ~30 ms | 1000 → **15 ms** |
| `grad_norm` | 390 → ~100–150 ms | 3172 → **46 ms** |
| r1 g→buf (bỏ với `adamw_step_glm`) | 78 → 0 | bỏ được thật ở nhánh `coef == 1.0` |

→ cả 3 đường đều **thoáng hơn ngân sách post-native** của đơn (40/30/100–150 ms) với biên lớn; phần budget còn lại (~880 ms «glue») không thuộc ask này.

**Cảnh báo đo:** benchmark đây là wrapper `.tkv` tự viết, **không phải probe CG của các bạn** — số thật phải đo lại bằng probe production (`_bd2.tkv`, `gpt2_unflatten`, `opt.grad_norm`) sau khi wire, như đơn §5 đã nói. Các con số này chỉ để xác nhận **thứ tự và biên độ**.

---

## 5. Ưu tiên B — đề xuất thiết kế f32buf data plane (chưa implement)

Đúng yêu cầu §2.5: **đề xuất trước, chưa wire.**

### 5.1 Mục tiêu

`Tensor.data` là **handle vào native buffer** (`i64`), thay vì `List[Single]`. Toàn bộ BWD/optimizer/unflatten sống trên buffer; `list↔buf` chỉ xảy ra ở **biên** (đọc/ghi dữ liệu vào/ra), nơi đã có sẵn builtin.

### 5.2 ABI đề xuất

```tkv
# (DA CO) f32buf_wrap(p: i64, n: i32) -> i64      # buffer handle (REFERENCE §509)
# (DA CO) alloc_bytes(n*4) -> i64 ; free_bytes(p)

# MOI: quan ly phia Tensor
i32   f32buf_len(h)                      # doc so phan tu da cap phat
i32   f32buf_copy_to_list(h, dst, n)     # = f32_copy_from_buf da co (dat lai ten giao dien)
i32   f32buf_copy_from_list(h, src, n)   # = f32_copy_to_buf da co
i64   f32buf_from_list(src, n)           # alloc + copy 1 lan: tao handle tu list (biên vào)
i64   f32buf_alloc_zero(n)               # alloc + f32_zero (zero-fill, het vong r0)
f32   f32buf_get(h, i) / i32 f32buf_set(h, i, v)   # CHI cho phia interpreted con lai (cham, co tinh)
```

Ghi chú:

- **Không thay `Tensor.data[k]` interpreted bằng FFI từng phần tử làm đường nóng** — `f32buf_get/set` chỉ để giữ tương thích các chỗ lẻ (đọc/ghi rải rác), đường nóng phải là bulk (`f32_list_*`, `f32_copy_*`, `simd_gemm_full`, `adamw_step_*`).
- Mở rộng `simd_gemm_full`/`adamw_step_glm`/`f32_list_*` nhận **handle** thay list là thay **wrapper** (IL đã tách giữa “lấy con trỏ” và “gọi native”), không đổi native.

### 5.3 Danh sách điểm đụng (rủi ro theo PLAN B)

1. **Định dạng ckpt**: giữ nguyên list khi serialize (copy buffer → list 1 lần trước khi ghi) → **ckpt không đổi định dạng**, chỉ đổi nơi sống. Nếu đổi luôn định dạng thì phải bump version + converter.
2. **Resume bit-exact**: `sync_mv()` / `push_p()` (`pdirty`) phải chuyển sang coi buffer là nguồn chân lý; thứ tự copy quyết định bit.
3. **Mọi `Tensor.data[k]` interpreted còn lại** (đoạn `zero_grad`, `gpt2_unflatten`, bench, test đọc `opt.p`) → cần rà và thay bằng bulk/`f32buf_get`.
4. **Biên list↔buf**: đã có sẵn (`f32_copy_to/from_buf`, `f32_list_copy/add`) — chính là ask §2.1/§2.2 của đơn này; **không cần ABI mới để làm biên**.
5. **Double-buffer / lifetime**: buffer do ai free (`free_bytes`), handle dùng sai sau free → cần hợp đồng (đề nghị: `Tensor` giữ `p` và free trong destructor của Python-level; tkv hiện không có destructor → ghi vào contract của repo).

### 5.4 Lộ trình đề xuất (từng bước, không big-bang)

| Bước | Nội dung | Rủi ro |
|---|---|---|
| B2.1 | `opt.p` (đã có `pdirty`/`push_p`) sống hoàn toàn trên buffer; `opt.p` list chỉ là cache đọc | thấp — đã làm một nửa |
| B2.2 | `opt.m`/`opt.v` bỏ hẳn list (đã làm một nửa với `sync_mv` lazy) | thấp |
| B2.3 | `grads` (`self.g`) → buffer: `zero_grad` = `f32_zero`, BWD ghi thẳng buffer, `f32_list_add` → **thay bằng** `f32_addcmul`/kernel list-buf tương đương | **cao** — đụng mọi chỗ `g[k]` interpreted |
| B2.4 | `Tensor.data` chung (weights) → buffer + ckpt bridge | **cao nhất** — làm cuối, chỉ khi B2.1–3 ăn tiền thật |

**Khuyến nghị:** làm B2.1–B2.2 trước, đo, rồi mới quyết B2.3/B2.4 — ask §2.1/§2.2/§2.3 của đơn này đã lấy phần lớn budget (~2.3 s/step) mà **không cần** đổi định dạng gì cả.

---

## 6. Việc team Inference cần làm tiếp (theo §5 đơn)

1. **Smoke probe** từng builtin mới với TOL 1e-6 so với interpreted + negative `n > len` (đã có mẫu trong `tests/f32_list_ops_test.tkv`).
2. **`grad_norm`/`adamw_step_glm` bit-exact trên fixture 8 token** — đọc §2 trước (chọn A hay B).
3. Gate **135/135** (testkit giờ là **133/133 + NEG 42/42** ở phía compiler) + trainer **15/15** (kèm resume) + loss chain 3 seq EXACT.
4. Wire dần theo mẫu M5-opt, **sync 4 mirror `*.tkv`** của repo Inference.
5. Bench 3 seq best-of xen kẽ torch fresh → `HANDOFF §0.53`.

**Kéo 2 file:** `Release/dist/tkvc-tv.exe` + `Release/runtime/tkv_simd_native.dll` (3 builtin mới là P/Invoke xuống DLL mới).

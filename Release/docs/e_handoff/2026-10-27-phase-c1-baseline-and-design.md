# PHASE C1 — BASELINE + ROOT-CAUSE IL + THIẾT KẾ (đầu vào cho yêu cầu #5)

**Ngày:** 2026-10-27 · **Đơn:** `docs/COMPILER_TEAM_REQUEST5.md`
**Trạng thái:** ✅ đo baseline + truy root cause IL · ⬜ **chưa implement codegen** (xem §5)

---

## 1. Baseline — harness `_f32p` chạy được ngay (chưa đổi codegen nào)

```text
$ tkvc-tv.exe tv/tests/_f32p.tkv out/_f32p.exe main && ./out/_f32p.exe
[1] BUILD tile512/768 x120 batch, best-of-3: f64=188.0 ms  f32=171.0 ms  speedup=1.099x  BIT_MAXDIFF=0.0
[2] ACC  T=768   x120 batch, best-of-3: production=531.0 ms  f32local=562.0 ms  speedup=0.945x  BIT_MAXDIFF=0.0
[3] ARITH x12000000 batch, best-of3: f64=313.0 ms  f32=312.0 ms  speedup=1.003x
=== _f32p done fails=0 ===
```

→ **Tái lập đúng kết luận §2.1 của đơn**: `f32` locals **BUST** (1.0×, 0.94×, 1.0×).
Mục tiêu C1 = **≥ 2× trên 4 shape** → hiện còn **≥ 1.8–2.1× nữa** mới đạt.

Log: `out/_f32p_baseline.log`

---

## 2. Root cause — IL thật của vòng BUILD (`_b64`)

### 2.1 Toàn bộ thân vòng copy `out[dst] = d[src + j]`

```il
_b64_W2_start:
  ldloc.s 3            ; j (i64)
  ldarg.s 6            ; pw
  clt
  brfalse _b64_W2_end

  ldarg.s 1            ; d  (list ref)      ─┐
  ldloc.s 4            ; src (i64)           │ doc d[src+j]
  ldloc.s 3            ; j (i64)             │
  add                                         │
  conv.ovf.i4          ← NHANH 1 (OverflowException)
  callvirt ...::get_Item(int32)  ← NHANH 2 (bounds) + DISPATCH 1

  ldarg.s 0            ; out (list ref)     ─┐
  ldloc.s 2            ; dst (i64)           │ ghi out[dst]
  conv.ovf.i4          ← NHANH 3 (OverflowException)
  callvirt ...::set_Item(int32, !0) ← NHANH 4 (bounds) + DISPATCH 2

  ldloc.s 2 / ldc.i8 1 / add / stloc.s 2     ; dst++
  ldloc.s 3 / ldc.i8 1 / add / stloc.s 3     ; j++
  br _b64_W2_start
```

### 2.2 Chi phí mỗi phần tử (chưa vectorize)

| thành phần | số | chi phí |
|---|---|---|
| `conv.ovf.i4` — i64 → i32 **có kiểm tra** | 2 | 2 nhánh (throw `OverflowException`) |
| `callvirt get_Item` / `set_Item` | 2 | 2 dispatch + 2 bounds check + 2 load `_items` từ object |
| tính index i64 (`add`) | 2 | register ops |
| loop (`clt` + `brfalse` + `br`) | — | 2–3 nhánh |

→ **≈ 5–6 nhánh + 2 virtual dispatch mỗi phần tử**, trong khi phép toán thật chỉ là
1 load + 1 add + 1 store float32.

### 2.3 Vì sao `get_Item` không tự tối ưu

`List<T>.get_Item` là generic method trên type **mở** (không sealed). Dù JIT có
thể devirtualize, mỗi call vẫn phải: null-check object → load `_items` field →
bounds check `_size` → load phần tử. Không có cách nào JIT **gộp 2 call (read+write)
hoặc vectorize** vì chúng vẫn là 2 callvirt rời nhau.

**Kết luận:** đúng lever cần sửa là **codegen index trong vòng** (§3 yêu cầu), không
phải typing (đã bust) và không phải wrapper (đã có builtin bulk cho 2 vòng).

---

## 3. Thiết kế đề xuất (C1)

### 3.1 Mục tiêu tối thiểu an toàn — bỏ 2 dispatch + gộp bounds check

Trong ngữ cảnh vòng `while`/`for`, thay vì:

```
ldlist ; idx ; conv.ovf.i4 ; callvirt get_Item        // mỗi phần tử
```

emit:

```il
; --- TRƯỚC vòng (một lần) ---
ldlist
callvirt get_Count()          -> hoisted cnt (local)
; reflection _items           -> hoisted arr (float32[])
; CHỨNG MINH phạm vi vòng ⊆ [0, cnt)  -> 1 check duy nhất

; --- TRONG vòng (mỗi phần tử) ---
ldloc arr
ldloc idx ; conv.ovf.i4       // GIỮ nguyên semantics OverflowException
ldelem.r4                     // CLR tự bounds-check theo arr.Length
```

`_items.Length >= Count` nên mọi index hợp lệ với `Count` đều hợp lệ với array.

### 3.2 Hợp đồng exception — điểm phải cẩn thận

| tình huống | hiện tại | sau hoist | cách xử lý |
|---|---|---|---|
| index vượt `Count` | `ArgumentOutOfRangeException` (từ `List.get_Item`) | `IndexOutOfRangeException` (từ `ldelem`) | **phải emit nhánh ném `ArgumentOutOfRangeException` tường minh** để gate negative giữ nguyên |
| i64 không vừa int32 | `OverflowException` | giữ nguyên | giữ `conv.ovf.i4` |
| vòng không chạy (`limit ≤ 0`) | không ném | **không được ném** | check hoist chỉ đặt sau guard vòng sẽ chạy |
| exception xảy ra lúc nào | giữa vòng | **trước vòng** | ⚠ khác biệt về thời điểm — cần chốt với repo (§4) |

### 3.3 Phân đoạn an toàn (đề nghị làm từng bước, không big-bang)

| bước | phạm vi | rủi ro |
|---|---|---|
| **C1-a** | index **chính là biến đếm vòng** (`a[i]` với `while i < n`) — chứng minh `n ≤ len(a)` | thấp — pattern rõ |
| **C1-b** | index affine đơn giản `a[i + c]`, `a[c + i]` với hằng `c ≥ 0` | trung bình |
| **C1-c** | index là **counter riêng** (`out[dst]` khi `dst++` song song) — cần range analysis của `dst` | **cao** — đây chính là shape của `_b64`/`_a64`! |

⚠ **Vấn đề then chốt:** shape đo trong harness (`out[dst]`, `cd[bc]`, `Ct[bt]`)
nằm ở **C1-c** — cần chứng minh `dst`/`bc`/`bt` nằm trong `[0, len)` qua mọi
lần lặp. Làm được C1-c thì mới chạm được mục tiêu ≥2× của §4; chỉ làm C1-a
có thể không đủ.

### 3.4 Vectorize (§3.3 đơn) — để sau

Auto-vectorize AVX2 yêu cầu nhận diện pattern elementwise **và** giữ hợp đồng
*bit-exact* (1 phép/ptu, không đổi thứ tự). Repo đã có kernel AVX2 theo từng op
(`simd_feature.tkv`), nên **C2 (builtin từng op) có sẵn đường lui an toàn**.

Đề nghị: **hoàn tất C1-a/b đo trước**, nếu < 2× → chuyển C2 theo thứ tự A2
(`softmax_bwd` → `layernorm_bwd` → `gelu_bwd` → `bias_grad`) như §5 của đơn.

---

## 4. Trả lời 3 câu hỏi §4 — **ĐÃ TRẢ LỜI ĐỦ, KHÔNG CẦN HỎI LẠI REPO**

### 4.1 Q1 — Hợp đồng exception (đo thật, `tv/tests/_oob_probe.tkv`)

| case | hành vi HIỆN TẠI |
|---|---|
| `[1]` đọc `a[len]` | `ArgumentOutOfRangeException` — msg `"Index was out of range. Must be non-negative and less than the size of the collection."`, **paramName `index`** |
| `[2]` ghi `a[len]` | giống hệt `[1]` |
| `[3]` chỉ số âm động (`a[-1]`) | giống hệt `[1]` |
| `[4]` chỉ số i64 = 5e9 | `OverflowException` — `"Arithmetic operation resulted in an overflow."` (từ `conv.ovf.i4`) |
| `[5]` vòng **không chạy** (`len=0, lim=0`) | **KHÔNG ném** |
| `[6]` vòng chạy qua `len` (`len=1, lim=5`) | ném **giữa vòng**, tại lần lặp đầu vượt (`kk=1`) |

→ **Hợp đồng phải giữ nguyên:** đúng *type*, đúng *message*, đúng *paramName*,
`OverflowException` cho i64→i32, **không ném khi vòng không chạy**, và ném ở
lần OOB đầu tiên.

**Hệ quả cho thiết kế:** check hoist phải đặt **sau guard vòng sẽ chạy**
(`n > 0` mới check) để không phá case `[5]`. Thời điểm ném có thể sớm hơn
(một lần trước vòng thay vì giữa vòng) — **acceptance §4 chỉ ghi «vẫn ném
đúng exception lúc chạy», không quy định thời điểm**, nên chấp nhận được;
nhưng phải giữ nguyên *type + message + paramName* → **không được dùng `ldelem`
thô** (array ném `IndexOutOfRangeException`, sai type) — phải emit nhánh ném
`ArgumentOutOfRangeException("", msg)` tường minh.

### 4.2 Q2 — «4 shape» của acceptance: **C1-a/b KHÔNG ĐỦ**

Đo `_f32p` cho thấy 2 shape **trong vùng đo** đều là **C1-c**:

| case | thân vòng | phân loại |
|---|---|---|
| `[1]` BUILD | `out[dst] = d[src + j]` | `dst` là **counter riêng** → **C1-c** · `src+j` có `j` là biến đếm → C1-b |
| `[2]` ACC | `cd[bc] = cd[bc] + Ct[bt]` | `bc`, `bt` là **counter riêng** → **C1-c** |
| `[3]` ARITH | `x*x+0.5` | không index list |

→ **C1-a/b chỉ chạm các vòng `a[i]` ngoài vùng đo** (`_md`, setup `d[i]=...`) —
**hiệu số đo trên acceptance ≈ 0%**. Muốn đạt ≥2× phải làm **C1-c**.

**Nhưng C1-c nhẹ hơn thiết kế ban đầu** — xem §4.4.

### 4.3 Q3 — `IL_IDENTICAL` nghĩa là (a), **không cần cờ opt-in**

Nguồn: [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §0 + [`tools/vong.tkv`](../../tools/vong.tkv):

1. Gộp 132 file `.tkv` → 1 nguồn ≈ 2,9 MB
2. `dist/tkvc-tv.exe` biên dịch → `g1.il` ≈ 13 MB
3. `g1.exe` biên dịch lại chính nó → `g2.il`
4. In `IL_IDENTICAL` nếu 2 file giống byte-for-byte

Nghĩa là **điểm bất động của vòng tự-host (g1 == g2)**, **KHÔNG** phải «khớp
với baseline cũ»:

> `g1 != g2` KHÔNG có nghĩa là lỗi… Đó là **TIẾN HỌA**… `vong` tự nâng cấp
> `g2` thành `dist\tkvc-tv.exe` và in yêu cầu chạy lại; vòng sau lại biến dịch
> từ `g2` cho đến khi `IL_IDENTICAL`.

→ **Đổi codegen là bình thường.** Lần đầu sẽ in `IL KHAC NHAU`, chạy lại
`tools/vong.exe` cho tới khi hội tụ — «Mỗi thay đổi `compiler_bootstrap/` cần
một thay đổi compiler, tức khoảng **12–20 phút** tính cả các vòng tiến hoá.»

**Không cần cờ opt-in** (đã bỏ giả định đó khỏi §5).

### 4.4 Phát hiện lớn: **đã có sẵn bộ auto-vectorize P6 — nhưng chỉ cho `f32buf`**

[`control_flow.tkv`](../../compiler_bootstrap/compiler/il_features/control_flow.tkv)
đã có:

- `_licm` (LICM) — **đã hoist biểu diễn loop-invariant vào preheader**
- `_p6_vectorize_while` (dòng 1759) / `_p6_vectorize_for` (dòng 1925)
- `_p6_vec_phat` (dòng 1847) — **phát IL vòng vector bước 4 (`v_load4`/`v_store4`) + đuôi scalar**

`codegen_for` đã gọi `_p6_vectorize_for` **trước khi** phát vòng thường.

Nhưng bộ khớp mẫu chặn ở [`_p6_is_f32buf`](../../compiler_bootstrap/compiler/il_features/control_flow.tkv):

```python
def _p6_is_f32buf(scope, ten) -> "i32":
    ta = scope.tra(ten).ta
    return 1 if ta is not None and ta.shape_ten == 'f32buf' else 0
```

→ **`shape_ten == 'list'` bị loại.** Đó chính là lý do mọi vòng `list[f32]`
trong repo không bao giờ vector hoá, trong khi **máy móc vector đã có sẵn**.

**C1 do đó không phải xây từ đầu — nó là MỘT CÁI NHỚN vào matcher:**

| việc | nơi | độ khó |
|---|---|---|
| cho phép `shape_ten == 'list'` (dtype `f32`) bên cạnh `f32buf` | `_p6_is_f32buf` / `_p6_viet_lai_rhs` | nhỏ |
| preheader: validate `n <= len(list)` (đúng type+message §4.1) | thêm vào đầu `_p6_vec_phat` | nhỏ–vừa |
| preheader: lấy `_items` → địa chỉ `v_load4` (pin/GCHandle 1 lần) | mẫu đã có ở `simd_feature.tkv` (`_pk_get_items`) | **vừa — điểm rủi ro chính** |
| đuôi scalar vẫn đi `get_Item` (giữ OOB contract) | đã có sẵn trong `_p6_vec_phat` | 0 |

**An toàn:** bộ khớp mẫu đòi thanh vòng **đúng 2 câu** (`idx_assign` + `iv = iv + 1`)
→ trong thân **không có `append`/gọi hàm** nên `_items` không thể bị cấp lại
trong lúc hoist đang giữ địa chỉ. Đây là điều kiện an toàn sẵn có, không cần
phân tích thêm.

> **Rủi ro cần kiểm khi implement:** hoist `pinned`/`GCHandle` qua `.locals init`
> — `ctx.locals_decl` là `(name, TypeAnn)` và có thể không diễn tả được local
> byref `float32& pinned`. Nếu không được thì dùng `GCHandle.Alloc` 1 lần
> trước vòng (≈1 µs, không đáng kể so với hàng triệu phần tử).

---

## 5. Trạng thái

| việc | trạng thái |
|---|---|
| Đo baseline `_f32p` 3 case | ✅ (1.099× / 0.945× / 1.003× — f32 locals bust, khớp đơn) |
| Truy root cause IL từng lệnh | ✅ (§2 — 5–6 nhánh + 2 dispatch/ptu) |
| Thiết kế hoist + hợp đồng exception | ✅ (§3) |
| **Q1 — hợp đồng exception** | ✅ **đã đo, §4.1** — không cần hỏi repo |
| **Q2 — C1-a/b có đủ không** | ✅ **§4.2 — KHÔNG đủ, cần C1-c** |
| **Q3 — ý nghĩa `IL_IDENTICAL`** | ✅ **§4.3 = điểm bất động, không cần cờ opt-in** |
| **Phát hiện bộ vectorize P6 có sẵn** | ✅ **§4.4 — C1 = mở matcher cho `list[f32]`** |
| ⚠ BUG compiler mới phát hiện | ✅ **§6 — `__tkv_import__` không resolve → SEGFAULT** |
| Implement mở `_p6_*` cho `list[f32]` + preheader validate | ⬜ |
| Acceptance §4 (≥2×, gate 135/135, trainer 15/15, loss EXACT, OOB) | ⬜ |

**Chưa có thay đổi codegen nào** → chưa cần chạy lại self-host/gate ở bước này.

---

## 6. ⚠ BUG compiler phát hiện thêm trong lúc làm việc này

**`__tkv_import__` trỏ tới module không tìm được → `tkvc-tv.exe` SEGFAULT**
(exit 139 / `0xc0000005`), hiện cửa sổ
`System Error: Exception Processing Message 0xc0000005 - Unexpected parameters`
và **không in ra thông điệp lỗi nào cả**.

### Repro tối giản (cùng nội dung, khác đúng 1 dòng)

```tkv
__tkv_import__ = ["tkv_test_lib"]     # <- dòng này gây crash

def main() -> "i32":
    print("hi")
    return 0
```

| điều kiện | kết quả |
|---|---|
| có dòng import, thư mục **không** có `tkv_test_lib.tkv` cạnh nó | **exit 139, không ra exe, không thông điệp** |
| cùng nội dung, **bỏ** dòng import | `[tkvc] da dich`, exit 0 |
| có dòng import, đặt cạnh `Release/tests/tkv_test_lib.tkv` | chạy bình thường |

### Bằng chứng trong repo

- `tkv_test_lib.tkv` chỉ tồn tại ở **`Release/tests/tkv_test_lib.tkv`**.
- Bản gốc probe `_oob_probe.tkv` đặt ở `tv/tests/` (repo Inference, không có lib)
  đã crash đúng kiểu này → phải bỏ dòng import (probe không dùng `check()`) mới chạy được.
- Không có `try`/`raise` quanh bước resolve `__tkv_import__` → nhiều khả năng
  đệ quy vô tận khi tra module làm tràn stack, hoặc deref con trỏ null.

### Đề nghị

Nếu không tìm thấy module trong `__tkv_import__` → raise `SyntaxError` kèm tên
module + đường dẫn đã tìm (giống các lỗi `[tkvc] loi dich: ...` khác), thay vì
crash process.

> Không thuộc scope C1 nhưng **cần sửa sớm**: nó biến một lỗi cú pháp thành
> crash với thông điệp `0xc0000005` vô nghĩa, khó chẩn cho người dùng.
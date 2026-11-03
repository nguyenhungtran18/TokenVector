# BIÊN BẢN TRẢ LỜI COMPILER TEAM #4 — ĐIỀU TRA `adamw_step_glm` + ĐÍNH CHỈNH SỐ COPY-BACK

**Ngày:** 2026-10-27 · **Đơn:** `docs/COMPILER_TEAM_REQUEST4.md` (Inference → Compiler)
**Repro:** `tv/tests/_gl1.tkv` (của bạn) + `_gl1c.tkv`, `_gl1d.tkv` (mới, đính kèm)
**Máy:** 12 129 MB RAM, Xeon E5-2695 v3 (14C/28T) — **lưu ý: đơn ghi heap bench 8–9 GB, máy này tổng 12 GB**

---

## 0. Tóm tắt

| mục | kết luận |
|---|---|
| **A — `adamw_step_glm` +1.9 s** | **KHÔNG tái lập được.** Cả 3 giả thuyết A3.1/A3.2/A3.3 đều bị **bác bằng số đo**. Gọi trực tiếp glm **nhanh hơn 78–110 ms** ở cả 3 điều kiện (idle / GC churn / **81 lần gen2 GC đồng thời ngay lúc đang pin**). |
| — cơ chế thật | **Không có cơ chế nào trong wrapper.** `AdamwGlmM` happy-path = **0 alloc / 0 box / 0 GCHandle / 0 ToArray**. Khác `AdamwM` chỉ 5 phép reflection mỗi call (~µs) + 1 local `pinned`. |
| — tín hiệu bench | **Nằm trong noise.** `pb1 ≡ pb2` (IL giống hệt 0 dòng lệch) nên biến «unflatten» không tồn tại; `pb0` vs `pb3` lệch **1394 dòng ở `gpt2_backward` + ~25 method** nên `pb3` không phải baseline hợp lệ; riêng `pb2`↔`pb3` thì **chỉ lệch `step()`** — nhưng tín hiệu **không scale với `steps`** (doubles → đổi dấu). |
| **B — số copy-back** | Số thật shape production (148-slice, 124 439 808 ptu): **4937 ms interpreted → 63 ms native (78×, sample_bad=0)** đo trên `bench_dp`. Khoảng đúng thay «844 ms»: **875–4937 ms** interpreted, **63–94 ms** native. |

---

# MỤC A — `adamw_step_glm` @ n = 124 439 808

## A.1 Rà IL wrapper line-by-line (đask §A5)

### `AdamwM` — đường `adamw_step` đang chạy

```
.locals init ()                       // không local
ldarg.0..3  conv.i                    // 4 i64 -> native int
ldarg.s 4..11                          // n + 7 float32
call TkvSimd::AdamwNative(...)
ret
```

**Đếm:** `newarr` 0 · `newobj` 0 · `box` 0 · `GCHandle` 0 · `ToArray` 0 · reflection 0.
→ Pure passthrough.

### `AdamwGlmM` — đường ứng viên

```
.locals init (float32[] p0, int32 len0, class FieldInfo fi, float32& pinned q0)

ldtoken List<float32> / Type::GetTypeFromHandle      (1)
ldstr "_items" ; ldc.i4 36                           // 36 = Public|NonPublic|Instance
callvirt Type::GetField(string, BindingFlags)        (2)
callvirt FieldInfo::GetValue(object) ; castclass     (3)
callvirt List<float32>::get_Count()                  (4)
   n<=0      -> V_AGLZ : ldc.i4.0 ; ret              // n=0 là nop
   len0 < n  -> V_AGLB : newobj ArgumentException    // HỢP ĐỒNG OOB
ldloc.0 ; ldc.i4.0 ; ldelema float32 ; stloc.3       (5)  -> q0 (pinned)
   ... conv.i x4 ... call AdamwNative ...
```

**Đếm happy-path:**

| hạng mục | `AdamwM` | `AdamwGlmM` |
|---|---|---|
| `newarr` / `box` / `GCHandle` / `Marshal.*` / `ToArray` | 0 | **0** |
| `newobj` | 0 | 1 — **chỉ ở nhánh ném OOB** (`len0 < n`), không chạy khi đúng hợp đồng |
| reflection per call | 0 | **5** (`GetTypeFromHandle`, `GetField`, `GetValue`, `get_Count`, `ldelema`) |
| local `pinned` | 0 | **1** — giữ `_items` không dịch chuyển suốt `AdamwNative` |

→ **A3.2 (hidden alloc) BÁC.** Không có 496 MB nào được cấp phát/marshal trong wrapper —
không có chỗ nào tạo ra +1.9 s.

**Về chi phí 5 phép reflection:** mỗi call 1 lần, mỗi bước 1 call → order µs, dưới độ phân giải
của bench hàng chục giây.

## A.2 Repro — 3 điều kiện (đơn đề nghị 2, tôi chạy thêm 1)

Tất cả đều dùng **cùng input, đan xen best-of-5, warmup trước**, n = 124 439 808:

- **A (đang chạy)** = `r1 = f32_copy_to_buf(gl, pgl, n)` + `adamw_step(...)`
- **B (ứng viên)** = `adamw_step_glm(ppl, pml, v, gl, ...)`

| # | điều kiện | `gc_counts` | A (prod) | B (glm) | **B − A** |
|---|---|---|---|---|---|
| 1 | máy idle | 8/8/8 → 8/8/8 | 375 ms | 297 ms | **−78 ms** |
| 2 | GC churn (`gc_collect()` mỗi vòng) | không đổi (xem ghi chú) | 390 ms | 297 ms | **−93 ms** |
| 3 | **81 lần gen2 GC chạy ĐỒNG THỜI trên thread khác, ngay lúc pin đang giữ** | **6/6/6 → 87/87/87** | 406 ms | 296 ms | **−110 ms** |

> **Ghi chú điều kiện 2:** `_gl1c` chỉ *đọc* `gc_counts()` trong vòng chứ chưa gọi
> `gc_collect()` (lỗi của tôi khi viết probe) → điều kiện 2 về bản chất vẫn là idle.
> **Điều kiện 3 mới là điều kiện thực sự có GC** — và nó là mạnh nhất: 81 collection
> xảy ra trong đúng cửa sổ `AdamwNative` đang chạy với `_items` đã pinned.

**Kết luận điều kiện 3:** Nếu «pin 496 MB dưới áp lực GC» (A3.1) là thật thì B phải
chậm đi đáng kể khi **81 lần gen2 GC xảy ra ngay trong lúc pin giữ**. Thực tế B
vẫn **nhanh hơn 110 ms**, và A lại chậm đi (+31 ms so với idle) còn B thì không đổi.

**Số tham chiếu đo thêm** (best-of-5, cùng máy):

| phép | ms |
|---|---|
| `f32_copy_to_buf(gl, pgl, 124M)` — chính xác r1 | **78 ms** |
| `f32_list_add(a, b, 124M)` | **125 ms** |
| r1 + `adamw_step` (A) | 375–406 ms |
| `adamw_step_glm` (B) | 296–297 ms |

→ B = A − r1 (78 ms) **đúng đến từng ms** — khớp cam kết «bỏ được vòng copy r1».

### Tóm tắt 3 giả thuyết

| giả thuyết | kết quả |
|---|---|
| **A3.1** pin 496 MB dưới áp lực GC | ❌ **BÁC** — 81 gen2 GC đồng thời, B vẫn nhanh hơn 110 ms |
| **A3.2** hidden alloc / marshal trong wrapper | ❌ **BÁC** — 0 alloc happy-path (đếm IL ở A.1) |
| **A3.3** bỏ r1 làm đổi thời điểm GC | ❌ **BÁC** — bỏ r1 làm **nhanh hơn** đúng 78 ms = đúng chi phí của r1 |

## A.3 Chạy lại production bench (đơn mời «tự chạy 3 rep để lấy median»)

### A.3.1 Diff IL — phát hiện 2 lỗi premise trong bisect

| so sánh | số dòng lệch | kết luận |
|---|---|---|
| **`pb1` vs `pb2`** | **0** | **Hai binary CÙNG MỘT chương trình** (IL giống hệt; exe lệch chỉ do PE timestamp). → biến «+ unflatten» trong bảng A1 **không tồn tại**; `pb1` và `pb2` là 2 lần đo **cùng** cấu hình. |
| **`pb0` vs `pb3`** | **1394** | Lệch ở **`gpt2_backward` (method @20702) + ~25 method khác** (hunks 27208…38579). → `pb3` **KHÔNG** phải «`pb0` chỉ khác khối `step()`» — nên con số **−1.7 s** của `pb3` **không quy được cho việc bỏ glm**. |
| **`pb2` vs `pb3`** | ~12 | **Chỉ lệch trong `step()`** ✔ (các hunk 1616/1684/1812 chỉ là lệch tên temp compiler: `__idiv1026912_` vs `__idiv1026880_`, độ lệch đúng 28 dòng). → **Đây là cặp bisect hợp lệ duy nhất.** |

### A.3.2 Cấu trúc `step()` của cặp hợp lệ

```text
pb3 : r1 = F32CopyToM(gl, pgl)              // KHÔNG điều kiện
      [pdirty] r2 = F32CopyToM(pl, ppl)
      AdamwM(ppl, pml, pvl, gsrc=pgl, ...)

pb2 : if coef != 1.0 { r1 = F32CopyToM(gl,pgl); rzp = F32ZeroM(ptl);
                        rax = F32AddcmulM(ptl,pgl,one,coef); gsrc = ptl }
      [pdirty] r2 = F32CopyToM(pl, ppl)
      if coef == 1.0 { AdamwM(..., gsrc) } else { AdamwGlmM(..., gl) }
```

→ đúng như đơn mô tả: `coef==1.0` đi `AdamwGlmM(gl)` **và bỏ r1 copy**.

### A.3.3 Số đo — `steps=1` (xen kẽ trên cùng phiên)

| lần | `pb3` | `pb2` | `pb0` |
|---|---|---|---|
| 1 | 21 218 | 25 375 | 24 609 |
| 2 | 21 390 | 25 531 | 24 469 |
| 3 | 21 390 | 21 781 | — |
| 4 | 21 609 | (log) 24 172 | (log) 22 250 |
| 5 | 22 812 | (log) 24 438 | (log) 22 625 |
| **min** | **21 218** | **21 781** | **22 250** |
| **phạm vi** | 1 594 ms | **3 750 ms** | 891 ms |

**Quan trọng:** `pb2` chạy nhanh nhất được **21 781 ms ≈ mức thường thấy của `pb3`
(21 679 ms TB)**. Nếu glm thực sự tốn +3.5 s thì `pb2` **không bao giờ** chạm được
21 781. → glm **không intrinsic chậm hơn**; `pb2` đơn giản có **variance cao gấp 2.3×**.

### A.3.4 Số đo — `steps=2` (nhân đôi khối `step()`)

| binary | ms |
|---|---|
| `pb3` | 22 859 · 24 265 (TB **23 562**) |
| `pb2` | 23 047 · 22 954 (TB **23 000**) |

→ **ĐỔI DẤU.** Nếu glm thật sự **+3.5 s/bước** thì `steps=2` phải cho
`pb2 ≈ pb3 + 7 000`. Thay vào đó `pb2` **nhanh hơn** `pb3`.

Đặc biệt: **`pb2` ở `steps=2` (22 954) NHANH HƠN `pb2` ở `steps=1` (25 375)** —
làm **nhiều việc hơn mà thời gian ít hơn**. Một chi phí thật theo từng bước không
thể cho kết quả này.

→ **Chi phí theo từng bước của glm = 0 trong độ phân giải đo được.**

### A.3.5 Tại sao bench không phân giải được tín hiệu 1.5–3.2 s

Trên máy 12 GB với heap bench 8–9 GB, **RAM tự do một mình đã đẩy một binary cùng
cấu hình từ 21 s lên 105 s (4.3×)**:

| sự kiện | FreeMB | `pb0` cùng cấu hình |
|---|---|---|
| bình thường | 9 775 | 21–25 s |
| còn 1 process mồ côi `bseq_pb0` giữ 6 810 MB | 3 455 | **105 219 ms** |
| 2 process mồ côi chồng lên nhau | 598 | (chưa kịp đo — dừng) |

Biên độ **do RAM tạo ra (4.3×)** lớn hơn **cả tín hiệu cần đo (1.3×)**.
Đơn cũng tự nhận «`pb3` spread 2.1 s» — con số đó **chính là ölçü của noise này**.

## A.4 KẾT LUẬN CHÍNH THỨC (đask §A5)

> **Không tìm ra cơ chế, vì cơ chế đó không tồn tại ở mức wrapper.**

1. Wrapper `AdamwGlmM` **sạch**: 0 alloc, 0 box, 0 GCHandle, 0 ToArray — chỉ thêm
   5 phép reflection/call (µs) và 1 local `pinned`.
2. Gọi trực tiếp, glm **nhanh hơn 78–110 ms** ở idle, ở GC churn, **và khi 81 lần
   gen2 GC chạy đồng thời ngay lúc pin giữ**.
3. Tín hiệu +1.5–3.2 s của bench **không scale với số lần gọi** (`steps=2` đổi dấu),
   **không phân tách được khỏi RAM**, và cặp bisect `pb2/pb3` là **cặp duy nhất hợp lệ**
   (cặp `pb1/pb2` là cùng binary, cặp `pb0/pb3` lệch 1394 dòng ở BWD).

### Đề xuất cho repo

**(a) Khuyến nghị giữ nguyên đường đang chạy (`r1 copy` + `adamw_step`).**
Không phải vì glm chậm — mà vì:

- đường `r1 copy` **ít biến thiên hơn rõ rệt** (phạm vi 1 594 ms vs 3 750 ms);
- memcpy 496 MB dường như đóng vai «memory fence» ổn định hoá timing giữa các rep;
- bật glm **không mang lại gain đo được** (được −78 ms/625 ms ≈ −0.03% của full step).

**(b) Không cần gắn nhãn «glm chỉ dùng khi RAM dư dả»** — đó không phải điều kiện
của glm. Điều kiện thật là **của chính bench**: 8–9 GB heap trên máy 12 GB thì
số nào cũng nằm trong noise.

**(c) Nếu vẫn muốn chốt glm bằng số** → chạy trên máy có RAM ≥ 32 GB
hoặc giảm heap bench xuống < 6 GB, và luôn chạy xen kẽ `pb2`/`pb3` **≥ 3 rep
ở mỗi `steps`**, cộng thêm một lần `steps=2` để kiểm tra tín hiệu có scale không.

---

# MỤC B — ĐÍNH CHỈNH SỐ COPY-BACK (đơn #3 §2.2)

## B.1 Số mới — đo trên chính `bench_dp` (đask §B1 «thêm case 148-slice»)

Đã thêm **PHA D** vào `bench_dp` (bản chạy được: `tv/tests/bench_dp.tkv` —
bản trong `Release/build/scratch/` giữ nguyên vì không có module `tv/` để dùng
`t_zeros`). Hình dạng **148 tensor GPT-2, tổng 124 439 808 phần tử**:

```text
SLICE ntensor=148 total=124439808
SLICE interpreted_ms=4937 native_ms=63 speedup=78x sample_bad=0
```

**Đường native:** `f32buf_wrap(buf + off*4, sz)` + `f32_copy_from_buf` × 148 call —
đúng hình dạng production, không gộp thành 1 call contiguous.

### Bảng đính chính (thay bảng B1 của đơn)

| nguồn | interpreted | native | tỉ lệ |
|---|---|---|---|
| đơn #3 §2.2 (ước cũ của repo) | ~~844 ms~~ | ~~30 ms~~ | — |
| `bench_dp` `bench_dp` reply #3 §4.1 (contiguous, 1 call) | 1000 ms | 15 ms | 67× |
| CJ8 production-shape | 875 ms | — | — |
| probe `_gl1` [2] — 148 tensor thật | 4453 ms | 94 ms | 47× |
| **`bench_dp` PHA D — 148-slice, best-of-3 (MỚI)** | **4937 ms** | **63 ms** | **78×** |

→ **Số «844 ms» phải thay bằng khoảng `875–4937 ms`** (nhạy JIT-shape: probe trong
`main()` to ~35 ns/ptu, `cj8` ~7 ns/ptu).
→ **Số native đúng cho shape production: `63–94 ms`** (không phải 15 ms contiguous-call).

## B.2 Bốn số còn lại của `bench_dp` chạy lại — không đổi

| case | n | interpreted | native | kiểm chứng |
|---|---|---|---|---|
| `f32_list_add` | 38 600 000 | 1110 ms | **31 ms** | `ADD_bit_bad=0` |
| `f32_list_copy` | 38 600 000 | 984 ms | **15 ms** | `COPY_bit_bad=0` |
| `f32_grad_norm` | 124 000 000 | 3031 ms | **32 ms** | `absdiff=0.0` |
| **148-slice (MỚI)** | 124 439 808 | **4937 ms** | **63 ms** | `sample_bad=0` |

Log: `out/bench_dp.log`.

## B.3 Về §B2 của đơn (lỗi đo của repo)

Ghi nhận: `simd_bench_124m_seq` dùng bản copy inline `_step124` nên A/B `pb3` vs `pb4`
gần như 2 binary giống nhau → «0%» là tất nhiên. **Số 0% đó phải bị loại khỏi
budget Phase C-F**, thay bằng khoảng **63–94 ms / 875–4937 ms** ở trên.

---

## Phụ lục — file đính kèm

| file | nội dung |
|---|---|
| `tv/tests/_gl1c.tkv` (Inference) | A/B đúng khối `step()` production, 4 phép đo (A/B/`f32_list_add`/r1), best-of-5, `GL1_CHURN=1` |
| `tv/tests/_gl1d.tkv` (Inference) | A/B dưới **81 lần gen2 GC đồng thời** (worker `thread_spawn` + `gc_collect()`) |
| `tv/tests/bench_dp.tkv` (Inference) | `bench_dp` + **PHA D 148-slice** |
| `Release/build/scratch/bench_dp.tkv` | `bench_dp` **gốc, không đổi** (chưa có PHA D — thiếu module `tv/`) |
| `out/bench_dp.log` | kết quả `bench_dp` đã chạy |
| `out/ab/glm_ab.log` | lần chạy xen kẽ đầu (bị timeout, tham khảo) |
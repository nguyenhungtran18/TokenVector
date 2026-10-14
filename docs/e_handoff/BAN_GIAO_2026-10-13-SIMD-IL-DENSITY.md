# BÀN GIAO 2026-10-13 — SIMD / siết IL / perf gate

## 0. TRẠNG THÁI: công việc đã xong, mọi gate xanh

```
vong             IL_IDENTICAL
testkit_gate     122/122  BUILDFAIL=0 TESTFAIL=0 ILFAIL=0 NEG=31/31
dang_ky_gate     PASS (0 vi phạm)
lint_rules_gate  PASS (8/8, 0 false positive)
ext_smoke        PASS (4/4)
perf_gate        PASS
```

Working tree: 4 file compiler sửa + 3 file mới + submodule `compiler_py` có 1 thay đổi chưa commit.
**Không có file rác.**

---

## 1. ĐÃ LÀM XONG (đã kiểm chứng — KHÔNG làm lại)

### 1.1 Hai bug `int_narrow` — đã sửa
Cùng một căn: `compile_binop` trả kết quả **không nở về `dtype` ngữ cảnh**.

- **Bug 1** (`int64 × float` → 0): nhánh `//` và `%` thiếu `widen_if_needed`.
  `(i % 7) * 0.5` cho `2.5e-316` thay vì `1.5`.
  → `operators.tkv`: thêm `ctx.widen_if_needed(operand_dtype, dtype, out)` trước `return`.
- **Bug 2** (thiếu `conv.ovf.i4`): `_widen_if_needed` **thiếu nhánh `i64 → i32`**.
  `r[k * 2] = v` đẩy `int64` thẳng vào `set_Item(int32)` → IL sai kích thước stack.
  → `il_codegen.tkv`: thêm nhánh `conv.ovf.i4`; `operators.tkv`: nở ở nhánh `+ - *`.

**Hai test hồi quy (đã chứng minh bắt được bug, không phải xanh vờ):**

| file | khi revert sửa đổi |
|---|---|
| `tests/int64_mixed_float_test.tkv` | **11/13** (fail 2) |
| `tests/int64_index_store_test.tkv` | **7/8** (fail 1) |

> **Quan trọng**: test dùng **tham số `"i64"`**, KHÔNG dùng `k: "i64" = 3` — vì
> `tkvc.exe` (phía Python) **từ chối** khai báo local có kiểu. Tham số chạy được cả 2 compiler.
>
> Ca bắt bug 2 phải dùng `2^32`: chỉ số nhỏ vừa khít int32 nên bản lỗi và bản
> sửa cho **cùng** kết quả, và CLR JIT không verify IL. Chỉ có tràn int32 mới
> phân biệt được — bản lỗi ghi âm thầm vào `r[0]`, bản sửa ném `OverflowError`.

### 1.2 `int_narrow` bật lại
`int_narrow.tkv` có `narrowable_locals` chạy đúng. Thiết kế **thận trọng có chủ đích**:
- Chỉ `+` `-` và unary `-`. **KHÔNG có `*`**, vì `x = x * 2` trong vòng lặp
  làm tràn i64 sau ~63 vòng (Python trả BigInteger chính xác, bản thu hẹp ra rác).
- `for`-var chỉ dùng làm **su kiểm** cho `_expr_int64`, KHÔNG đưa vào tập kết quả
  (nó đã là i32 sẵn, đổi sang i64 chẳng lời gì).
- Kiểm tra literal bằng **đếm chữ số + so sánh từ điển** (`int_builtin._int_fits_i32`),
  vì `int(s, 0)` bị chặn lúc biên dịch và `int()` trả i32 nên ném với số lớn.
- Biến đếm `for` là i32 (`declare_scalar_int`) — `while`-counter mới là TkvInt nên được narrow.

### 1.3 Siết khuôn `compile_binop`
Vòng nóng matmul32: **36 → 32 lệnh/MAC**, `conv.ovf.i4` **10 → 1**.

Nguyên nhân: truyền `dtype` ngữ cảnh xuống *từng toán hạng*, nên `i * n + kk`
(i, n, kk đều i64, ngữ cảnh i32) bị hẹp 3 lần/phép.

→ `operators.tkv` + `il_codegen.tkv`: thêm nhánh `i32 → i64` (`conv.i8`) vào
`_widen_if_needed`; `compile_binop` tính ở `khuon_dt` (khuôn rộng nhất) rồi hẹp **một lần**.

**Kết quả KHÔNG đều** — phải đọc kỹ:
| kernel | trước | sau |
|---|---|---|
| matmul32 | 212.1 µs | **195.1 µs** (−8%) |
| f32mm | 142.5 µs | **156.8 µs** (+10% tụt) |

`f32mm` tụt vì `_mm` có `n: "i32"` còn `i`/`kk` là i64 → `conv.i8` cho `n` **mỗi MAC**,
trước đây nó i32 sẵn không cần ép. Gate cũ **không bắt** → ra đời perf gate.

### 1.4 Perf gateway (việc đáng giá nhất về mặt quy trình)
`tools/perf_gate.ps1` + `tools/perf/{perf_mm,perf_f32mm,perf_e2e}.tkv` + `baseline.txt`

- So với **chính nó qua thời gian** — KHÔNG so CPython/NumPy (cái đó ở repo TestOracle).
- Exit code ≠ 0 hoặc checksum lệch ⇒ fail ngay.
- Chậm quá **7%** ⇒ `exit 1`. `-Update` để nạp lại baseline, `-ThreshPct` đổi ngưỡng.
- **Đã kiểm chứng bắt được**: baseline nhồi +25% → báo "nhanh hơn 22%" (đúng hướng);
  baseline hạ → `TUOT 73–76%` và **exit 1**.

Đã khai báo trong `CLAUDE.md` (mục Performance Gate, ngay trước Acceptance Gate).

### 1.5 `aggressiveinlining` — đường `v_*8` (con số 2.11x ĐÃ BỊ ĐO LẠI)
Cùng một phép AXPY, checksum khớp tuyệt đối (`2778491.4497380257`):

| | |
|---|---|
| scalar `list[f32]` | 11.78 ms |
| 8-lane `v_*8` **có** `aggressiveinlining` | **5.58 ms** (2.11x) |
| 8-lane `v_*8` **không** có (lần thử trước) | **chậm hơn scalar 25%** |

Lý do: thân method ~60 byte IL vượt hạn inline mặc định của JIT (~32 byte) → mỗi phép
là một CALL. `cil managed aggressiveinlining` nới hạn ngưỡng. Đúng một dòng.

> ⚠ **ĐO LẠI 2026-10-14 — con số 2.11x SO VỚI `list[f32]`, KHÔNG phải so với
> native scalar.** Cả hai cùng đọc/ghi bộ đệm native, cùng 1 M phần tử f32:
>
> | | ms (best-of-5) |
> |---|---|
> | `v_*8` (8 lane) | 2.35 |
> | **native scalar** (`read_f32`/`write_f32`) | **2.55** |
> | `list[f32]` | 4.47 |
>
> ⇒ `v_*8` nhanh hơn native scalar **1.08x**, không phải 2.11x. Phần lớn
> "2.11x" là do đổi **substrate** (`list[f32]` → native), không phải do 8 lane.
> Nguyên nhân đo được trong IL: `v_load8`/`v_store8` **không hề có lệnh SIMD
> nào** — vẫn là 16 × `ldind.r4` + 8 × `stind.r4` (đọc/ghi từng lane như
> scalar), **213 lệnh IL cho 8 phần tử so với 39** của bản native scalar.
> Cải thiện 1.08x đến từ `aggressiveinlining` cho phep, không từ SIMD.
>
> **Hệ quả cho kế hoạch:** đừng ghi "đường `v_*8` nhanh 2.11x" vào tài liệu
> nữa. Muốn SIMD thật thì phải sửa `vector_block.tkv` phát `ldind`/`stind`
> 32-byte liên tục (`v_load8` hiện ghi 8 field struct), hoặc dùng
> `System.Numerics.Vector<float>` — xem handoff 2026-10-14.

> Lưu ý: kết quả benchmark hầu như **không đổi** sau thay đổi này vì **không kernel
> benchmark nào dùng `v_*8`**. (Đã sửa 2026-10-14: nay có `tools/perf/perf_axpy.tkv`.)

---

## 2. KIẾN TRÚC ĐÃ KHÁM PHÁ (đừng khám phá lại)

### 2.1 Node representation — hai compiler KHÁC NHAU
| | TokenVector (`compiler_bootstrap`) | Python (`compiler_py`) |
|---|---|---|
| node | **int index vào pool chuỗi**, truy cập qua `ekind`/`ea_str`/`eb_nut`/`con_nut` | **tuple** `('binop', op, l, r)` |
| stmt | **i32 row id**, `lay_str`/`lay_nut`/`lay_than` | `dict` `{'kind': ...}` |
| dụng cụ IL | phụ thuộc `ilasm.exe` **.NET Framework** | giống |

`compiler_py/compiler/` **chỉ có 7 file .tkv** — không có `expr_row.tkv`, `stmt_row.tkv`.

### 2.2 Field layout (đã xác minh — dễ lại nhầm)
`KHUON` (expr_layout.tkv): `'binop:1': 'str'` = **toán tử**, o2/o3 = toán hạng.
→ op là **`ea_str`**, KHÔNG phải `eb_str` (tôi đã nhầm, tốn một vòng).

`_LAYOUT` (stmt_row.tkv): `assign_scalar` lưu `rhs_text` nhưng `lay_nut(st,'rhs_node')`
**fallback** sang `rhs_text` — hoạt động được.

### 2.3 Rào chắn ngôn ngữ (đã chạm vào tất cả)
- **`isinstance` không có** trên đường TokenVector. Dùng `la_node`/`ekind`.
- **`int(s, 0)` là lỗi biên dịch** — chỉ nhận cơ sở 2/8/10/16; `int()` trả i32 nên ném với số lớn.
- **Comprehension/generator** chỉ hợp lệ khi là **toàn bộ** RHS của gán **ra tên trần**, một dòng.
- **Statement row là NỘI LUÂN BẤT BIẾN** trong pool — không có `_set_nut`, không sửa được `cond_node`.
- **`global` chỉ hỗ trợ kiểu vô hướng** (i32/i64/f32/f64/str), KHÔNG container/record.
- **Hằng số cấp module**: viết HOA, **không** dấu `_` đầu, và **không** có annotation kiểu —
  có annotation là *biến global*, phải `global` mới đọc được.
- `join`/`split`/module-level container đã gây lỗi "The given key was not present in the dictionary".

### 2.4 `ctx` — 4 lớp KHÁC NHAU (nguồn bug nguy hiểm)
`il_dispatch.tkv`:
| lớp | vai trò | `locals_decl`? |
|---|---|---|
| `Ctx` (dòng 279) | **codegen** | ✅ **đã thêm hôm 2026-10-13** |
| `WalkCtx` (dòng ~835) | first-pass | ✅ có từ trước |
| `GenCtx`, `PrescanCtx` | khác | — |

`ctx` **không phải một kiểu dict** — nhiều trường là handle type. `il_dispatch.tkv:303-308`
liệt kê **cố ý không khai** (`infer_dtype`, `gen_il_function`…) vì `func(...)` arity cố định.

---

## 3. VIỆC DỞ DANG: LICM — biết chính xác con đường, chưa đi được

### 3.1 Bài toán (đã đo, không phỏng đoán)
Vòng nóng hiện 32 lệnh/MAC, còn thừa (loop-invariant):
```
_mm_W3_start:
  ldloc.s 3      ; kk
  ldarg.s 3      ; n
  conv.i8        ; <-- 3 lần mỗi MAC (1 điều kiện + 2 chỉ số)
  ...
  mul.ovf        ; i * n  <- LOOP-INVARIANT!
```
Nhổ đủ: **32 → ~27 lệnh/MAC**.

### 3.2 Tiền đề kiến trúc ĐÃ XONG
`Ctx` giờ có `locals_decl` (`il_dispatch.tkv:354`), khởi tạo `:460`,
thứ tự giữ đúng tham chiếu qua `tao_ctx`/`sao_ctx` (`:568`, `:697`).
**Đây là phần đã xác minh và an toàn — giữ nguyên, đừng hoàn tác.**

### 3.3 LICM ĐÃ VIẾT XONG nhưng KHÔNG CHẠY — 0 dòng `__lib` trong IL
Code đã hoàn tác (`control_flow.tkv` về HEAD). Cách làm đúng:
theo mẫu `_p6_vectorize_while` — **phát truy cấp cả vòng rồi `return 1`**,
KHÔNG sửa `cond_node` (row bất biến, đã thử thất bại).

### 3.4 Việc tiếp theo — CHẨN ĐOÁN, không viết lại từ đầu
Thử **theo thứ tự này**, mỗi bước một:

1. **`ekind(cond)` có đúng `'compare'`?** — dùng `probe` tạm hoặc
   đọc `_compile_cond` trong `control_flow.tkv` xem nó kỳ vọng gì.
2. **`eso_o(compare)` là bao nhiêu?** — `'compare:1/2/3'` = 3 o + kind ⇒ `eso_o = 4`.
   Điều kiện `< 3` của tôi đúng, nhưng cần xác nhận.
3. **`_p6_vectorize_while` có đang chặn trước?** — kiểm tra điều kiện của nó.
4. **`ctx.infer_dtype(...)` trả gì?** — `ve_trai` là `kk`, `ben` là `n: "i32"`.
   `_licm_rong_dt` cần cả hai ∈ {i32, i64}. Nếu một cái `None` thì bail.
5. **`gen_il_function` có THỰC SỰ dùng `ctx.locals_decl` không?** ⚠️ **Nghi vấn mạnh nhất.**
   Ở il_codegen.tkv gần dòng 8397 có:
   ```python
   locals_sig = ', '.join([... for name, ta in locals_decl])
   ```
   dùng biến cục bộ `locals_decl` (từ `_first_pass_collect_locals`),
   **không phải `ctx.locals_decl`**. Nếu hai cái khác object, ghi vào
   `ctx.locals_decl` sẽ **không ra file .il** — khớp đúng triệu chứng "0 dòng `__lib`".
   → Nếu đúng, sửa dòng đó sang `ctx.locals_decl` (hoặc gán trước khi dùng).

**Bắt đầu bằng việc 5.** Đó là điểm nghi ngờ nhất.

---

## 4. ĐO ĐẠC ĐÃ CÓ (đừng làm lại)

### 4.1 Bản đồ headroom
| kernel | toán học | phần còn lại | trần SIMD |
|---|---|---|---|
| matmul32 (f64) | **4%** | 96% = 2×`get_Item` bounds check + chỉ số | **1.03x** |
| add (f64) | ràng buộc bởi **số lệnh** (~16 IL/phần tử, IPC≈2) | — | ~3x |

Phân rã `add`: elementwise **69.2%**, rút gọn **30.8%**.

### 4.2 Route B (CoreCLR) — đã kiểm chứng, KHÔNG phải phỏng đoán
| câu hỏi | kết quả |
|---|---|
| CoreCLR JIT có SIMD hóa raw operator không? | **Có** — `Vector256.IsHardwareAccelerated = True` |
| Hiệu quả matmul thật (256³, có bounds check) | **4.97x**, checksum khớp tuyệt đối |

> **Bẫy đã mắc**: đo ra `0.25 µs/matmul` (vô lý). Hai lần do JIT:
> (1) **dead-code elimination** — `r` được ghi mà không ai đọc;
> (2) **hoisting** — pure function của static field không đổi ⇒ nhổ khỏi vòng đo.
> Chỉ khi `N=256` **và** làm dữ liệu thay đổi mỗi lần đo mới ra số đúng.

**Blocker**: không có compiler C (`gcc`/`clang`/`cl`/`tcc`) cho đường P/Invoke native;
và ilasm hiện chỉ của .NET Framework, máy có CoreCLR 8/9 nhưng **không có ilasm cho nó**.

### 4.3 SIMD thật sự của TokenVector
- `f32x4` = `System.Numerics.Vector4` qua `call op_*` → **method call thật**, không phải SIMD.
- **Raw CIL `add`/`mul` trên `Vector4` → `SEHException`.** Đã thử, đã hoàn tác,
  ghi lại kết quả âm trong `vector4_type.tkv` (chỉ comment).
- `v_*8` chỉ có **một thanh ghi ngầm**, `v_load8` ghi đè accumulator,
  `v_mul8_add8(x,y)` nhận **vô hướng** ⇒ **không diễn đạt được `acc + va*vb`**.
  Vốn dành cho AXPY, **không thay được `f32x4` cho matmul**.
- **P6 auto-vectorizer đã tồn tại** (`_p6_vectorize_while`, `control_flow.tkv:1227`)
  nhưng chỉ cho `f32buf` + một dạng vòng `r[i]=a[i]+b[i]` — và đi qua `f32x4`.
- Sau khi `int_narrow` chạy, `f32mm_vec` **nhanh hơn scalar 3.3x**. Nghĩa là đường SIMD
  vốn hoạt động, chỉ bị giấu dưới overhead TkvInt.

---

## 5. VIỆC CÒN DỞ

| việc | ghi chú |
|---|---|
| Chẩn đoán/hoàn thành LICM | Bước 1 là việc 5 ở mục 3.4 |
| `compiler_py` đồng bộ | ~~chưa có thay đổi `compile_binop` mới nhất~~ **ĐÃ ĐÓNG 2026-10-14: chủ repo dừng phía `compiler_py`.** Đừng làm việc này nữa |
| Kernel AXPY vào benchmark | ~~`v_*8` nhanh 2.11x~~ **XONG 2026-10-14**: thêm `tools/perf/perf_axpy.tkv`. Nhưng con số 2.11x đã bị đo lại thành **1.08x** — xem mục 1.5 sửa ngay trên |
| Perf gateway nhạy hơn | dao động ~3-4%; ngưỡng 7% chỉ đủ bắt ≥10%, không bắt được 3-5%. Tăng `-Runs` hoặc khóa CPU nếu cần |
| Bỏ bounds check (`f32buf`) | theo đo đạc là **96%** thời gian matmul32 — tiềm năng lớn nhất |

---

## 6. LƯU Ý VẬN HÀNH

- **Luôn chạy `tools\vong.exe` sau khi sửa compiler_bootstrap**, và chạy **lại cho tới
  khi `IL_IDENTICAL`**. Gặp `IL KHAC NHAU` là bình thường (đó là **tiến hoá** — vong tự
  nâng cấp `tv2s`); chạy lại một vòng nữa.
- ~~Cần **`dist\tkvc.exe`** để chạy các gate cần Python; sửa `compiler_py/` thì **phải
  build lại** bằng `compiler_py\build_tkvc.ps1` — không build thì gate đang đo compiler cũ.~~
  **KHÔNG CÒN ĐÚNG (2026-10-14):** `parity_probe` và `ext_smoke` đã bỏ khỏi
  danh sách gate; `tkvc-tv.exe` là compiler duy nhất.
- Đổi `compiler_bootstrap/compiler/bootstrap_all.tkv` thì kiểm tra **có thể tạo `__tkv_import__`
  trùng tên** — dùng tên biệt danh (ví dụ `compile_binop_vector4`).
- Trước khi ghi một file `compiler/il_features/`, kiểm tra **đừng ghi đè module đang sống** —
  từng gặp vì vậy mà mất 104/104 file.

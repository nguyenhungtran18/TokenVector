# COMPILER BUGS — Báo lỗi tkvc (2026-09-20)

> **Cập nhật 2026-09-21:** đã vá 2 gap đa luồng của KERNEL_LAB 6.2 (worker trả
> `list[T]` — first-pass/codegen giữ nguyên TypeAnn thay vì dtype trần; worker
> là hàm lồng — `thread_spawn` dùng đúng delegate instance của closure class bọc
> trong `Task.Factory.StartNew`). Probe `_probe_thread.tkv` PASS; benchmark
> `bench_thread_real8.tkv` đạt 13.2 ms @5M output thật (8 workers) — mở khóa
> đa luồng sinh output thật của engine (xem BENCHMARKS.md mục 1a bên
> TokenVector.Data). Còn sót BUG-4 bên dưới.

## BUG-4: Closure bắt list local — first-pass không thấy biến bị bắt khi index (MỚI, 2026-09-21)

**Triệu chứng:** hàm lồng `nonlocal` một list local rồi **index** nó trong vòng
lặp (`inp[i]`) → `SyntaxError: bien 'inp' chua duoc khai bao/tham so` lúc compile.
Gọi closure TRỰC TIẾP hoạt động đúng (probe tách riêng PASS) — lỗi chỉ ở đường
first-pass suy shape cho BIỂU THỨC INDEX trên biến bị bắt (var capture vẽ chưa
vào infer_scope của ngữ cảnh suy dtype index). Ảnh hướng: worker đa luồng không
đọc được cột thật qua closure (phải sinh dữ liệu inline trong worker).

**Repro:** `tvsrc/_probe_cap.tkv` (D:\TokenVector.Data) — closure bắt
`inp: list[f64]`, thân `for i in range(3): s = s + inp[i] * 2.5 + inp[i]`.

**Hướng vá:** nơi suy dtype node 'index' cần tra infer_scope của HAM NGOAI cho
các tên trong capture-set của closure hiện tại (giống cách closures.py vẽ
nonlocal vào closure class), hoặc đơn giản hơn: first-pass khi xử lý `nonlocal`
trong ham long thì copy TypeAnn của biến ngoài vào scope suy luận cục bộ.

Phát hiện khi tối ưu thư viện TokenVector.Data (Welford 1-pass). Tất cả đều có
repro tối thiểu < 10 dòng. Thứ tự theo mức nguy hiểm.

---

## BUG-1: `int_var * float_literal` → crash hoặc giá trị rác (NGHIÊM TRỌNG)

**Triệu chứng** (2 dạng):
1. Crash: `ValueError: invalid literal for int() with base 10: '0.5'` tại
   `int_type.compile_literal` dòng 129.
2. Im lặng sinh giá trị rác khi toán hạng int là biểu thức trong vòng lặp
   (`1.0 + (i % 7) * 0.5` lưu vào buffer 5M phần tử → mỗi giá trị =
   `(i%7) * 43920888 + 1.0` thay vì `(i%7) * 0.5 + 1.0`).

**Repro:**
```python
def main() -> "str":
    k = 3
    v = k * 0.5        # crash, kỳ vọng 1.5
    print("v=", v)
    return "ok"
```

**Gốc:** `operators.compile_binop` suy
`operand_dtype = left_dtype or right_dtype or dtype` — `left` là biến int
nên `operand_dtype='int'`, rồi compile toán hạng PHẢI (num `0.5`) với
dtype='int' → rơi vào `int_type.compile_literal` → `int('0.5')` crash.
Helper `_contains_float_literal` đã tồn tại ở il_codegen (dùng cho
`compare` qua `_resolve_compare_operand_dtype`) nhưng KHÔNG được dùng cho
`binop`.

**Fix (đã áp):** trong `operators.compile_binop`, ngay sau khi suy
`operand_dtype`: nếu int-family và có float literal ở 1 trong 2 vế →
promote `operand_dtype = 'f64'` (widen một chiều, đúng ngữ nghĩa Python).
Đi kèm helper `_float_literal_in` bản local trong operators.tkv (tránh
import ngược il_codegen từ plugin LIBRARY).

---

## BUG-2: `float(counter)` trong vòng lặp trả 0.0 im lặng (NGHIÊM TRỌNG)

**Triệu chứng:** biến đếm kiểu `'int'` (TkvInt struct) truyền vào `float()`
→ codegen rơi nhánh generic `conv.r8` TRÊN STRUCT → đọc 8 byte đầu của
struct (object ref null) → luôn = 0.0. Hệ quả: phép chia cho `float(cnt)`
→ `mean = inf` am thầm.

**Repro:**
```python
def main() -> "str":
    fb = [1.0, 2.0, 3.0, 4.0]
    cnt = 0
    mean = 0.0
    for i in range(4):
        x = fb[i]
        cnt = cnt + 1
        fc = float(cnt)
        mean = mean + x / fc
    print("mean=", mean)   # in "inf", kỳ vọng 2.5
    return "ok"
```

**Gốc:** `float_builtin.push_float_builtin` xử lý `str/f64/None`, phần còn
lại (gồm `'int'`) rơi `conv.r8` — đúng cho i32/i64 nhưng SAI cho `'int'`
(struct TkvInt). Cơ chế `TkvInt::ToF64` đã có sẵn trong int_type.tkv
(dòng ~460) nhưng chưa được nối.

**Fix (đã áp):** `push_float_builtin` thêm nhánh `src == 'int'`:
`compile_expr(arg, 'int')` + `call float64 TkvInt::ToF64(valuetype TkvInt)`.

---

## BUG-3: Gán lại local theo kiểu khác → crash compiler hoặc rác (VỪA)

**Triệu chứng:** local đã khai kiểu này, gán lại giá trị kiểu khác:
- `a = [1.0, 2.0, 3.0]` rồi `a = [4, 5]` → build crash `KeyError: 'str'`
  (từ `_expr_num`/`_compile_cond` — repro cần cô lập thêm vì `if True:`
  trong test cũ cũng dính lỗi suy luận riêng).
- Dạng production thật: 1 biến local dùng chung cho 2 buffer khác kiểu
  (`ib = s.i64s` ... `fb = s.f64s` TÁI DÙNG TÊN `buf`) → đọc bit pattern
  sai (1.0 đọc thành 4.6e18) im lặng.

**Gốc:** mô hình local của DSL = 1 tên 1 kiểu (suy từ lần gán đầu). Gán
lại lệch kiểu hiện không bị chặn, sinh IL sai kiểu ngầm.

**Fix (đã áp, guard hẹp theo HƯỚNG nguy hiểm):**
- Scalar: `_stmt_assign_scalar` (il_codegen) — local int-family
  (i32/i64/int) gán lại RHS chứa float literal → SyntaxError rõ ràng
  (trước đây crash `ldc.i4 2.0` kiểu ilasm-invalid).
- List: guard `check_list_retype` expose qua ctx, gọi từ plugin
  `list_type.codegen_assign_list_literal` — local list phần tử int-family
  gán lại list_literal có phần tử FLOAT → SyntaxError rõ ràng (hướng này
  trước đây crash `int('0.5')`). Hướng NGƯỢC (list f64 ← phần tử nguyên)
  là widen an toàn, codegen đã xử lý đúng (in 4.0) → GIỮ nguyên.
- Ghi chú: dtype literal nguyên suy qua `_infer_literal_dtype` là `'int'`
  (struct TkvInt), KHÔNG phải `'i32'` — guard phải tính cả `'int'`

---

## Regression tests (đã chạy xanh trên tkvc build 2026-09-21)

- `bug_int_float_mul_test.tkv` (entry `run`): 4/4 PASS — int*float literal,
  vòng lặp `(i % 7) * 0.5`, `0.5 * 4`.
- `bug_float_counter_test.tkv` (entry `run`): 2/2 PASS — `float(cnt)` với
  cnt là `'int'` (tổng = 4.0), `float(n)` trực tiếp.
- `bug_local_retype_test.ps1` (PowerShell runner): 3/3 PASS —
  `bug_local_retype_list.tkv` (int-list ← float elems, phải bị TỪ CHỐI),
  `bug_local_retype_scalar.tkv` (int ← 2.0, phải bị TỪ CHỐI),
  `bug_local_retype_widen.tkv` (f64-list ← int, phải VẪN CHẠY = 4.0).
- Smoke không regress: bytes, counter, complex, dict_update, divmod,
  defaultdict, context_manager, datetime_ticks, bytearray — toàn PASS.

**Bài học build:** sửa file trong `compiler/` (CORE) phải rebuild lại
tkvc.exe (`build_tkvc.ps1`) — CORE bị PyInstaller nhúng BÊN TRONG exe,
plugin_loader bỏ qua bản trên đĩa. Riêng nhóm LIBRARY
(`dist/il_features/*.tkv`) nap động lúc chạy, chỉ cần copy qua `dist/`.

# SESSION HANDOFF — TokenVector compiler

Ngày: 2026-09-29. Cổng: **90/90 + negative 9/9 xanh** tại commit `93fcd18`.

**CÓ VIỆC DỞ DANG, CHƯA COMMIT.** Xem mục 3 trước khi làm bất cứ việc gì.

---

## 1. Bối cảnh: tập trung compiler, hoãn repo khác

Chỉ sửa `3.code`. `TokenVector.Inference` và `TokenVector.Data` đang **không build**
vì quy tắc "record không được có field container chưa khởi tạo" (lý do có chủ đích,
người dùng đã chọn phương án B: cho phép nếu có `self.X = ...` trong `__init__`).
Việc sửa hai repo đó **đã được hoãn có chủ đích** — đừng đụng vào.

`docs/SO_SANH_TOKENVECTOR_VS_PYTHON.md` còn khẳng định hỗ trợ `iter()`/`next()` —
**sai**, hai hàm đó không tồn tại. Nên sửa tài liệu, để sau.

---

## 2. Xong trong phiên này (mỗi cái một commit, đã mirror cả hai repo)

| Feature | `3.code` | parent | Test |
|---|---|---|---|
| Chuỗi tam nháy nhiều dòng `"""..."""` | `fedce3b` | `694f5ef` | `multiline_string_test.tkv` 8/8 |
| `yield from` + `return <v>` trong generator | `97b2dd1` | `a2f9a86` | `generator_yield_from_test.tkv` 10/10 |
| Literal lồng `[{"a":1}]`, `{"k":[1,2]}` | `549dbc7` | `a998f02` | `nested_literal_test.tkv` 7/7 |
| Linter chấp nhận literal lồng | `2f85d29` | `0e2fe11` | — |
| Tuple literal `(1, 2)` — phần 1/2 | `93fcd18` | `5294746` | `tuple_literal_test.tkv` 5/5 |

Cộng 2 negative test mới (`yield_from_bad_source`, `generator_return_no_gen_ret`).

**Quy tắc commit:** mỗi thay đổi commit vào **cả hai** repo, chạy gate trước khi commit.

---

## 3. ⚠ VIỆC DỞ DANG — đọc trước khi sửa

Working tree (`3.code`) đang sửa 2 file, **chưa commit vì sinh ra IL không hợp lệ**:

```
 M Testkit/tuple_literal_test.tkv      # 2 check `for a, b in ...` đã bật lại
 M compiler/il_features/tuple_type.tkv # thêm try_parse_for_tuple_pairs
                                       # fpw_for_tuple_pairs
                                       # codegen_for_tuple_pairs
```

**Triệu chứng:** `tuple_literal_test` build được, 5 case literal vẫn PASS, nhưng
`sum_pairs()` và `join_pairs()` chết lúc chạy với
`System.InvalidProgramException: Common Language Runtime detected an invalid program`.

**Nguyên nhân đã định vị chính xác** (dùng `TKV_DBG_NARROW=1` có sẵn):

```
plain     (for thường):     for_targets=['__iterexpr0_idx']  assigned=['i','total']  → total = TkvInt, OK
sum_pairs (for_tuple_pairs): for_targets=[]                   assigned=['total']     → total = int64, HỎNG
```

`int_narrow` (`compiler/il_features/int_narrow.tkv`, `narrowable_locals` L217) đánh giá
biến qua 2 nguồn: tên trong `assigns` (có RHS để phân tích) và `for_targets`.
- `for` thường: macro sinh `i = src[idx]` → `i` **có** RHS → bị loại khỏi tập narrow →
  `total` theo mà không bị narrow.
- `for_tuple_pairs`: `i`/`j` khai báo thẳng bằng `declare_named`, **không** đi qua
  `assigns` → `_expr_int64` không có bằng chứng để loại `total` → hạ `total` xuống i64.

Rồi `return total` trong hàm `-> "i32"` **không có bước thu hẹp i64→i32** → `ret` sai
kiểu → verifier từ chối.

**Đây là khoảng trống CÓ SẴN, không phải do tính năng mới tạo ra.** Tính năng chỉ lộ
nó ra. Hai hướng sửa:

- **(a) Hẹp, chưa thử:** dạy `_collect_for_targets`/`_collect_assigns` trong
  `int_narrow.tkv` biết `for_tuple_pairs`, để `i`/`j` được phân tích như `for` thường.
  CẢnh báo: trong fixpoint, tên thuộc `for_targets` bị **giữ** trong tập narrow
  (`if name in for_targets: continue`), nên thêm `i`/`j` vào đó có thể làm chúng
  thành i64 và hỏng theo cách khác. Chưa chạy thử — đừng coi là đã đúng.
- **(b) Rộng hơn, sửa gốc:** thêm bước thu hẹp i64→i32 ở `codegen_return` khi biến bị
  narrow còn chữ ký là i32. Có thể giúp nhiều chỗ khác, nhưng đụng đường `return` dùng
  chung cho cả chương trình.

Nếu chỉ muốn trạng thái sạch: `git checkout -- Testkit/tuple_literal_test.tkv
compiler/il_features/tuple_type.tkv` là về `93fcd18` (90/90 xanh).

---

## 4. Còn lại của Giai đoạn 2

| Mục | Trạng thái |
|---|---|
| `del` phần tử | XONG (`79de33a`) |
| Hàm lồng / module-global | XONG SẴN, đã có test |
| Biểu thức điều kiện | XONG dạng Python `a if c else b` |
| Chuỗi nhiều dòng | XONG |
| `yield from` | XONG (list + generator) |
| `return <v>` trong generator | XONG (kênh `__gen_ret__`) |
| Literal lồng | XONG |
| Tuple literal | **1/2** — xem mục 3 |
| `f(*xs)`, `f(**kw)` | chưa làm — lớn, cần đổi mô hình arity |

Giai đoạn 3 (`yield from`) về mặt roadmap đã xong; mục 5 của PLAN đã viết lại từ
"vì sao chưa làm" thành mô tả đã làm.

---

## 5. Quy trình bắt buộc

```powershell
cd D:\TokenVector\3.code
Remove-Item "build\pyinstaller" -Recurse -Force -ErrorAction SilentlyContinue
powershell -NoProfile -ExecutionPolicy Bypass -File .\build_tkvc.ps1   # REBUILD TRƯỚC KHI CHẠY CỔNG
.\tools\testkit_gate.ps1
```

- Cổng: `Testkit/*_test.tkv`, **entry `run`** (không phải `main`).
- `Testkit/negative/*.tkv`: dòng đầu `# EXPECT-SUBSTRING: <đoạn>` — phải **fail** và
  thông điệp phải **chứa** đúng đoạn đó.
- `native_test_suite.tkv` **không** thuộc cổng và vẫn không build.
- Sau **mỗi** thay đổi compiler phải clean build. Binary cũ che giấy hồi quy.

### Bẫy đã dính nhiều lần — đọc trước khi sửa

1. **Đừng dùng PowerShell here-string để viết code.** Nó hỏng `\n`, dấu nháy và
   Unicode. Dùng Write/Edit tool, hoặc ghi patch ra file rồi `python file.py`.
2. **File `.tkv` chính là Python.** Docstring `"""..."""` chứa sẵn `"""` sẽ tự hủy —
   đừng viết dấu nháy tam bên trong docstring `"""`.
3. **Kiểm tra anchor là DUY NHẤT.** `edit` khớp mờ, đã từng sửa nhầm chỗ khác.
4. **Ngữ cảnh kiểu suy ra ở first-pass và codegen KHÁC NHAU** cho int literal:
   `infer_scope` ra `int` (TkvInt 16 byte), scope thật ra `i32`. Hai tầng tự suy
   riêng sẽ sinh IL lệch kích thước → biểu hiện thành `NullReferenceException` /
   `InvalidProgramException` **lúc chạy**, không phải lỗi biên dịch. Bắt buộc lấy
   kiểu từ `TypeAnn` mà first-pass đã khai báo (xem `emit_tuple_literal` trong
   `tuple_type.tkv`). `yield from <list>` đã dính đúng lỗi này.
5. **Đặt cụm từ khóa cần test ở ĐẦU thông điệp lỗi.** Gate so `-notmatch` trên
   stderr mà PowerShell wrap theo bề rộng console — cụm ở giữa bị cắt bởi CR/LF và
   gate báo "sai LÝ DO" dù thông điệp đúng.
6. **`ctx` của codegen và `walk_ctx` của first-pass là hai dict khác nhau.** Thêm
   khoá vào một cái thì first-pass không thấy.
7. **`infer_scope[name]` trả 3-tuple** `('local', None, ta)` — phải lấy `[2]`; nó
   chỉ được seed bằng hằng module, **không** có biến module-level.
8. **Gọi hàm generator không chạy thân hàm** — phải iterate mới chạy tới `return`.
   Và đọc biến module từ trong hàm cần `global`.

---

## 6. Bẫy kiểu ngôn ngữ đã biết

- `List<T>`/`HashSet<T>`/`Dictionary<K,V>` so sánh container theo **tham chiếu** →
  mọi phép so sánh theo *nội dung* trên container lồng (`remove`/`in`/`index`/`count`)
  **phải** bị từ chối. Đã có guard; đừng nới lỏng để cho test xanh.
- Có **không** `StopIteration`; không gọi được method trên đối tượng generator
  (chỉ `record`/`string`). Vì vậy giá trị `return` của generator đi qua biến module
  `__gen_ret__` — quy ước, không phải ngôn ngữ; hai generator chạy song song ghi đè
  lẫn nhau.
- Field record kiểu container: chỉ được khi có `self.X = ...` trong `__init__`.
- `global` chỉ hỗ trợ kiểu vô hướng (`i32/i64/f32/f64/str`), **không** container.
- Chuỗi: chỉ nháy kép. Phương thức chỉ gọi được trên biến, không trên literal.
- `len()` chỉ nhận 1 biến trần.
- LAMBDA phải có khai báo chữ ký; `f(*xs)` chưa hỗ trợ (arity tĩnh).

---

## 7. Kỹ thuật dò lỗi đắt giá (dùng nhiều lần phiên này)

- **`TKV_DBG_NARROW=1`** in ra hàm nào bị narrow, `for_targets`, `assigned`, và các
  `kind` lệnh thật → chẩn đoán nhanh nhất khi biến bị hạ kiểu sai.
- **`--emit-il`** rồi đọc file `.il` — bắt được cả lỗi mà ilasm **không** kiểm tra
  (nó không xác minh kiểu/kích thước stack). `InvalidProgramException` lúc chạy thì
  luôn xem IL trước.
- **Dò bằng probe trước khi viết code.** Viết test xong **xác nhận nó đỏ đúng lý do**,
  rồi mới viết compiler. Không có cái neo đó thì không biết mình đúng.
- **So sánh trước/sau bằng `git stash`** khi sửa linter hoặc guard — đo hành vi
  thay đổi thay vì tin lý thuyết.

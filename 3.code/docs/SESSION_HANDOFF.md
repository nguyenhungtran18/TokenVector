# SESSION HANDOFF — TokenVector compiler

Ngày: 2026-09-29. Cổng: **90/90 + negative 10/10 xanh** tại commit `1f7a5ab`.

**KHÔNG còn việc dở dang** — working tree sạch, cả hai repo đã mirror.

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
| `for a, b in <nguồn>` — phần 2/2 | `1f7a5ab` | `96889bf` | `tuple_literal_test.tkv` 7/7 |

Cộng 2 negative test (`yield_from_bad_source`, `generator_return_no_gen_ret`) và 1 negative
test của tuple (`for_tuple_pairs_var`).

**Quy tắc commit:** mỗi thay đổi commit vào **cả hai** repo, chạy gate trước khi commit.

**Quy tắc commit message:** PowerShell nuốt backtick (`\`` thành ký tự điều khiển:
`` `f `` → form feed). Message nào có backtick thì viết ra file rồi
`git commit -F <file>`, đừng truyền `-m` trực tiếp.

---

## 3. `for a, b in <nguồn>` — xong, và hai bẫy đã dính

Nguồn hiện **chỉ** nhận list literal chứa tuple literal; biến list-của-tuple bị từ chối
rõ ràng (`Testkit/negative/for_tuple_pairs_var.tkv`). Vòng lặp dựng mỗi tuple một lần,
đọc `Item1`/`Item2` rồi nạp vào **hai `List` vô hướng song song**, duyệt bằng
`get_Count`/`get_Item`.

**Bẫy 1 — IL hợp lệ ≠ IL chạy được.** Hai cách hiểu nhiên đều **assemble** được bởi
`ilasm` nhưng chết lúc chạy:

- `List<ValueTuple<TkvInt, TkvInt>>::Add(!0)` → `InvalidProgramException`;
- `ldelem`/`ldelema` trên mảng `ValueTuple<TkvInt, TkvInt>` → verifier từ chối.

`ilasm` không xác minh kiểu/kích thước stack. Xem `--emit-il` và thử chạy trước khi tin.

**Bẫy 2 — regex của line parser cướp đường cũ.** Bản regex đầu tiên nhận mọi nguồn nên
nuốt luôn `for k, v in d.items():`, làm hỏng `comprehension_multi_for_test` và
`dict_update_test`. Nay regex **chỉ** nhận `[...]` và biến trong ngoặc đơn `(<tên>)`;
biến trong ngoặc được giữ lại đúng để first-pass báo lỗi rõ ràng thay vì macro
`for_in_kvlist` xử lý nhầm.

**Bẫy 3 — `int_narrow` phải duyệt thân vòng lặp mới.** `_collect_assigns` trước đó bỏ
qua mọi thân vòng lặp, nên `total = total + i + j` không được tính, `total` thành i64,
rồi `return total` trong hàm `-> "i32"` sinh `ret` sai kiểu. Đã sửa ở `int_narrow.tkv:151`.
Cảnh báo khi sửa tiếp: trong fixpoint, tên thuộc `for_targets` bị **giữ** trong tập
narrow, nên **đừng** thêm `i`/`j` của `for_tuple_pairs` vào `for_targets` — chúng lấy
kiểu từ phần tử tuple, không phải biến đếm int64.

---

## 4. Còn lại của Giai đoạn 2

Mục duy nhất còn lại: `f(*xs)`, `f(**kw)` — lớn, cần đổi mô hình arity.

| Mục | Trạng thái |
|---|---|
| `del` phần tử | XONG (`79de33a`) |
| Hàm lồng / module-global | XONG SẴN, đã có test |
| Biểu thức điều kiện | XONG dạng Python `a if c else b` |
| Chuỗi nhiều dòng | XONG |
| `yield from` | XONG (list + generator) |
| `return <v>` trong generator | XONG (kênh `__gen_ret__`) |
| Literal lồng | XONG |
| Tuple literal + `for a, b in` | XONG (nguồn chỉ nhận list literal — xem mục 3) |
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
- `for a, b in` chỉ nhận list literal chứa tuple literal; **không** nhận biến. Không
  nới lỏng khi chưa có đường đọc hợp lệ cho `List<ValueTuple<...>>` (xem mục 3).

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

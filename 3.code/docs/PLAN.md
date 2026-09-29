# TokenVector — Kế hoạch và lộ trình

Cập nhật 2026-09-29. Thay thế mọi bản trước. Mọi mục dựa trên **kết quả đo
được**, không phải suy đoán: 80 file Testkit, 26 test Inference, 18 suite Data,
7 kernel benchmark.

Bản trước đã phình bằng cộng dồn và sai ở nhiều chỗ: số cổng cũ, mục 4a còn
liệt kê việc đã xong, tiêu đề Bước bị **trùng số**, và một tham chiếu "Bước 7"
trỏ tới mục không tồn tại. Bản này viết lại từ đầu theo trạng thái thật.

---

## 1. Trạng thái hiện tại

| Cổng | Kết quả |
|---|---|
| `3.code\tools\testkit_gate.ps1` | **80/80** (timeout 0) |
| Inference | **26/26** |
| Data gate | **PASS** (library 2/2, fragments 0 lỗi thật, suites 18/18) |
| Benchmark | 7 kernel, checksum 7/7 OK |

Benchmark đo trên máy này (min của 5 lần, đã trừ startup). **Chưa chạy lại từ
lần sửa cuối** — số cũ vẫn đúng nhưng cần đo lại sau P6:

| kernel | TokenVector | CPython | nhanh hơn | NumPy |
|---|---|---|---|---|
| fib | 12 075 µs | 941 157 µs | **78×** | – |
| string | 18 629 µs | 50 687 µs | **2.7×** | – |
| sort | 17 344 µs | 1 032 756 µs | **60×** | – |
| add | 1 455 µs | 67 717 µs | **47×** | 1.8× chậm hơn |
| matmul32 | 4 462 µs | 8 805 µs | **2.0×** | **746× chậm hơn** |
| f32mm scalar | 147 µs | 1 533 µs | 10.4× | – |
| **f32mm_vec (SIMD)** | **34 µs** | 1 528 µs | **45×** | – |

SIMD 4-lane đạt **4.08×** so với scalar — ngay tại trần lý thuyết 4 lane.
Startup 24.6 ms so với CPython 35.8 ms.

---

## 2. Tính năng — đã xong

Mỗi dòng có commit và file gate. Cổng phải xanh sau **từng** commit.

| Tính năng | `3.code` | Test |
|---|---|---|
| Timeout mỗi test trong cổng | `fb73f8b` | — |
| `raise <biến>` | `7863ee3` | `raise_var_test.tkv` 7/7 |
| `try/except/else` | `2d3e9dc` | `try_except_else_test.tkv` 10/10 |
| `for`/`while` `else` | `19a8a52` | `for_while_else_test.tkv` 15/15 |
| Comprehension nhiều `for` / `if` | `ba5f5d0` | `comprehension_multi_for_test.tkv` 17/17 |
| Slice có bước `a[i:j:k]` (dương) | `d81bc4f` | `slice_step_test.tkv` 16/16 |
| Set literal `s = {1,2,3}` | `bfdcfc7` | `set_literal_test.tkv` 13/13 |
| Dict literal `d = {"a": 1}` | `ff48634` | `dict_literal_test.tkv` 16/16 |
| Duyệt set `for v in s:` | `268e050` | `set_iteration_test.tkv` 11/11 |
| Chặn field container trên record | `a2919f9` | `record_container_field_test.tkv` 6/6 |
| Kiểu `bool` (alias của `i32`) | `04f80d3` | `bool_type_test.tkv` 20 |
| `is` / `is not` | `a24a347` | `identity_test.tkv` |
| Literal `0o` / `0b` / `1e3` | `dca987d` | `num_literal_test.tkv` |
| `print(sep=, end=)`, `enumerate(a, 1)` | `d997fbd` | `kwargs_enumerate_test.tkv` |
| `in` trên record (`__contains__`) | `bf2b189` | `record_contains_test.tkv` |
| `__lt__` trên record | `69c8827` | `record_lt_test.tkv` |
| `lambda` qua khai báo kiểu `func` | `bb241b4` | `lambda_test.tkv` 11 |
| `list.extend()` | — | có trong testkit sẵn |
| `for k, v in d.items()` | — | có trong testkit sẵn |

---

## 3. Lộ trình

### Giai đoạn 0 — Dọn tài liệu (đang làm)
Chính là bản viết lại này. Xong khi file này được merge.

### Giai đoạn 1 — P6: tự động vector hoá (1–2 ngày)

**Đây là mục tiêu gốc, đã bị các tính năng ngôn ngữ đẩy sang.** Hiện P6 **không
có dòng code nào**.

Phần khả thi đã nghiên cứu xong, ở `REPOSITORY-NOTES.md`. Tóm tắt:

- `TKV_SIMD` **chưa từng tồn tại**. `f32x4` đã luôn bật, không có gì để "bật".
  Nói "P6 đã bật đường nhanh" sẽ là sai. P6 thực sự nghĩa là: **compiler tự phát
  `f32x4`** cho vòng lặp mà lập trình viên viết bằng code vô hướng.
- Vòng lặp elementwise kiểu người dùng viết tay biên dịch thành **đúng 15 lệnh
  IL**: một biến đếm, bước `+1`, cùng chỉ số cho load và store, một lần ghi.
  Nhận dạng cơ học; thay bằng `f32x4` + đuôi scalar là an toàn về **bit**.

Chốt phạm vi: **chỉ elementwise**. Không đụng giảm tổng (`sum += a[i]`) — cái đó
đòi hỏi dung sai 1e-5, là quyết định khác hẳn.

Cổng: chạy cùng một vòng lặp viết tay và viết `f32x4`, so kết quả **bit-for-bit**,
rồi đo lại bảng benchmark ở mục 1.

### Giai đoạn 2 — Phần còn lại của ngôn ngữ

| Mục | Công sức |
|---|---|
| `del` biến / phần tử | rẻ |
| Hàm lồng không bắt buộc là câu lệnh đầu tiên | rẻ |
| Chuỗi nhiều dòng `"""..."""` | trung bình |
| Biểu thức điều kiện `a if c else b` | **cần quyết định** — xem mục 4 |
| Literal lồng `[{"a":1}]`, `{"k":[1,2]}` | thiết kế |
| Tuple literal `(1, 2)` | thiết kế — DSL **không có kiểu tuple** |
| `f(*xs)`, `f(**kw)` | lớn — cần đổi mô hình arity |
| `yield from` | lớn — xem mục 5 |

### Giai đoạn 3 — `yield from`
Chỉ khi `native_test_suite.tkv` build được. Chi tiết ở mục 5.

---

## 4. Giới hạn CÓ CHỦ ĐÍCH — không phải việc cần làm

| Mục | Vì sao |
|---|---|
| `@classmethod` | Runtime chưa có khái niệm `cls`. Bị từ chối với thông báo rõ, không phải chưa làm. |
| Slice bước **âm** `a[::-1]` | Cần đổi chiều so sánh, sửa mốc âm, sửa điều kiện thoát. Linter chặn rõ. Từ chối còn hơn sinh IL sai. |
| `lambda` không khai báo kiểu | Node lambda chỉ mang *tên* tham số; ngôn ngữ này không suy luận kiểu. Bắt buộc khai `func(...) -> ...`. |
| Field container trên record | `.ctor` lấy tham số từ *field*, container bị lọc khỏi danh sách đó nên không bao giờ gán được. Nay báo lỗi biên dịch. |
| `f64` vector hoá | CLR 4.x không có `Vector<T>`/`Vector256`. Cần retarget .NET 8 — đổi nền tảng, không phải việc compiler. |
| `str(<so sánh>)` in `"True"` | Đổi sang `"1"` là **thay đổi phá vễ**; mọi test phải gán biến trước rồi mới `str()`. Xem mục 6. |

### Cần anh quyết định: conditional expression

Cả hai dạng đều hỏng: `a if c else b` **và** `c ? a : b`. Nhưng thông báo lỗi của
compiler lại bảo dùng dạng `c ? a : b` — tức là bảo dùng thứ không dùng được.

Ba lựa chọn: (a) hỗ trợ cả hai, (b) hỗ trợ dạng Python và sửa thông báo, (c) sửa
thông báo để cả hai đều gợi ý viết `if` tường minh. Tôi nghiêng về **(a)** vì
ngôn ngữ này đã có `?` cho điều kiện một phía, nhưng đây là quyết định cú pháp nên
cần anh chốt.

---

## 5. `yield from` — vì sao chưa làm

Phải cho state machine generator ăn iterator thứ hai (MoveNext/Current vào cùng
đường yield).

**Không kiểm chứng được bằng bộ suite nào chặn**: `native_test_suite.tkv` là bộ 16
case duy nhất dùng nó, và file đó hiện **không build** vì thiếu `yield from`.
Làm nó lúc này nghĩa là làm mù. Phải làm kèm một Testkit riêng, hoặc sửa
`native_test_suite.tkv` cho build trước.

Cùng nhóm: `return <giá trị>` trong generator (`StopIteration.value`).

---

## 6. Bài học đã tích lũy — đọc trước khi sửa gì

Chi tiết đầy đủ: `3.code/docs/SESSION_HANDOFF.md` (mục bẫy) và
`REPOSITORY-NOTES.md` (829 dòng nhật ký). Ở đây chỉ những điều định hình cách làm:

**Cổng chỉ phủ những gì ai đó ngồi viết test cho.** 80 file test bảo chứng cho 80
*đường đi đã được đi qua*, không phải 80 tính năng. Bốn bug đã sửa trong chu kỳ
trước đều nằm ngoài tập đường đi đó, và ba cái trong số đó **âm thầm**.

**Tài liệu bỏ sót một tính năng đã chạy nguy hiểm hơn tài liệu nói "chưa làm".**
`PLAN.md` từng xếp dict comprehension vào "cần thiết kế" trong khi nó **đã chạy
đúng từ trước**; thứ thật sự chặn nó là linter. `lambda` cũng bị xếp nhầm. Luôn
chạy một probe thật trước khi tin danh sách thiếu.

**Đừng sửa theo chẩn đoán chưa kiểm.** Một handoff của tôi ghi sai nguyên nhân
lỗi container; tôi sửa theo đó, thành công một lần rồi mới thấy cơ chế đó không
tồn tại, và phải hoàn tác. Chi phí: một commit rác.

**Đối chiếu CPython trước khi viết kỳ vọng vào test.** Trong một ngày tôi đoán
sai 4 lần; cả bốn lần code đều đúng và CPython mới là chuẩn xác nhận.

**Lỗi làm hỏng cả file thì bắt ở probe nhỏ, đừng chạy cổng.** `sig.params` là
list *object* chứ không phải tuple; unpack sai nó kéo cổng xuống 0/80.

**Đừng ship code không tới đường.** Tôi viết `EXPR_CODEGEN` cho set literal inline
rồi gỡ bỏ, vì mọi đường tiêu thụ đều bị chặn bởi hạn chế có sẵn nên không test
được. Code không tới đường là nợ.

**Cổng không diễn đạt được "cái này phải build hỏng".** Nên phần "đã bị từ chối"
được chứng minh bằng probe tách riêng, không phải bằng `check()`. Đừng thêm
`check("bi tu choi", "1", "1")` — nó khẳng định điều gì cũng không.

---

## 7. Cổng nghiệm thu

Chạy trước khi coi bất cứ thay đổi nào là xong:

```powershell
# 1. Build lại compiler TỪ CÂY NGUỒN (binary cũ che hồi quy)
.\3.code\build_tkvc.ps1

# 2. Testkit — 80 file, timeout 120s/test
.\3.code\tools\testkit_gate.ps1

# 3. Inference
.\3.code\dist\tkvc.exe build D:\TokenVector.Inference\tv\tests\inference_tests.tkv `
    --entry main --out $env:TEMP\inf.exe --no-lint
.\%TEMP%\inf.exe

# 4. Data — mất khoảng 5 PHÚT, không tre
powershell -File D:\TokenVector.Data\tools\datagate.ps1

# 5. Benchmark — tự build kernel từ dist\tkvc.exe
python .\3.code\bench\run.py
```

Bước 1 **không được bỏ** — binary cũ từng che một test suite không build được.
Bước 4 mất ~296 s vì nó build rồi **thực thi** 18 check, không chỉ biên dịch.

**Quy tắc commit:** mỗi thay đổi commit vào **cả hai** repo (`3.code` và parent),
ghi rõ `(mirrors 3.code <hash>)` trong message của parent.

---

## 8. Việc treo ngoài roadmap — cần quyết định riêng

| Việc | Tình trạng |
|---|---|
| `tokenvector-grammar` | Working tree bẩn: **xoá** `tokenvector-syntax-1.0.0.vsix` (file đã track) + ~15 file scratch. Cần chọn khôi phục hay chấp nhận xoá. Con trỏ gitlink **không đổi**. |
| 4 fragment Data | `tokenvector_compute`/`datetime`/`io`/`stats` cần hằng số module. Đã ghi ở `Data\SESSION_HANDOFF.md`. |
| Xoá repo con `3.code` | Không hoàn tác được. Mọi commit đã có trong parent qua tag `nested-3code-snapshot`. Chờ quyết định. |
| `f32x8`/`VBuf8` retire | Đã ghi chú là không phải SIMD nhưng chưa gỡ. 8 số rời, không lợi. |

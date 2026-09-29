# TokenVector — Kế hoạch và lộ trình

Cập nhật 2026-09-29. Thay thế mọi bản trước. Mọi mục dựa trên **kết quả đo
được**, không phải suy đoán: 84 file Testkit, 26 test Inference, 18 suite Data,
7 kernel benchmark.

Bản trước đã phình bằng cộng dồn và sai ở nhiều chỗ: số cổng cũ, mục 4a còn
liệt kê việc đã xong, tiêu đề Bước bị **trùng số**, và một tham chiếu "Bước 7"
trỏ tới mục không tồn tại. Bản này viết lại từ đầu theo trạng thái thật.

---

## 1. Trạng thái hiện tại

| Cổng | Kết quả |
|---|---|
| `3.code\tools\testkit_gate.ps1` | **86/86** + **negative 7/7** (timeout 0, ILFAIL 0) |
| Inference | **KHÔNG BUILD** — xem mục 1.1 |
| Data gate | **FAIL (0/2 library, 0/18 suites)** — xem mục 1.1 |
| Benchmark | 7 kernel, checksum 7/7 OK (đo lại 2026-09-29) |

Benchmark đo trên máy này (đo lại 2026-09-29, đã trừ startup). **Số cũ trước
đây đã lỗi thời** — bảng dưới là lần đo mới nhất:

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

**P6 (vector hoá TỰ ĐỘNG) — đo riêng bằng `3.code\bench\p6_bench.py`.**
Bảng trên dùng SIMD viết tay, nên không phản ánh P6. P6 đo bằng cách so
**chính compiler với chính nó**: hai kernel giống hệt nhau, chỉ khác ở điều
kiện vòng lặp (`while i < nb` — biến, vector hoá; `while i < 262144` — hằng
số, bị từ chối). Chênh lệch thời gian đó ra công **đúng hiệu quả của P6**.

| tập 3 bộ đệm | scalar | tự động | tăng tốc |
|---|---|---|---|
| 48 KB (vừa L2) | 20.1 ms | 5.4 ms | **3.8×** |
| 3 MB (vượt L2) | 21.8 ms | 11.3 ms | **1.9×** |

Số đo **có nhiễu lớn** giữa các lần chạy (cùng cấu hình cho 3.1× rồi 3.8×).
Đừng trích con số đơn lẻ. Ba điều đã biết:
- Tăng tốc **riêng của P6** là ~1.6–2.1×. Tỷ lệ 3.8× trên đây cao hơn vì
  kích thước được chọn vừa L2, và vì kích thước lớn thì giới hạn băng thông.
- Vòng vector kiểm tra giới hạn **một lần cho 4 phần tử** (`(i+3) < len`)
  trong khi vòng scalar kiểm tra 4 lần — cải thiện thuật toán hợp lệ.
- Vẫn chưa đạt 4× vì mỗi vòng còn **36 lệnh IL cho 4 phần tử**, trong đó
  18 lệnh tính địa chỉ byte cho 3 toán số.

---

## 1.1 HỒI QUY do tôi gây ra: chặn field container trên record (2026-09-29)

Chạy đủ 5 bước của mục 7 lần đầu sau nhiều commit cho thấy **Inference và
Data đều KHÔNG BUILD**, cùng một nguyên nhân:

```
class 'Schema': field 'fields' kieu container ('list[Field]') chua ho tren record
class 'ExecutionMemoryArena': field 'fmap' kieu container ('dict[i64,list[f32]]') chua ho tren record
```

- Inference: **không build** → số "26/26" trong bảng mục 1 là **stale**, đo
  trước commit `a2919f9`.
- Data: **0/2 library, 0/18 suites** (toàn bộ 18 check fail build), mất 123 s.

**Nguyên nhân là commit `a2919f9` của chính tôi** ("chặn field container trên
record"). Luận cứ lúc đó: `.ctor` lấy tham số từ *field*, container bị lọc khỏi
danh sách đó, nên field container **không bao giờ** được lấp đầy.

Luận cứ đó **sai vì bỏ sót một đường**: field vẫn được `__init__` gán trực tiếp
bằng `self.fmap = {}` — đó chính là cách Inference và Data dùng. Cơ chế `.ctor`
không lấp được, nhưng phép gán trong `__init__` thì có, và đó là cách hợp lệ.

**Vì sao 85/85 không bắt được:** cổng Testkit chỉ phủ `Testkit/`. Hai hệ thống
dùng nó là Inference và Data **không nằm trong Testkit**. Và bảng mục 1 vẫn ghi
kết quả cũ mà không ai chạy lại — đó là lỗi của PLAN, không chỉ của code.

### Kết quả khi áp dụng (b) — và phạm vi thật

Quy tắc mới đã vào compiler (`a9ac525`):

| trường hợp | kết quả |
|---|---|
| `self.X = {}` trong `__init__` | **cho phép** — gán trực tiếp, không qua `.ctor` |
| container truyền qua tham số `.ctor` | từ chối — `.ctor` lọc container khỏi danh sách tham số |
| field container **chưa** gán trong `__init__` | từ chối — sẽ rỗng, im lặng |

Ngay khi áp dụng, nó bắt được **bệnh thật** chứ không phải vài lỗi lẻ:

| hệ thống | số field container chưa gán trong `__init__` |
|---|---|
| Inference | **19** (77 bản sao) |
| Data | **31** (90 bản sao) |

Quét hết bằng: `python .\3.code\tools\scan_uninit_container_fields.py D:\TokenVector.Inference`

Gồm `DataFrame.cols`, `Col.f64s`, `Grammar.rules`, `GenRequest.tokens`,
`SymbolicShape.dims`… Tức **~50 null-deref tiềm ẩn**. Hai hệ thống này trước
đây build và pass cổng — nghĩa là chúng đã sống chung với những field null đó
mà compiler im lặng.

**Đã sửa thử 2 field** (`ExecutionGraph.dim_params`, `StrAcc`) thì còn 17+29.
Đã **hoàn tác toàn bộ** thay đổi ở Inference để không để lại repo ở trạng thái
vá dở nửa chừng.

### Quyết định: hoãn sửa repo khác, tập trung compiler (2026-09-29)

Lệnh rõ của anh: **tập trung compiler, lỗi các repo khác để sau.** Vì vậy:

- Quy tắc (b) **giữ nguyên là lỗi chặn build** — nó đúng, và sai lệch là
  chi phí của repo khác chứ không phải của compiler.
- **Inference và Data tạm thời không build được.** Đây là hệ quả đã biết,
  không phải tai nạn mới.
- 50 field ở trên **chưa sửa**. Không thể đoán giá trị khởi tạo đúng cho từng
  field — cần người hiểu ngữ nghĩa domain của từng hệ thống.
- Việc này nên là **dự án riêng**, có gate riêng, không gộp vào chuỗi sửa
  compiler.

**Hệ quả phải nói thẳng:** công cụ không còn kiểm chứng được bằng hệ thống
thật. Phần "cho phép" hiện **chỉ** được kiểm chứng bằng Testkit; bản dương
chưa viết được (vướng lỗi khác: gọi method của record với tham số scalar báo
`literal '5' khong dung voi dtype 'Acc'` — cũng chưa điều tra).

### Việc nên làm thêm

`Testkit/` nên có **smoke test** cho Inference và Data: chỉ cần build được
`inference_tests.tkv` và vài fragment Data, không cần chạy hết. Rẻ hơn nhiều so
với phát hiện hồi quy sau 15 commit. **Hiện chưa làm** — và sẽ đỏ ngay vì
lý do ở mục trên.

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
| Cổng `Testkit/negative/` ("phải bị từ chối") | `f41b391` | 3/3, có mutation check |
| Kiểu `bool` (alias của `i32`) | `04f80d3` | `bool_type_test.tkv` 20 |
| `is` / `is not` | `a24a347` | `identity_test.tkv` |
| Literal `0o` / `0b` / `1e3` | `dca987d` | `num_literal_test.tkv` |
| `print(sep=, end=)`, `enumerate(a, 1)` | `d997fbd` | `kwargs_enumerate_test.tkv` |
| `in` trên record (`__contains__`) | `bf2b189` | `record_contains_test.tkv` |
| `__lt__` trên record | `69c8827` | `record_lt_test.tkv` |
| `lambda` qua khai báo kiểu `func` | `bb241b4` | `lambda_test.tkv` 11 |
| `list.extend()` | — | có trong testkit sẵn |
| `for k, v in d.items()` | — | có trong testkit sẵn |
| **P6-1** container `f32buf` | `2ee0c31` | `f32buf_test.tkv` 16/16 |
| **P6-2** vector hoá tự động vòng lặp | `83db909` | `p6_vectorize_test.tkv` 16/16 |
| **P6-3** mutation test + sửa gate | `c81dff9` | 82/82 (gate bắt được transform hỏng) |
| **P6-4** đo hiệu quả | `59b3329` | `p6_bench.py` |
| **P6-5** giới hạn + `f32buf_free` | `22ca15e` | `f32buf_bounds_free_test.tkv` 19/19 |
| **P6-6** tối ưu địa chỉ vector | `3723ce0` | 83/83 |
| Conditional expression `a if c else b` | `beee4cd` | `conditional_expr_test.tkv` 16/16 |
| `del lst[i]`, `del d[k]` | xem mục 3 | `del_stmt_test.tkv` 13/13 |
| Hàm lồng + biến module (`global`) | xem mục 3 | `nested_global_test.tkv` 6/6 |

---

## 3. Lộ trình

### Giai đoạn 0 — Dọn tài liệu: **XONG**

### Giai đoạn 1 — P6: tự động vector hoá: **XONG (P6-1 → P6-6)**

Mục tiêu gốc, đã bị các tính năng ngôn ngữ đẩy sang. Giờ đã có code, cổng
xanh 83/83. Chi tiết ở `REPOSITORY-NOTES.md`; tóm tắt:

- `TKV_SIMD` **chưa từng tồn tại**. `f32x4` đã luôn bật. P6 thực sự nghĩa là:
  **compiler tự phát `f32x4`** cho vòng lặp mà lập trình viên viết bằng code
  vô hướng.
- **P6-1** container `f32buf` — substrate bắt buộc. `v_load4`/`v_store4` cần
  16 byte liên tiếp, mà `List<T>` không cho lấy địa chỉ mà không chạm field
  private `_items` của BCL (đã bị từ chối có chủ đích).
- **P6-2** recognizer `while i < n` + đuôi scalar. Nguyên tắc: có bất kỳ nghi
  ngờ nào thì **không** vector hoá.
- **P6-3** mutation test — và phát hiện gate **chưa bao giờ bắt được test
  fail** (xem mục 6).
- **P6-4** đo hiệu quả: ~1.6–2.1× (riêng P6), tốt hơn khi dữ liệu vừa cache.
- **P6-5** kiểm tra giới hạn + `f32buf_free`.
- **P6-6** tối ưu địa chỉ: 42 → 36 lệnh IL, đồng thời sửa lỗi cắt offset 2 GB.

Chốt phạm vi vẫn là: **chỉ elementwise**. Không đụng giảm tổng (`sum += a[i]`) —
cái đó đòi hỏi dung sai 1e-5.

Còn lại của P6 (xem mục 8): nâng `i*4` ra khỏi vòng vector.


### Giai đoạn 2 — Phần còn lại của ngôn ngữ

| Mục | Công sức |
|---|---|
| ~~`del` phần tử~~ | **XONG** — `del lst[i]`, `del d[k]`. `del x` (biến) **từ chối có chủ đích**: local có kiểu khai báo, tạo "không còn binding" đòi hỏi mọi nơi đọc biến phải kiểm tra. Xem REPOSITORY-NOTES |
| ~~Hàm lồng không bắt buộc là câu lệnh đầu tiên~~ | **XONG SẴN** — kiểm chứng lại (2026-09-29): `def` lồng chạy được sau lệnh thường, sau chú thích, sau `while`. Biến module cần `global` là **có chủ đích**. Test `nested_global_test.tkv` 6/6 |
| ~~Chuỗi nhiều dòng `"""..."""`~~ | **XONG (2026-09-29)** — `_join_triple_quoted` (il_codegen.tkv) nối dòng khi `"""` chưa đóng, đổi newline thành escape 2 ký tự ngay tại nơi nối; nhom `TRIPLESTR` trong `_EXPR_TOKEN_RE` (il_core.tkv) nhận nội dung. Test `multiline_string_test.tkv` 8/8. Xem REPOSITORY-NOTES |
| ~~Biểu thức điều kiện~~ | **XONG** — dạng Python `a if c else b` đã có. Dạng `c ? a : b` vẫn bị chặn bởi `ast.parse` của Python — xem mục 4 |
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

### Conditional expression — đã chốt, đã làm xong một nửa

**Đã thêm dạng Python `a if c else b`** (`beee4cd`, gate 16/16, đối chiếu CPython
từng dòng). Thông báo lỗi sai lệch cũng đã sửa — trước đó nó bảo dùng `?`,
tức bảo dùng đúng cái đang không dùng được.

Lựa chọn ban đầu của tôi là (a) hỗ trợ cả hai. **Đó là lựa chọn sai**, vì hai
dạng không đối xứng về chi phí:

| dạng | parser riêng | thực ra chết ở đâu |
|---|---|---|
| `c ? a : b` | **đã làm được từ trước** | `tkv_compile.tkv:3854` |
| `a if c else b` | thiếu một production | chính nó |

`tkv_compile.tkv`'s `_parse_program_ast` gọi **`ast.parse` của Python** ở dòng
đầu để rút record/signature/hằng số module. Python không có `?:`, nên dạng `?`
chết trước khi parser của TokenVector kịp chạy. **Xương sống của front-end là
AST của Python** — tháo ra thì phải viết lại cả phần trích xuất.

Muốn mở lại dạng `?` thì phải xử lý trước `_parse_program_ast`. Cách ít hại nhất:
một tiền xử lý **văn bản** chuyển `X ? Y : Z` thành `Y if X else Z` trước khi
gọi `ast.parse` (Python-valid, cùng nghĩa). Rủi ro: phải đặt đúng ranh giới ba
toán số khi `?`/`:` lồng nhau. Việc riêng, có kiểm thử riêng.

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

# 2. Testkit — 87 file + 7 negative, timeout 120s/test
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
| Nâng `i*4` ra khỏi vòng vector | Còn 6/36 lệnh IL do `i*4` bị tính 3 lần. Cần `first_pass_walk` cho `while` chạy cùng logic khớp mẫu ở cả 2 pass — lệch một chút là `InvalidProgramException` **lúc chạy**, không phải lúc build. Đổi lại ~17% trên đường đã nhanh hơn scalar ~4×. Tỷ lệ giá trị/chi phí không tốt; để thành việc riêng. |
| Tích hợp SIMD vào `TokenVector.Data` | Handoff ở `Data\SESSION_HANDOFF_SIMD.md`. Chưa làm. |

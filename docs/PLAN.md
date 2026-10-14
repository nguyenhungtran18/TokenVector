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
| `tools\testkit_gate.ps1` | **123/123** + **negative 31/31** (timeout 0, ILFAIL 0) — nguồn sự thật hiện tại |
| Inference | **26/26** PASS (`tv/tests/inference_tests.tkv`) |
| Data gate | **PASS (18/18)** |
| Parity probe CPython | ~~**119/119**~~ — **đã gỡ khỏi danh sách gate 2026-10-14** (cần compiler Python cũ). Đối chiếu CPython nay ở repo `TokenVector.TestOracle` |
| Hiệu năng | `tools\perf_gate.ps1` — so với baseline của chính compiler, **có so checksum** |

> Bảng benchmark bên dưới là **số đo lịch sử (2026-09-29)** so với CPython/NumPy.
> Việc đó đã tách sang repo `TokenVector.TestOracle`; trong repo này chỉ còn
> `perf_gate` so với chính nó qua thời gian.

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

**P6 (vector hoá TỰ ĐỘNG) — đo riêng bằng `\bench\p6_bench.py`.**
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

> **ĐÃ GIẢI QUYẾT (2026-09-30).** `self.X = {}` trong `__init__` đã được cho
> phép; Inference **26/26** và Data **18/18** đều build và PASS. Giữ nguyên mục
> này vì nó ghi lại *cách* lỗi xảy ra, không phải trạng thái hiện tại — số liệu
> trong đoạn dưới là của đúng ngày 2026-09-29.

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

**Vì sao 85/85 không bắt được:** cổng Testkit chỉ phủ `tests/`. Hai hệ thống
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

Quét hết bằng: `dist\tkvc-tv.exe tools\scan_container.tkv build\sc.exe run D:\TokenVector.Inference`

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

> **Cập nhật 2026-09-30:** người dùng đã cho phép sửa cả hai repo. Cả 50 field đã gán
> bằng container rỗng (xem mục 1.1), và `__init__` nay **thật sự chạy** (trước đó
> compiler bỏ qua toàn bộ thân `__init__`, nên `self.X = {}` trong đó chết). Cả hai
> repo nay build và chạy xanh. Quy tắc (b) vẫn giữ nguyên.

**Hệ quả phải nói thẳng:** công cụ không còn kiểm chứng được bằng hệ thống
thật. Phần "cho phép" hiện **đã** được kiểm chứng bằng bản dương — xem
`tests/record_container_field_test.tkv`'s `container_field_positive` (4 check) và
`tests/record_method_name_collision_test.tkv` (18/18). Bản dương này trước đây
**không viết được** vì lỗi `literal '5' khong dung voi dtype 'Acc'` — nguyên nhân là
method của record trùng tên method của container bị line parser của container cướp
mất; **đã sửa** (commit `b1ba163`).

### Việc nên làm thêm

**ĐÃ XỬA (2026-09-30)** — cả 50 field đã gán: Data 31 (`fcdd972`) + Inference 19
(`609ea31`). Mọi field đều là container **rỗng** nên không cần đoán giá trị domain.
Kết quả: Data gate **2/2 + 18/18**, Inference **26/26 PASS** — trước đó cả hai repo
đều **không build được**.

---

## 2. Tính năng — đã xong

Mỗi dòng có commit và file gate. Cổng phải xanh sau **từng** commit.

| Tính năng | `` | Test |
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
| Cổng `tests/negative/` ("phải bị từ chối") | `f41b391` | 3/3, có mutation check |
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

**Đo lại 2026-10-14** (`tools/perf/perf_f32buf.tkv`, nay đã vào `perf_gate`):
P6 **nhanh hơn scalar `list[f32]` 1.57×** — khớp con số 1.6–2.1× ghi ở
trên. Bằng chứng mạnh nhất: khi đổi thành `r[i] = a[i] * 2.0 + b[i]` (P6 **từ chối**
vì có hằng số ⇒ chạy scalar) thì kernel chậm **+103%** (232 → 472 ms), tức
đường vector hoá đóng góp đúng **một nửa** thời gian.

> **Không phải SIMD thật.** IL là `call System.Numerics.Vector4::op_Addition` —
> một **method call**, không phải lệnh vector. 1.57× đến từ ít lệnh hơn
> (6 lệnh / 4 phần tử), không từ SIMD. Cùng lý do `v_*8` chỉ nhanh 1.08×
> (213 lệnh IL / 8 phần tử so với 39 của scalar — xem handoff 2026-10-14).

**Giới hạn chưa ghi ở đâu:** `f32buf` **chỉ là local** — không truyền được qua
tham số hàm (probe trực tiếp: *"Ky vong dtype, gap 'f32buf'"*). Muốn dùng P6 thì
vòng phải nằm trong hàm, không tách ra hàm con được.

Chốt phạm vi vẫn là: **chỉ elementwise**. Không đụng giảm tổng (`sum += a[i]`) —
cái đó đòi hỏi dung sai 1e-5.

Còn lại của P6 (xem mục 8): nâng `i*4` ra khỏi vòng vector. **Đo lại 2026-10-14:
không đáng làm** — biến `i*4` vẫn bị tính 3 lần trong IL, nhưng thời gian hai
kiểu chỉ khác ~4% (1.23 vs 1.18 ms), vì JIT chịu được `TkvInt`. Tỷ lệ
giá trị/chi phí không tốt.


### Giai đoạn 2 — Phần còn lại của ngôn ngữ

| Mục | Công sức |
|---|---|
| ~~`del` phần tử~~ | **XONG** — `del lst[i]`, `del d[k]`. `del x` (biến) **từ chối có chủ đích**: local có kiểu khai báo, tạo "không còn binding" đòi hỏi mọi nơi đọc biến phải kiểm tra. Xem REPOSITORY-NOTES |
| ~~Hàm lồng không bắt buộc là câu lệnh đầu tiên~~ | **XONG SẴN** — kiểm chứng lại (2026-09-29): `def` lồng chạy được sau lệnh thường, sau chú thích, sau `while`. Biến module cần `global` là **có chủ đích**. Test `nested_global_test.tkv` 6/6 |
| ~~Chuỗi nhiều dòng `"""..."""`~~ | **XONG (2026-09-29)** — `_join_triple_quoted` (il_codegen.tkv) nối dòng khi `"""` chưa đóng, đổi newline thành escape 2 ký tự ngay tại nơi nối; nhom `TRIPLESTR` trong `_EXPR_TOKEN_RE` (il_core.tkv) nhận nội dung. Test `multiline_string_test.tkv` 8/8. Xem REPOSITORY-NOTES |
| ~~Biểu thức điều kiện~~ | **XONG** — dạng Python `a if c else b` đã có. Dạng `c ? a : b` vẫn bị chặn bởi `ast.parse` của Python — xem mục 4 |
| ~~Literal lồng `[{"a":1}]`, `{"k":[1,2]}`~~ | **XONG (2026-09-29)** — list/dict/set chứa nhau, tới 4 cấp. Test `nested_literal_test.tkv` 7/7. Các phép so sánh theo NỘI DUNG trên container lồng (`remove`/`in`/`index`/`count`) **vẫn bị từ chối** — `List<T>`/`HashSet<T>` so sánh theo tham chiếu |
| ~~Tuple literal `(1, 2)`~~ | **XONG (2026-09-29)** — ghi chú cũ "DSL **không có kiểu tuple**" SAI: kiểu tuple có sẵn và chạy (`-> "(i32,i32)"`, `return a, b`, `a, b = f()`, `p[0]`, `for_in_iter`). Đã làm: literal ở vị trí biểu thức, phá huỷ từ literal (`a, b = (3,4)`), phá huỷ từ biến (`x, y = t`), khai báo local kiểu tuple, truyền literal làm tham số, và `for a, b in <nguồn>`. Test `tuple_literal_test.tkv` 7/7. **CÒN:** nguồn của `for a, b in` hiện **chỉ** nhận list literal chứa tuple literal; biến list-của-tuple bị từ chối (`tests/negative/for_tuple_pairs_var.tkv`) |
| ~~`f(*xs)`, `f(**kw)`~~ | **XONG (2026-09-29)** — không đổi mô hình arity: desugar tại điểm gọi, khi độ dài/khoá nguồn biết lúc biên dịch thì sinh N đối số cố định (hoặc node `('kwarg', …)` cho `**`), rồi đi tiếp vào đường `call` sẵn có (arity check / tham số mặc định / monomorphize y nguyên trạng). `**` tái dùng `kwarg_resolve` nên trùng tên/khoá lạ/thiếu tham số đều đã có sẵn. Nguồn nhận: `f(*[1,2,3])`, `f(**{"a":1})`, và biến `xs = [...]` / `kw = {...}` dùng ngay, không dùng ở chỗ khác. Nguồn động bị từ chối rõ ràng. Test `star_args_test.tkv` 11/11 + `star_kwargs_test.tkv` 11/11 + 5 negative. **Giai đoạn 2 xong toàn bộ** |
| ~~`yield from`~~ | **XONG (2026-09-29)** — ho tro **list** (vong lap theo chi so) va **ham generator** (ban giao `MoveNext`/`get_Current`). Nguon khac bi tu choi VOI LY DO. Test `generator_yield_from_test.tkv` 10/10. Xem mục 5 |
| ~~`return <giá trị>` trong generator~~ | **XONG (2026-09-29)** — `return v` DUNG vong lap + ghi `v` vao bien module `__gen_ret__` (xem mục 5 vi sao khong phai `StopIteration.value`) |

### Giai đoạn 3 — `yield from`
~~Xong 2026-09-29 (xem dòng `yield from` o bang tren).~~

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

### Conditional expression — **XONG CẢ HAI DẠNG** (2026-09-29)

~~Đã thêm dạng Python `a if c else b`~~ (`beee4cd`, gate 16/16) và **2026-09-29 đã
thêm nốt dạng `c ? a : b`** (commit `60c1d8f`, test `question_ternary_test.tkv`
9/9).

Trước đây tôi chọn (a) hỗ trợ cả hai và **đó là lựa chọn sai** — tôi đã viết ở đây
rằng hai dạng "không đối xứng về chi phí" và `?` chết ở `tkv_compile.tkv:3854`
vì `ast.parse` của Python không có `?:`. Cả hai vế đều đúng, nhưng kết luận "việc
riêng, có kiểm thử riêng" thì đã lỗi thời: **chỉ cần một tiền xử lý văn bản** đổi
`X ? Y : Z` thành `Y if X else Z` ngay trước `ast.parse` là xong, không phải viết
lại phần trích xuất. Xem `compiler/question_ternary.tkv`.

Ràng buộc đã giữ: **không thêm/bớt dòng** (`start_line` và `node.lineno` phải đúng),
và **không chắc chắn thì không ghi đè** — để `ast.parse` báo lỗi như trước.

Làm việc này lộ ra **3 bug ternary cũ, đều im lặng** (assemble được, hỏng lúc chạy) —
xem mục 1.1 và `REPOSITORY-NOTES`. Đáng chú ý nhất: local `__ternN` được first-pass khai
một kiểu nhưng codegen đẩy hai nhánh theo kiểu khác → **sai gi��i trí mà không có lỗi
nào**. Nguyên tắc của dự án ("sai âm thẩm nguy hiểm hơn lỗi ồn ào") đúng, nhưng ở
đây cả hai đều xấu: cần kiểm tra `--emit-il` khi thấy kết quả lạ.

---

## 5. `yield from` — ĐÃ LÀM (2026-09-29)

Trước đây mục này ghi "vì sao chưa làm". Lý do lúc đó: `native_test_suite.tkv` là
bộ case duy nhất dùng nó mà file đó **không build** vì thiếu `yield from` — vòng
luẩn quy, làm thì không kiểm chứng được. Đã gỡ bằng cách viết
`tests/generator_yield_from_test.tkv` **trước** (đỏ đúng lý do), rồi mới
implement.

**Cú pháp**: `yield from <nguon>`, 2 dạng nguồn —
- biến `list` → vòng lặp theo chỉ số (`get_Count`/`get_Item`)
- gọi trực tiếp 1 hàm generator → bàn giao `MoveNext`/`get_Current`

Nguồn khác (set, dict, record có `__iter__`) **bị từ chối với lý do rõ ràng** ở
first-pass, không âm thầm sinh IL sai. Thêm `GetEnumerator` + mở
`IEnumerable<T>` lên class generator sẽ gộp được mọi loại, nhưng đó là việc
riêng, chưa làm.

**`return <giá trị>` trong generator**: `return v` dừng vòng lặp (`MoveNext` trả
false, `__state = -1`) và ghi `v` vào biến module `__gen_ret__`.

Vì sao **không phải** `StopIteration.value` như Python — đã kiểm chứng bằng
probe trước khi thiết kế:
1. Không thể gọi method trên đối tượng generator: compiler chỉ cho phép method
   trên `record`/`string` (`'.Reset(...)' chi dung duoc tren bien kieu record,
   string`).
2. Không có cơ chế `StopIteration` nào trong codebase.

Nên biến module là kênh đọc giá trị khả dụng duy nhất mà không phải sửa cả cơ
chế method dispatch. **Hệ quả phải nói rõ**: hai generator chạy song song sẽ
ghi đè lẫn nhau, và tên `__gen_ret__` là quy ước chứ không phải ngôn ngữ.

Cùng nhóm: `yield from` trên set/dict/record (**chưa làm**). `iter()`/`next()`
**ĐÃ LÀM 2026-10-02** (list only) — xem `REFERENCE.md` §7.12.

---

## 6. Bài học đã tích lũy — đọc trước khi sửa gì

Chi tiết đầy đủ: `docs/SESSION_HANDOFF.md` (mục bẫy) và
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
# 1. Fixpoint tu bien dich (binary cu che hoi quy)
.\tools\vong.exe              # cho toi khi in IL_IDENTICAL

# 2. Testkit — 123 file + 31 negative, timeout 120s/test
.\tools\testkit_gate.ps1

# 3. Hieu nang — so voi baseline cua chinh compiler, CO so checksum
.\tools\perf_gate.ps1

# 4. Dang ky + lint
.\dist\tkvc-tv.exe tools\dang_ky_gate.tkv build\dk.exe run
.\build\dk.exe
powershell -File .\tools\lint_rules_gate.ps1
```

Bước 1 **không được bỏ** — binary cũ từng che một test suite không build được.
`IL KHAC NHAU` là bình thường (compiler tự nâng cấp) — chạy lại là đúng.

**Quy tắc commit:** mỗi thay đổi commit vào **cả hai** repo (`` và parent),
ghi rõ `(mirrors  <hash>)` trong message của parent.

---

## 8. Việc treo ngoài roadmap — cần quyết định riêng

| Việc | Tình trạng |
|---|---|
| `tokenvector-grammar` | Working tree bẩn: **xoá** `tokenvector-syntax-1.0.0.vsix` (file đã track) + ~15 file scratch. Cần chọn khôi phục hay chấp nhận xoá. Con trỏ gitlink **không đổi**. |
| 4 fragment Data | `tokenvector_compute`/`datetime`/`io`/`stats` cần hằng số module. Đã ghi ở `Data\SESSION_HANDOFF.md`. |
| Xoá repo con `` | Không hoàn tác được. Mọi commit đã có trong parent qua tag `nested-3code-snapshot`. Chờ quyết định. |
| `f32x8`/`VBuf8` retire | **Đã đo lại 2026-10-14, xác nhận không phải SIMD**: `v_load8`/`v_store8` vẫn phát `ldind.r4`/`stind.r4` từng lane, **213 lệnh IL / 8 phần tử** so với **39** của native scalar, và nhanh hơn scalar chỉ **1.08x**. Muốn SIMD thật thì phải sửa `vector_block.tkv`. Chi tiết: `docs/e_handoff/BAN_GIAO_2026-10-14-PERF-CHECKSUM-V8.md` |
| Nâng `i*4` ra khỏi vòng vector | **KHÔNG ĐÁNG LÀM (đo lại 2026-10-14).** `i*4` vẫn bị tính 3 lần trong IL, nhưng thời gian hai kiểu chỉ khác ~4% (1.23 vs 1.18 ms) vì JIT chịu được `TkvInt`. Đóng lại. |
| Tích hợp SIMD vào `TokenVector.Data` | Handoff ở `Data\SESSION_HANDOFF_SIMD.md`. Chưa làm. |
| **SIMD thật** (thay `Vector4::op_*`) | `f32x4` phát **method call** `Vector4::op_Addition`, `v_*8` phát **lệnh scalar** từng lane — cả hai đều **không phải lệnh vector**. Muốn SIMD thật thì phát `ldind`/`stind` 32 byte liên tục (hoặc `System.Numerics.Vector<float>` với toán tử thô). Việc lớn, chưa bắt đầu |

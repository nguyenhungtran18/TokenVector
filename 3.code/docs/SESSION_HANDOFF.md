# SESSION HANDOFF — TokenVector compiler

Ngày: 2026-09-29. Cổng: **92/92 + negative 15/15 xanh**. **Giai đoạn 2 XONG toàn bộ.**

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

## 3b. `f(*xs)` — xong, và vì sao KHÔNG đổi mô hình arity

Quyết định (đã hỏi user, chọn phương án desugar): TokenVector giữ nguyên **arity
tĩnh**. `f(*xs)` được **nối tại điểm gọi** thành N đối số cố định rồi mới đi tiếp vào
đường `call` sẵn có — nên kiểm tra arity, tham số mặc định và monomorphize vẫn chạy
y nguyên trạng trên danh sách đã nối. Biến `*args` trong **chữ ký** đã có sẵn từ
trước (`Testkit/varargs_py_tree_test.tkv`); đây là `*` ở **điểm gọi**.

Ba vị trí duy nhất phải sửa, đều nhỏ:

1. `il_core.tkv` `_parse_one_call_arg`: `*`/`**` ở đầu 1 tham số → node
   `('star', expr)`/`('star2', expr)`. Nhờ vậy lỗi cũ vớ vẩn
   `khong parse duoc factor tai OP '*'` biến thành lỗi có nghĩa.
2. `il_core.tkv` `_parse_postfix_method`: trước đây parse tham số bằng
   `parse_expr` trực tiếp, nên `Box(5).two(*[1, 2])` (node `method_call_expr`) không
   thấy `*`. Đổi sang `_parse_one_call_arg` như 3 chỗ còn lại — đủ cả 3 vì cả 3 đều
   đặt danh sách tham số ở **cuối** node.
3. `il_codegen.tkv` `_first_pass_collect_locals`: gọi
   `call_star_args.expand_star_args_in_stmts(stmts, func_name=sig.name)` **trước
   first-pass**. Đây là điểm móc duy nhất mà cả hàm top-level lẫn hàm lồng đều đi
   qua, và nó chạy trước mọi logic đọc `stmts` bên dưới. Sửa **tại chỗ** node trong
   cây lệnh nên mọi vị trí gọi hàm đều được hỗ trợ: biểu thức, `y = f(*xs)`, lệnh
   độc lập, method, hàm lồng, và lồng trong mọi biểu thức còn lại.

Nguồn được chấp nhận: `f(*[1, 2, 3])`, và biến `xs = [...]` (kind `assign_list_literal`)
dùng ngay, **không dùng ở chỗ khác**. Cách kiểm chứng độ dài tĩnh: quét cây lệnh, yêu
cầu đúng 1 lệnh gán list literal cho tên đó, và mọi lệnh khác có nhắc tên đều bị từ
chối. Cố tình **siết** thay vì lỏng: sót 1 lần là sinh ra **số tham số sai** — lỗi
âm thầm nếu hàm nhận `*args` hoặc có tham số mặc định. Nguồn động (`[]` + `.append()`,
biến trả về từ hàm) bị từ chối rõ ràng: AOT không thể đếm phần tử lúc chạy mà vẫn
sửa chữ ký `call` lúc biên dịch.

**Bẫy 4 — noi 1 danh sách tham số rồi PHẢI quét tiếp các tham số còn lại.** Bản đầu
tiên chỉ nối rồi `return`, nên `f3(*[1,2,3])` bên trong `str(...)` bên trong
`check(...)` không được nối và lỗi lại quay về "chưa được nối". Sửa: `_expand_args`
map `_expand_node` lên mọi thành phần sau khi nối.

**Bẫy 5 — docstring mở ngoài đóng trong sẽ HẠNG build theo cách rất khó đoán.**
Một `"""` bị bỏ sót trong `il_codegen.tkv` làm PyInstaller **im lặng không đóng gói
`il_codegen`**; exe build xong, chạy cũng không báo lỗi cú pháp, mà chết ở
`ImportError: No module named 'il_features.list_type'` khi nạp thư viện. Kiểm tra
trước khi build:
`python -c "import ast; ast.parse(open(f,encoding='utf-8').read(), filename=f)"`.

**Bẫy 6 — build chậm 90 giay, có cách sửa 2 giây.** `tools/tkvdev.py` (mới) chạy
compiler trực tiếp từ source bằng meta_path finder ánh xạ `<ten>.tkv`, nên sửa
compiler rồi chạy lại là vài giây và **có traceback thật** thay vì thông báo
`[tkv] Loi:`. Dùng nó để lặp nhanh; clean build + `testkit_gate.ps1` vẫn bắt buộc
trước khi commit.

### 3c. `f(**kw)` — xong, gần như miễn phí

Không viết đường phân giải tham số mới: nối `f(**kw)` thành các node
`('kwarg', ten, gia_tri)` — **đúng định dạng `kwarg_resolve` đã xử lý sẵn** từ
Phase 11a. Nên sắp xếp theo chữ ký, lấp tham số mặc định, bắt trùng tên, bắt khoá
lạ, bắt thiếu tham số đều có sẵn và có negative test sẵn. Chỉ phần mới là:
`_kwarg_nodes_from_pairs` (bắt khoá phải là chuỗi literal) và nhánh dict trong
`_static_srcs`/`_expand_args`.

Ba sửa nhỏ nữa:

- `call_star_args.tkv`: `_star_var_names` và `_holds_star_of` trước đó **chỉ nhận
  `('star', …)`**, quên `('star2', …)` — `f(**kw)` với biến báo "không tìm thấy
  nguồn" dù dict literal có sẵn. Sửa cả hai chỗ.
- `syntax_baseline.tkv`: thêm `_collect_star_dict_ids` để `f(**{"a": 1})` không bị
  flag "dict literal with content". Chỉ exemption node dict của keyword `**` nên
  `len({1,2})` vẫn bị từ chối như cũ.
- Xoá negative `star_args_kw.tkv`: sau khi hỗ trợ `**` thì `f1(**kw)` với
  `kw = {"a": 1}` **là chương trình hợp lệ** — test đó chỉ có nghĩa khi `**` chưa
  được hỗ trợ. Đổi lại thành 4 negative mới: khoá lạ, nguồn là list, trùng tên,
  nguồn dict động.

**Lưu ý khi chạy gate:** `Testkit/vector_block_test.tkv` fail **rất hiếm, không tái
hiện** (chạy tay 35/35, chạy lại gate xanh). Đừng vội sửa khi thấy; chạy lại 1 lần
trước.

---

## 4. Còn lại của Giai đoạn 2

**Không còn.** Mọi mục trong bảng Giai đoạn 2 của `PLAN.md` đã XONG, gồm `f(*xs)` và
`f(**kw)` (mục 3b). Việc tiếp theo nếu user muốn tiếp: mục 4 của PLAN (giới hạn có
chủ đích — đừng "sửa" vội), hoặc mục 8 (P6 còn 6/36).

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
| `f(*xs)`, `f(**kw)` | XONG cả hai (desugar khi độ dài/khoá tĩnh) — xem mục 3b |

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
- LAMBDA phải có khai báo chữ ký. `f(*xs)`/`f(**kw)` xong (mục 3b/3c) nhưng nguồn
  phải có **thông tin tĩnh** (độ dài của list, khoá của dict).
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
- **`python tools/tkvdev.py build ...`** (mới) chạy compiler từ source: vòng lặp
  sửa compiler mất vài giây thay vì ~90 giây, và lỗi hiện ra **traceback thật**.
  Dùng để dò; clean build + gate vẫn bắt buộc trước khi commit.
- **`python -c "import ast; ast.parse(open(f,encoding='utf-8').read())"`** cho mọi
  file `.tkv` sửa, **trước** khi build. Một `"""` hở làm PyInstaller im lặng bỏ
  sót `il_codegen`, và exe chết sau đó bằng lỗi hoàn toàn không liên quan
  (`No module named 'il_features.list_type'`) — tốn thời gian vô ích.

---

## 8. Còn lại sau Giai đoạn 2 — đọc trước khi hỏi "làm gì tiếp"

Lộ trình (mục 3 của `PLAN.md`) đã **hết sạch**: Giai đoạn 0, 1 (P6), 2, 3 đều XONG.
Không còn mục tính năng nào đang dở. Còn lại:

**A. Việc thật (không phải roadmap) — nên làm theo thứ tự này**

1. **Lỗi `literal '5' khong dung voi dtype 'Acc'`** (`PLAN.md:128`) — gọi method
   của record với tham số scalar báo sai kiểu. **Chưa điều tra.** Đây là nút thắt
   duy nhất còn lại.
2. **Smoke test cho Inference và Data** (`PLAN.md:132`) — `Testkit/` chỉ phủ
   compiler, hồi quy ở hai hệ thống kia phải mất ~15 commit mới phát hiện. Làm bây
   giờ sẽ **đỏ ngay** vì lý do ở mục 1: rule "record không được có field container
   chưa khởi tạo" làm Inference/Data **không build**. Người dùng đã chọn phương án
   B: cho phép nếu `__init__` có `self.X = ...`. Sửa (1) là mở đường cho (2).
3. **Dạng `c ? a : b`** (`PLAN.md:238`) — dạng `a if c else b` đã có. Dạng `?` chết
   ở `ast.parse` của Python (`tkv_compile.tkv:3854`) trước khi parser TokenVector
   chạy; xương sống front-end **là** AST Python nên tháo ra thì phải viết lại phần
   trích xuất. Cách ít hại nhất đã ghi sẵn: tiền xử lý văn bản `X ? Y : Z` →
   `Y if X else Z` **trước** `ast.parse`. Việc riêng, kiểm thử riêng.

**B. Mục 8 của PLAN — 7 việc treo, cần quyết định riêng, đừng tự ý làm**

| Việc | Tình trạng |
|---|---|
| `tokenvector-grammar` | Working tree bẩn (dirt có sẵn, **không phải do ta**): xoá 1 file đã track + ~15 file scratch. Chọn khôi phục hay chấp nhận. Con trỏ gitlink không đổi. |
| 4 fragment Data | Cần hằng số module (`tokenvector_compute`/`datetime`/`io`/`stats`) |
| Xoá repo con `3.code` | Không hoàn tác được; đã có tag `nested-3code-snapshot` ở parent |
| `f32x8`/`VBuf8` retire | Ghi chú là không phải SIMD nhưng chưa gỡ |
| Nâng `i*4` ra khỏi vòng vector | Còn 6/36 lệnh IL, đổi lại ~17%. Tỷ lệ giá trị/chi phí không tốt |
| Tích hợp SIMD vào `TokenVector.Data` | Có handoff, chưa làm |
| Sửa `SO_SANH_TOKENVECTOR_VS_PYTHON.md` | Khẳng định hỗ trợ `iter()`/`next()` — **sai**, hai hàm đó không tồn tại. User đã nói để sửa tài liệu sau |

**C. Rủi ro vận hành đã biết**

- `Testkit/vector_block_test.tkv` fail **rất hiếm, không tái hiện** (chạy tay
  35/35, chạy lại gate xanh). Khi thấy: chạy lại 1 lần, đừng vội sửa.
- `native_test_suite.tkv` không thuộc cổng và vẫn không build (transpiler tự dựng
  thiếu `yield from`). Đừng dùng nó làm cổng.

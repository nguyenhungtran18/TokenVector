# SESSION HANDOFF — TokenVector compiler

Ngày: 2026-09-30. Cổng: **95/95 + negative 15/15 xanh** + smoke Inference/Data PASS.
**Giai đoạn 2 xong toàn bộ; cả 3 mục "việc thật" ở mục 8A và A' cũng xong.**

**KHÔNG còn việc dở dang** — working tree sạnh, cả hai repo đã mirror.

---

## 0. `__init__` chạy THẬT — mục mới nhất, đọc mục này trước

Trước đây `.ctor` của record **tự gán mọi field từ tham số ctor rồi bỏ qua toàn bộ thân
`__init__`**. Nghĩa là `self.X = <container>` trong `__init__` chết, và cả logic khởi tạo
phụ. Nay `__init__` được biên dịch vào `.ctor` (`42e32c3` + `a87087b`).

Quy tắc an toàn — **chỉ chạy thân khi ánh xạ tham số là 1:1 với field `.ctor`**:
số tham số `__init__` **bằng** số field (kể cả field của base), và kiểu khớp theo thứ tự.
Còn lại **bỏ qua thân** (giữ hành vi cũ) thay vì biên dịch sai âm thầm. Ba trường hợp
hay dính, tất cả đều là bẫy thật:

1. **Field ẩn đứng đầu.** `FP16` khai `_ok` (thuộc tính riêng) rồi `value`, nhưng
   `__init__` chỉ nhận `v`. Kiểu khớp (`i64`/`i64`) nên **check kiểu không bắt được**;
   phải check **số**. Nếu không, `self.value = v & 0xFFFF` ghi từ `_ok` → hỏng
   `quantize_fp16` + `matmul_fp16`. Đây chính là 2 test fail đầu tiên của Inference
   (`awq_asym_and_fp16`, `beam_log_softmax_tree`) — kiểm chứng bằng cách tắt thân
   `__init__`: 26/26. Bài học: khi một feature mới làm hỏng test, **đo bằng công tắc
   tắt trước**, đừng đoán.
2. **Kế thừa.** `.ctor` con có `[field base..., field rieng...]`, `__init__` con chỉ
   khai field riêng → lệch vị trí. Thân `__init__` của **base** vẫn chạy (nó nằm trong
   `.ctor` của base).
3. **Chữ ký không parse được theo DSL.** Ví dụ `min_v: "f32 = -3.4e38"` —
   `parse_default_literal` không nhận dấu `-`. Giá trị mặc định không quan trọng ở đây
   (body không dùng), nên bỏ qua thân là hợp lý.

Lý do bỏ qua được ghi vào `INIT_SKIPPED`, in ra khi `TKV_DBG_INIT=<file>`.

Kèm theo đó, 2 lỗi khác lộ ra và đã sửa:
- **Ternary hai nhánh khác kiểu** (`i32` vs `f32`) trước đây báo lỗi — nhưng hợp lệ,
  và chính compiler sinh ra nó qua macro text (`min(a,b)` → `a < b ? a : b`). Nay
  `_promote_pair_dtype` cho phép chiều lên hợp lệ (i32→i64→int, int→f32→f64, f32→f64).
- **`self.X = {}` trong `__init__`**: node `dict_empty` chỉ có đường `d = {}`. Ở
  `codegen_attr_assign` dùng thẳng `il_type_str` (đọc được container lồng) thay vì
  `il_container_type_of_spec` (chỉ lấy được spec chuỗi).

**Kết quả:** `ext_smoke.ps1` **4/4 BUILD OK** (trước đó 1 pass + 3 known-fail),
`TokenVector.Data` gate **2/2 + 18/18**, `TokenVector.Inference` **26/26 PASS**
(trước đó **không build được**).

---

## 1. Bối cảnh: tập trung compiler, hoãn repo khác

Ban đầu chỉ sửa `3.code`; `TokenVector.Inference` và `TokenVector.Data` bị chặn bởi quy
tắc "record không được có field container chưa khởi tạo" (người dùng đã chọn phương án B).
Ngày 2026-09-30 user đã cho phép sửa cả hai: đã vá Data (`fcdd972`) và Inference (`609ea31`).
Giữ quy tắc đó — chỉ cần thêm `self.X = <container rỗng>` vào `__init__` (215 dòng/53 file).

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

**Không còn.** Mọi mục trong bảng Giai đoạn 2 của `PLAN.md` đã XONG, gồm `f(*xs)`,
`f(**kw)` (mục 3b/3c) và `c ? a : b`. Việc tiếp theo nếu user muốn: mục 8B (7 việc
treo, cần quyết định riêng) hoặc A' (50 field container của Inference/Data).

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
| `__init__` chạy thật | XONG (`a87087b`) — xem mục 0 |

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
- **PyInstaller cache Analysis cũng gây đúng lỗi đó.** Không xoá
  `build\pyinstaller` thì `warn-tkvc.txt` còn ghi `invalid module named il_codegen`
  trong khi file staged parse sạch, và exe hỏng 0/95 trong khi `tools/tkvdev.py`
  (chạy source) vẫn 95/95. Dấu hiệu: **source OK nhưng frozen chết** → xoá cache
  rồi build lại, đừng săn bug trong `.tkv`.
- **`TKV_DBG_INIT=<file>`** ghi ra record nào thực sự chạy thân `__init__` và vì sao
  bị bỏ qua. Nhanh nhất để biết một feature có "chạy âm thầm trên tập con" hay không.
- **Đo bằng công tắc tắt trước khi sửa.** Bật/tắt nhánh nghi ngờ rồi so kết quả
  (tắt thân `__init__` → Inference 26/26, bật → 24/26) là cách nhanh nhất định vị
  lỗi do feature mới gây ra, thay vì đọc lại hàng nghìn dòng IL.

---

## 8. Còn lại sau Giai đoạn 2 — đọc trước khi hỏi "làm gì tiếp"

Lộ trình (mục 3 của `PLAN.md`) đã **hết sạch**: Giai đoạn 0, 1 (P6), 2, 3 đều XONG.
Không còn mục tính năng nào đang dở. Còn lại:

**A. Việc thật (không phải roadmap) — CẢ 3 ĐÃ XONG (2026-09-29)**

1. **Lỗi `literal '5' khong dung voi dtype 'Acc'`** — ĐÃ SỬA (`b1ba163`). Không phải
   lỗi 1 chỗ: **line parser của container cướp mất method của record** khi chưa biết
   kiểu biến. Quét 11 tên method (`add`/`clear`/`extend`/`update`/`sort`/`reverse`/
   `pop`/`insert`/`append`/`remove`/`discard`) thì **4 chức năng hỏng**, sửa cả 4 +
   một fix chung (nap local đã biết là record vào `known_shapes`). Test
   `record_method_name_collision_test.tkv` 18/18. Bản dương của quy tắc (b) — thứ
   PLAN ghi là "chưa viết được" — nay có: `record_container_field_test.tkv`'s
   `container_field_positive`.
2. **Smoke test cho Inference và Data** — ĐÃ CÓ (`tools/ext_smoke.ps1` +
   `ext_smoke_baseline.txt`, commit `ef54bd3`). Build 4 mục, so với kỳ vọng đã ghi;
   exit khác 0 **chỉ** khi regression. Đã kiểm chứng đường regression. Chạy:
   `powershell -File .\tools\ext_smoke.ps1`.
3. **Dạng `c ? a : b`** — ĐÃ CÓ (`60c1d8f`, `compiler/question_ternary.tkv`). Tiền xử
   lý văn bản đổi `X ? Y : Z` → `Y if X else Z` trước `ast.parse`, gọi ở 3 nơi.
   Không đổi số dòng; không chắc thì không ghi đè.

   **Quan trọng hơn tính năng: làm việc này lộ ra 3 bug ternary CŨ, đều im lặng.**
   Bug 3 đáng sợ nhất: local `__ternN` first-pass khai một kiểu, codegen đẩy nhánh
   theo kiểu khác → **sai giá trí, không một lỗi nào**. Đã sửa cả 3 (chi tiết trong
   PLAN mục 4 và commit message).

**A'. Đã xong (2026-09-30)**

- 50 field container chưa gán trong `__init__`: **Data 31** (`fcdd972`) + **Inference 19**
  (`609ea31`, gồm 215 dòng/53 file vì có bản sao). Đây chính là lý do 2 repo kia không
  build. Cả hai nay **build và chạy**: Data gate 2/2 + 18/18, Inference 26/26.

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

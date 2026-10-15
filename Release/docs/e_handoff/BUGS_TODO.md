# TokenVector — danh sách lỗi cần sửa (bản làm việc)

## T. [2026-08-31] 2 gap phát hiện khi viết `RamGuard.tkv` (Task 5, kế hoạch
`docs/superpowers/plans/2026-08-31-ramguard-tokenvector-rewrite.md`) —
CHƯA sửa, ghi lại backlog

Phát hiện trong lúc viết lại app thật `RamGuard` (trim RAM tiến trình)
bằng TokenVector — 2 giới hạn compiler/stdlib, không chặn việc hoàn
thành Task 5 (đã có cách vòng) nhưng nên đóng sau:

1. **[ĐÃ ĐÓNG 2026-08-31]** `int(str)` builtin luôn dùng `Int32::Parse` bất
   kể dtype đích — `compiler/il_features/int_builtin.py` sinh IL gọi
   `Int32::Parse` cứng, gây `OverflowException` THẬT khi ép giá trị lớn
   hơn `i32` (vd `datetime_ticks()` trong `RamGuard.tkv` trả timestamp
   dạng chuỗi số lớn). Đã thêm nhánh `Int64::Parse` khi dtype đích (tham
   số `dtype` truyền vào codegen) là `i64` — xác nhận bằng test thật
   (`test/verify/int_str_i64_overflow_test.py`, giá trị ticks thật
   `639237657423996539` parse đúng, không còn overflow), đồng bộ
   `release/3.code/` + rebuild `tkvc.exe`.
2. **[ĐÃ ĐÓNG 2026-08-31] Chưa có builtin sort cho `array[HandleType]`** —
   TokenVector không có `sorted()`/`.sort()` nào hoạt động trên `array[T]`
   khi `T` là 1 handle-type (`__tkv_extern_class__`). `RamGuard.tkv` cần
   top-N tiến trình theo RAM cao nhất (`array[Process]` từ
   `Process.GetProcesses()`) nên phải tự viết partial-selection sort thủ
   công (O(top_n × count)) để né gap này — xem
   `.superpowers/sdd/progress.md` mục Task 5 để biết chi tiết bug do
   implementer ban đầu bỏ qua bước sort này.

   **ĐÃ ĐÓNG — điều tra xác nhận KHÔNG CÓ GAP THẬT trong compiler, không
   cần sửa code.** Trước khi thiết kế 1 builtin `sort()` tổng quát (cần
   cơ chế key-extractor/lambda mà TokenVector chưa có, rủi ro thiết kế
   lớn), điều tra đường IL sinh ra (`compiler/il_codegen.py`,
   `compiler/il_features/nested_array_extern.py`) cho thấy: dtype
   `'array[T]'` CHỈ tồn tại ở TẦNG KHAI `__tkv_extern_class__` (chữ ký
   tham số/trả về của method .NET thật) — dtype PHÍA TOKENVECTOR của biến
   cục bộ nhận giá trị trả về LUÔN LÀ `'list[T]'` (marshal `T[] <->
   List<T>`, xem `_marshal_extern_return_array`). Do đó `procs =
   Process.GetProcesses()` trong `RamGuard.tkv` thực chất có
   `type_ann.shape == 'list'`, KHÔNG PHẢI `'array'` — và nhánh
   `list`/`_compile_index_store` (`il_codegen.py`) đã dùng
   `callvirt instance void List1<T>::set_Item(int32, !0)` GENERIC HOÀN
   TOÀN từ trước (không tra bảng scalar-only như `IL_STELEM`), nên GÁN
   PHẦN TỬ THEO CHỈ SỐ (`arr[i] = arr[j]`) đã HOẠT ĐỘNG SẴN cho MỌI `T`
   kể cả handle-type — không có gap nào cần vá trong codegen.

   Xác nhận bằng build+chạy THẬT (không mock, DLL C# thật qua `csc.exe` +
   `ilasm.exe` thật): `test/verify/array_handle_type_index_assign_test.py`
   (swap 2 phần tử `list[HandleType]` qua chỉ số, đọc lại đúng) +
   `test/verify/array_handle_type_selection_sort_test.py` (thuật toán
   selection-sort ĐẦY ĐỦ, có swap thật `items[i] = items[best]`, sắp xếp
   giảm dần theo property numeric của handle-type — kết quả khớp CHÍNH
   XÁC thứ tự mong đợi). Cả 2 PASS, không cần sửa `compiler/` (đồng nghĩa
   không cần đồng bộ `release/3.code/compiler/` hay rebuild `tkvc.exe` —
   không có thay đổi codegen nào). Regression: `extern_class_array_handle_
   type_marshal_test.py`, `extern_class_array_marshal_test.py`,
   `process_binding_test.py` đều PASS, không ảnh hưởng.

   **Kết luận thực tế cho `RamGuard.tkv`**: partial-selection sort thủ
   công KHÔNG PHẢI là workaround BẮT BUỘC để né 1 gap compiler — người
   viết `RamGuard.tkv` ban đầu có thể đã không nhận ra `array[T]` trả về
   thực chất là `list[T]` (hỗ trợ gán chỉ số như bình thường) và có thể
   viết selection-sort/bất kỳ thuật toán sort nào trực tiếp bằng code
   `.tkv` thường ngay từ đầu. Không thêm builtin `sort()` riêng (ngoài
   phạm vi, và không cần thiết — gán chỉ số đã đủ để tự viết mọi thuật
   toán sort).

---

## U. [ĐÃ ĐÓNG 2026-08-31] Parser không hỗ trợ `expr[index].property`
(đọc property KHÔNG dấu ngoặc ngay sau 1 index-expression)

Phát hiện khi đơn giản hoá `trigger_direct_trim()` trong `RamGuard.tkv`
(dùng selection sort có swap thật thay cho cách né tránh cũ — xem mục T.2
ở trên). **Sửa lại so với ghi chú ban đầu cùng ngày**: lúc đầu tưởng có 2
case lỗi độc lập (`arr[i].Prop` làm tham số hàm VÀ `var.Prop` khi làm toán
hạng giữa 1 chuỗi `+`) — điều tra kỹ lại (`il_core.py`) bằng file probe cô
lập TỪNG case riêng (bài học: lần đầu dồn nhiều hàm probe vào 1 file rồi
đổi `entry_name` để test riêng — SAI, vì `compile_tkv_cli` parse/biên dịch
CẢ FILE mỗi lần bất kể `entry_name`, nên lỗi ở 1 hàm KHÔNG được chọn vẫn
làm mọi `entry_name` khác trong CÙNG FILE báo lỗi giống hệt, gây kết luận
nhầm phạm vi bug rộng hơn thực tế) xác nhận: **CHỈ CÓ 1 case lỗi thật**,
case còn lại (`var.Prop` dùng trong chuỗi `+`/làm tham số hàm khi `var` là
1 TÊN BIẾN thường) hoạt động ĐÚNG, không cần né.

**Root cause THẬT (đọc `compiler/il_core.py`, xác nhận bằng test cô lập
đúng cách trong 1 file `.tkv` RIÊNG cho mỗi case)**:

- `parse_factor()` (`il_core.py:483-520`) có 1 vòng lặp hậu tố: sau khi
  parse xong 1 "factor gốc" (`_parse_factor_primary()`), nếu gặp `.` NGAY
  SAU và `node[0]` nằm trong `_POSTFIX_METHOD_BASES = ('str_lit', 'slice',
  'index', 'index_expr', 'call', 'method_call', 'method_call_expr')`
  (dòng 462-463), luôn gọi `_parse_postfix_method(node)`.
- `_parse_postfix_method()` (dòng 522-539) **CHỈ hỗ trợ `.method(...)`** —
  ngay sau khi đọc tên định danh, gọi cứng `self.expect_op('(')` (dòng
  530), KHÔNG có nhánh fallback cho trường hợp không có `(` theo sau (tức
  là 1 PROPERTY, không phải method call).
- `'index_expr'` (node sinh ra từ `arr[i]`, `il_core.py:520`) nằm TRONG
  `_POSTFIX_METHOD_BASES` — nên `arr[i].Prop` (không có `()`) LUÔN rơi vào
  nhánh trên và báo lỗi `SyntaxError: ky vong '(', gap ...` tại vị trí đọc
  nhầm (thông báo lỗi không chỉ đúng nguyên nhân thật: nó tưởng đang thiếu
  `(` của 1 method call, chứ không nói rõ "property sau index chưa hỗ
  trợ").
- Ngược lại, `var.Prop` (khi `var` là 1 TÊN BIẾN đơn, node gốc là `'var'`)
  KHÔNG đi qua vòng lặp hậu tố này chút nào — `'var'` không nằm trong
  `_POSTFIX_METHOD_BASES`, và thực ra `.Prop` sau 1 ID đơn được xử lý
  HOÀN TOÀN RIÊNG, ngay trong `_parse_factor_primary()` (dòng 620-653):
  nếu sau `.` KHÔNG có `(` thì trả về `('attr', v, v3)` — 1 node atomic,
  dùng được ở BẤT KỲ ngữ cảnh nào (toán hạng `+`, tham số hàm, so sánh...)
  vì nó không phụ thuộc gì vào phần còn lại của biểu thức. Đây chính là lý
  do `p.ProcessName + "=" + ...` (khi `p` là biến) hoạt động bình thường,
  không cần né.

**Kết luận backlog THU HẸP**: giới hạn thật CHỈ là **"đọc property (không
`()`) ngay sau 1 index-expression"** (`arr[i].Prop`) — KHÔNG phải giới hạn
rộng "property access trong biểu thức phức hợp" như ghi nhầm lúc đầu.
`var.Prop` (biến thường) dùng thoải mái ở mọi ngữ cảnh, không cần né.

**Cách vòng đã dùng** (áp dụng trong `RamGuard.tkv`): gán `arr[i]` ra 1
biến riêng TRƯỚC (`pj = procs[j]`), rồi dùng `pj.Prop` bình thường — không
cần tách property ra biến riêng thêm 1 lần nữa (`pj.Prop` dùng ngay trong
biểu thức lớn hơn được, xem ví dụ đã xác nhận ở trên). Giới hạn tương tự
đã biết trước đó với `.strftime()` (Task 5, chain method SAU 1 lời gọi
hàm khác, không phải index) — cùng họ vấn đề (postfix chain sau
non-`var` node), nhưng KHÁC nhau ở việc `.strftime()` là METHOD (có `()`,
lẽ ra phải hoạt động qua `_parse_postfix_method`) trong khi đây là
PROPERTY (không `()`, hoàn toàn chưa có nhánh xử lý).

**FIX ĐÃ LÀM (2026-08-31, cùng ngày)** — đúng theo hướng đề xuất ở trên:

1. `compiler/il_core.py`'s `_parse_postfix_method`: thêm PEEK token TRƯỚC
   khi đòi `expect_op('(')` — nếu KHÔNG phải `(`, trả về node MỚI
   `('attr_expr', node, name)` thay vì báo lỗi. Giữ nguyên 100% đường
   method-call cũ khi có `(` theo sau (không regress `.strftime()`/
   `.strip().lower()`/`",".join(lst)` — xác nhận bằng test thật).
2. `compiler/il_features/record_feature.py`: thêm `compile_attr_expr` +
   đăng ký `register_expr_codegen('attr_expr', compile_attr_expr)`. Dùng
   LẠI `_method_call_expr_receiver_ta` (đã có sẵn, dùng chung với nhánh
   `method_call_expr` — xử lý cả base là `'index'` (biến+1 chỉ số, case
   THẬT của `RamGuard.tkv`), `'index_expr'`, và fallback qua `_infer_dtype`
   cho `call`/`method_call`/`method_call_expr`) để suy TypeAnn của base
   expression, biên dịch base lên stack (`ctx['compile_expr'](base_node,
   scope, out, obj_ta.dtype, ctx)`), rồi `callvirt instance {ret_il}
   [assembly]class::get_{field}()` trực tiếp trên giá trị đã có sẵn trên
   stack (không qua `scope[name]`/địa chỉ biến như `attr` thường).
   **Phạm vi**: chỉ hỗ trợ `obj_ta.shape == 'extern_class'` (đúng nhu cầu
   thật) — shape khác (record/tuple/dict_kvpair) báo lỗi rõ ràng, gợi ý
   gán ra biến trước (cách vòng vẫn hoạt động, không mất gì).
   Dtype-widening (`bool`→`i32`/`u64`→`i64`/`enum:...`→`i32`) trùng lặp có
   ý thức 3 nhánh nhỏ từ `_tokenvector_facing_dtype` (tkv_compile.py) —
   KHÔNG import trực tiếp để tránh circular import
   (`compiler.il_features` → `tkv_compile` → `compiler.il_codegen` → ...).

**Bug thật thứ 2 tìm ra khi ÁP DỤNG fix vào `RamGuard.tkv`** (cùng ngày,
sau khi đơn giản hoá `trigger_direct_trim()` dùng `attr_expr` trực tiếp):
`_infer_dtype()` (`il_codegen.py`) THIẾU nhánh cho tag `'attr_expr'` — 1
biến MỚI gán từ 1 biểu thức dạng này (`best_ram = procs[i].WorkingSet64`)
bị fallback SAI về `body_dtype` của HÀM ĐANG BIÊN DỊCH (ở đây là
`'OptimizeResult'`, vì `trigger_direct_trim()` trả về record đó) thay vì
dtype THẬT của property (`i64`) — gây lỗi biên dịch hoàn toàn sai chủ đề:
`"'+' tren record can dinh nghia __add__"` cho 1 CÂU LỆNH GÁN không hề có
`+`. Đã thêm nhánh `'attr_expr'` vào `_infer_dtype`, mirror đúng cách
nhánh `'method_call_expr'` đã làm (dùng chung `_method_call_expr_receiver_ta`
+ `EXPR_METHOD_SHAPE`/`EXPR_METHOD_DTYPE`, khoá `('extern_class',
'get_<field>')`) — một nguồn sự thật duy nhất với codegen `compile_attr_expr`.
Xác nhận bằng chạy thật `RamGuard.exe` (top-N log đúng thứ tự giảm dần,
cooldown vẫn chặn đúng), đồng bộ `release/3.code/compiler/il_codegen.tkv`
+ rebuild `tkvc.exe`.

**Test thật** (`test/sample_attr_expr.tkv` +
`test/verify/attr_expr_test.py`, 4/4 PASS): `procs[0].ProcessName` trực
tiếp trong `return`; `procs[0].Id` làm THAM SỐ TRUYỀN TRỰC TIẾP cho
`str()`; gán ra biến rồi làm toán hạng số học (`x = procs[0].WorkingSet64;
y = x + 1`, xác nhận type-inference đúng `i64`, không lệch); dùng làm toán
hạng giữa chuỗi `+` nhiều đoạn. Cả 4 case PASS ở CẢ dev-mode
(`tkv_compile.py`) LẪN bản tự-host `release/3.code/dist/tkvc.exe` (build
qua `--no-lint` — hạn chế linter với dict-literal pragma đã biết từ
trước, không liên quan fix này).

**Regression** (không sửa `IL_SCALAR`, không đụng chỗ nào ngoài
`il_core.py`'s `_parse_postfix_method` + `record_feature.py`'s
`attr_expr`): `extern_class_test.py`, `extern_class_property_test.py`
(13/13), `record_test.py`/`record_method_test.py` (7/7 mỗi file),
`process_binding_test.py`, `computer_info_test.py`,
`array_handle_type_index_assign_test.py`,
`array_handle_type_selection_sort_test.py`,
`list_handle_type_functional_test.py` (9/9),
`method_call_expr_on_index_handle_type_test.py` (5/5 check) — tất cả
PASS, cộng test thủ công `.strip().lower()`/`",".join(lst)` xác nhận
method-chain cũ không bị ảnh hưởng.

Đồng bộ `release/3.code/compiler/il_core.tkv` +
`release/3.code/compiler/il_features/record_feature.tkv` (byte-identical
với `.py`) + rebuild `release/3.code/dist/tkvc.exe`.

**Chưa làm** (ngoài phạm vi fix này, để dành nếu có nhu cầu thật sau):
hỗ trợ `attr_expr` cho `record`/`tuple`/`dict_kvpair` shape (hiện chỉ
`extern_class`); chain tiếp `.property` SAU 1 `attr_expr` khác (vd
`arr[i].Obj.Prop`, 2 tầng) — `'attr_expr'` chưa nằm trong
`_POSTFIX_METHOD_BASES` nên dừng lại sau 1 tầng, đủ cho nhu cầu thật hiện
tại (`RamGuard.tkv` chỉ cần 1 tầng).

---

## S. [ĐÃ ĐÓNG 2026-08-20] `dict[str, list[i32]]` (dict-của-list) — set-item
rồi đọc lại nem `OverflowException: chi so int qua lon: khong vua int32`
lúc CHẠY

Phát hiện tình cờ lúc viết test cho plan `il-type-str-dict-key-error`
(xem `.superpowers/sdd/task-1-report-il-type-str-dict-key.md`, phần Step
3) — KHÔNG liên quan gì tới `il_type_str`/mục F, chỉ là 1 bug độc lập lộ
ra trong lúc thử pattern runtime.

**Root cause THẬT** (xác nhận bằng đọc IL sinh ra, không đoán — 2 lỗi độc
lập cộng dồn):

1. `compiler/il_features/dict_type.py`'s `declare_dict` (FIRST_PASS_WALK):
   khi biến được gán `= {}` rồi index-assign với **giá trị là 1
   list-literal** (`d["a"] = [1, 2, 3]`), và hàm đang biên dịch có chú
   thích TRẢ VỀ là dict-của-container (vd `dict[str, list[i32]]`), hint từ
   chú thích trả về (`_container_arg_hints`, `il_codegen.py`) bị BỎ QUA vì
   điều kiện fast-path cũ chỉ chấp nhận `hint.elem_ta is None`
   (dict-của-SCALAR). Nhánh đoán chung phía dưới
   (`find_first_dict_assign_value_ta`) CHỈ nhận diện giá trị là 1 BIẾN
   tham chiếu tới container khác, KHÔNG nhận diện list-literal — rồi về
   `infer_dtype([1,2,3])` trả dtype PHẦN TỬ (`'i32'`), khiến `d` được khai
   báo SAI thành `Dictionary<string, TkvInt>` thay vì `Dictionary<string,
   List<TkvInt>>`.
2. Ngay cả sau khi `d` được khai báo đúng kiểu (`elem_ta` không None),
   `il_codegen.py`'s `_compile_index_store` truyền `type_ann.dtype`
   (`'__nested__'`, sentinel không có nghĩa) làm ngữ cảnh dtype cho giá
   trị đang GHI — `codegen_expr_list_literal` dùng trực tiếp chuỗi đó làm
   `elem_spec`, sinh `List<'__nested__'>` lỗi (ném `SyntaxError` khi build
   lộ ra, hoặc sai kiểu ngầm nếu build qua được).

**Fix** (commit xem Step Commit bên dưới):
- `dict_type.py`'s `declare_dict`: thêm 1 fast-path THỨ HAI tin hint TRẢ
  VỀ ngay cả khi `hint.elem_ta` không None (dict-của-container), cùng
  tinh thần với nhánh dict-của-scalar đã có.
- `il_codegen.py`'s `_compile_index_store` (nhánh `dict`/`defaultdict`/
  `counter`): dùng `value_dtype_spec_for_ta(type_ann.elem_ta, value_node)`
  (nguồn sự thật CHUNG với tham số/giá trị trả về lồng nhau — xem
  `list_type.py`) thay vì `type_ann.dtype` phẳng khi giá trị đang ghi là
  container lồng nhau (sinh chuỗi mảng-shape `'list[i32]'` đúng thay vì
  sentinel `'__nested__'`).

**Test:** `test/verify/dict_of_list_setitem_test.py` (mới, build+run THẬT,
2 case — 1 key, nhiều key/độ dài khác nhau) — đối chiếu qua STDOUT (runtime
này luôn trả exit-code 0, giá trị `return` của `main()` được in ra stdout
qua `Main()` wrapper). Không còn `OverflowException`, giá trị đọc lại
đúng 100%.

**Phạm vi CHƯA đóng (ngoài phạm vi bug này, phát hiện thêm lúc điều tra):**
`print(m["a"])` (in TRỰC TIẾP 1 giá trị container đọc từ dict-của-list)
vẫn in ra rác — codegen của `print()` cho biểu thức `dict[...]` không tra
`elem_ta` để biết kết quả là 1 List, vẫn coi là scalar và gọi
`TkvStr::I32` nhầm. Đây là gap RIÊNG (codegen `print()` cho biểu thức
index-vào-dict-lồng-nhau, khác hẳn phạm vi set-item/get-item của mục S) —
CHƯA ghi thành mục backlog mới vì `print()` trên 1 container nói chung có
thể chưa từng được thiết kế hỗ trợ (cần điều tra riêng xem đây có phải
tính năng dự kiến hay không trước khi coi là bug).

## R. [ĐÃ ĐÓNG 2026-08-20] Tham chiếu TÊN 1 hàm top-level ở VỊ TRÍ GIÁ TRỊ
(không phải callback) bị coi ngầm là 0, build thành công thay vì báo lỗi

**ĐÃ ĐÓNG** (commit `f6884e2`): repro thật lúc sửa cho thấy hành vi hiện tại
KHÔNG còn là "coi ngầm là 0" (đã lệch so với mô tả gốc, có thể do các fix
mục Q sau đó) mà là **`KeyError` thô không bắt được** — thậm chí tệ hơn
(crash lộ liễu thay vì silent-wrong). Đã sửa: bắt `KeyError` CHỈ tại điểm
gọi `_infer_dtype` trong `declare_scalar`'s nhánh fallback
(`compiler/il_codegen.py`), kiểm khoá bị thiếu có nằm trong `func_table`
không — nếu có, báo `SyntaxError` rõ ràng; nếu không (biến thật sự chưa
khai báo/typo), NÉM LẠI nguyên `KeyError` cũ, không che giấu bug thật.
An toàn với callback hợp lệ (`map`/`filter`/`reduce`): nhánh `'call'` của
`_infer_dtype` chỉ tra dtype theo TÊN hàm gọi, không đệ quy vào tham số,
nên không bao giờ chạm nhánh mới này. Test: Step 12,
`test/verify/duck_typing_infer_test.py` (12/12 PASS) + đối chứng regression
`toplevel_callback_typeinfer_test.py`/`list_handle_type_functional_test.py`
(9/9 cả hai, không ảnh hưởng).

Phát hiện trong final-review của
`docs/superpowers/plans/2026-08-19-two-phase-typeinfer-toplevel-callback.md`
(mục Q) qua test A/B đối chứng shadowing - XÁC NHẬN là hành vi CÓ SẴN TỪ
TRƯỚC (không phải do fix mục Q gây ra, tái hiện y hệt ở commit trước mục Q).

**Tái hiện**: `y = foo + 1` với `foo` là 1 HÀM TOP-LEVEL (không gọi `foo()`,
chỉ tham chiếu TÊN suông, không phải vị trí callback hợp lệ như tham số
`map`/`filter`) - compiler ÂM THẦM coi `foo` như giá trị `0` thay vì báo lỗi
cú pháp rõ ràng ("tên hàm không thể dùng như biểu thức giá trị"). Chương
trình `.tkv` này vốn cũng không hợp lệ theo ngữ nghĩa Python thật
(`UnboundLocalError`/`NameError`), nên đây không phải bug làm sai kết quả
CHƯƠNG TRÌNH ĐÚNG - mà là THIẾU 1 validate reject rõ ràng cho input SAI,
khiến lỗi cú pháp người dùng lọt qua compiler mà không có tín hiệu báo lỗi.

**Không khẩn cấp** - không chặn bất kỳ chương trình `.tkv` hợp lệ nào, chỉ
ảnh hưởng chương trình vốn đã sai. Log lại để 1 phiên sau cân nhắc thêm
validate reject nếu cần siết chặt UX báo lỗi.

---

## P. [2026-08-19] `list[HandleType]` trong `stdlib_aggregates.py`/`stdlib_functional.py`/
`stdlib_itertools_expr.py`/`counter_type.py`/`stdlib_json.py`/`stdlib_random.py`/
`stdlib_sys.py`/`string_split.py`/`set_type.py` — CÙNG LỚP BUG với mục O
(shape==record/scalar thiếu nhánh `extern_class`), phát hiện ngoài phạm vi
Phase 6 `dict[K,V]`, ĐÃ ĐÓNG (2026-08-19)

Phát hiện bởi final whole-branch review (đợt 3) của
`docs/superpowers/plans/2026-08-19-extern-class-dict-container.md`, khi
quét lại toàn bộ codebase tìm điểm gọi `il_list_type(...)` KHÔNG qua
`ctx['il_type_str']`/không truyền `extern_class_defs`, SAU KHI Phase 6 đã
đóng hết các điểm liên quan đến `dict[...]`.

**Ví dụ tái hiện thật**: `sorted(L)` với `L: "list[Sb]"` (Sb là 1 handle
type đã khai qua `__tkv_extern_class__`) nem
`SyntaxError: il_codegen: List phan tu kieu 'Sb' khong hop le` — traceback
tới `compiler/il_features/stdlib_aggregates.py:322`'s `push_sorted`, gọi
`il_list_type(ta.dtype, ctx.get('records'))` KHÔNG truyền
`extern_class_defs` (thậm chí không đọc `ctx.get('extern_class_defs')`
như các điểm khác — thiếu tham số HOÀN TOÀN, không phải chỉ giá trị rỗng).

**Danh sách đầy đủ các điểm cùng pattern** (`il_list_type(..., ctx.get('records'))`
không truyền `extern_class_defs`, tìm qua grep, CHƯA xác nhận từng điểm có
tái hiện được crash thật hay không — chỉ xác nhận `stdlib_aggregates.py:322`):
`stdlib_aggregates.py:178,322`, `stdlib_functional.py:145,146,225,316`,
`stdlib_itertools_expr.py:80,148,149`, `counter_type.py:55,192-194`,
`stdlib_json.py:187`, `stdlib_random.py:147,286,343`, `stdlib_sys.py:35`,
`string_split.py:50`, `set_type.py:29`.

**Vì sao KHÔNG chặn merge của Phase 6**: đây là gap CÓ TRƯỚC Phase 6 (thuộc
phạm vi Phase 5 `list[T]`, KHÔNG phải regression do Phase 6 gây ra) — Phase
6 chỉ chạm tới `dict[...]`, không sửa các file trên. `sorted()`/hầu hết các
hàm trong danh sách trên vốn chỉ có ý nghĩa với dtype vô hướng/so sánh được
(vd `sorted()` cần `IComparable`, 1 handle type .NET tuỳ ý không tự có) —
hành vi ĐÚNG khi gặp `list[HandleType]` ở các hàm này là TỪ CHỐI RÕ RÀNG lúc
validate (thông báo "không hỗ trợ sort trên list chứa handle type"), KHÔNG
PHẢI sinh CIL rồi crash `SyntaxError` khó hiểu như hiện tại — nghĩa là bản
sửa ĐÚNG không đơn giản là "thêm `extern_class_defs`" như các lần trước,
mà cần quyết định: hàm nào NÊN hỗ trợ (thêm `extern_class_defs` giống các
lần sửa trước) và hàm nào NÊN từ chối rõ ràng (thêm validate) — cần 1 phiên
brainstorm/audit riêng, không phải fix cơ học 1 dòng.

**Cập nhật [2026-08-19], Task 2 (Nhóm B) — ĐÃ ĐÓNG một phần**: nhóm B
(`map`/`filter`/`reduce`/`choice`/`shuffle`/`sample`, tương ứng
`stdlib_functional.py:145,146,225,316` + `stdlib_random.py:147,286,343`)
đã được thêm `extern_class_defs` (giống các lần sửa trước) + `il_codegen.py`
(`_il_scalar_or_handle` helper, sửa 3 điểm `IL_SCALAR[...]` trực tiếp không
qua fallback extern_class trong `il_type_str`/`_compile_funcref_arg`) +
`func_table=None` thêm vào 4 chữ ký `return_dtype_fn` còn thiếu
(`_most_common_result_dtype`, `_agg_elem_dtype`, `_choice_dtype_fn`,
`_sample_dtype_fn` trong `counter_type.py`/`stdlib_aggregates.py`/
`stdlib_random.py`). Có test thật xác nhận PASS:
`test/verify/list_handle_type_functional_test.py` — `choice`/`shuffle`/
`sample`/`reduce` với `list[HandleType]` hoạt động ĐÚNG (build + run + output
đúng). `map`/`filter` với callback là TÊN 1 HÀM TOP-LEVEL (không phải biến
`func` đã khai báo) VẪN bị chặn — nhưng do 1 bug ĐỘC LẬP không liên quan gì
`extern_class`/handle-type (bug thứ tự suy kiểu 2-pha
`_probe_names_declared`/`_fpp_assign_scalar`, tái hiện y hệt cả với dtype vô
hướng thuần `i32`) — xem mục Q bên dưới. Phần còn lại của mục P (8 file khác
`stdlib_itertools_expr.py`/`stdlib_json.py`/`stdlib_sys.py`/
`string_split.py`/`set_type.py`, và quyết định "hỗ trợ vs từ chối rõ ràng"
cho `sorted()`) VẪN CHƯA SỬA, giữ nguyên trạng thái out-of-scope residual.
(Cập nhật: trạng thái trung gian này đã được đoạn "ĐÃ ĐÓNG" bên dưới thay thế hoàn toàn — xem cuối mục P.)

**ĐÃ ĐÓNG (2026-08-19)** — xem
`docs/superpowers/specs/2026-08-19-list-handle-type-aggregate-guard-design.md`
+ `docs/superpowers/plans/2026-08-19-list-handle-type-aggregate-guard.md`.
Audit thật xác nhận: 4/10 điểm nghi ban đầu (`stdlib_itertools_expr.py`,
`counter_type.py`, `string_split.py`, `stdlib_sys.py`) là FALSE POSITIVE
(dtype đã bị ép scalar/`'str'` trước khi chạm `il_list_type`, không sửa).
6 điểm (`map/filter/reduce` trong `stdlib_functional.py`,
`choice/shuffle/sample` trong `stdlib_random.py`) được nâng cấp HỖ TRỢ
`list[HandleType]` (thêm `extern_class_defs`, đúng pattern 10 lần sửa
trước). 3 điểm (`sum/min/max/any/all/sorted` trong `stdlib_aggregates.py`,
`json_dumps` trong `stdlib_json.py`) + `set`/`frozenset` (`set_type.py`)
được nâng cấp TỪ CHỐI RÕ RÀNG qua `reject_if_handle_type_elem`
(`list_type.py`) — không còn hàm nào trong danh sách gốc còn crash
`SyntaxError` mơ hồ khi gặp `list[HandleType]`/`set[HandleType]`.

Ghi chú thêm (Task 4, `set_type.py`): ngoài `il_set_type` (thêm tham số
`extern_class_defs`, 4 điểm gọi trong `set_type.py` đã cập nhật), còn phát
hiện 1 điểm gọi THỨ 5 tại `compiler/il_codegen.py`'s `il_type_str`
(dòng ~169, nhánh `shape in ('set', 'frozenset')`) gọi
`il_set_type(type_ann.dtype, records)` KHÔNG truyền `_EXTERN_CLASS_DEFS`
— đây là đường THẬT bị crash khi khai báo local `s = set()` rồi `s.add(a)`
với `a` là handle type (khai báo local qua `_local_il_type`/`il_type_str`,
không qua `set_type.py`'s call site nào cả) — đã sửa cùng lúc, có test thật
xác nhận qua `test/verify/set_handle_type_reject_test.py`.

---

## Q. [ĐÃ ĐÓNG] [2026-08-19] Bug thứ tự suy kiểu 2-pha khi map()/filter()/reduce()
dùng TÊN 1 HÀM TOP-LEVEL làm callback

Phát hiện khi thực hiện Task 2 của
`docs/superpowers/plans/2026-08-19-list-handle-type-aggregate-guard.md`
(mục P, KHÔNG liên quan gì extern_class/handle-type - xác nhận qua test độc
lập dùng dtype vô hướng thuần `i32`, vẫn tái hiện y hệt).

**Tái hiện**: `ys = filter(is_hello, xs)` (hoặc `map`) với `is_hello` là 1
HÀM TOP-LEVEL (không phải biến kiểu 'func' đã khai báo) — biến `ys`/biến
vòng lặp `y` (từ `for y in ys:`) bị suy SAI dtype (`i32`/`shape=None`) thay
vì đúng dtype của phần tử/kết quả callback.

**Nguyên nhân**: `_probe_names_declared` (dùng bởi `declare_scalar`'s cơ chế
defer) không nhận diện tên hàm top-level trong `func_table` - coi như biến
local chưa khai báo, khiến statement bị defer tới `final_pass`. Trong lúc
đó, `_fpp_assign_scalar` (prescan riêng, chạy sớm hơn) xử lý statement khi
phụ thuộc CHƯA sẵn sàng trong `infer_scope`, `_shaped_return_ta_of_call`/
`_map_result_dtype`/`_filter_result_dtype` trả `None`, prescan fallback gán
NHẦM dtype mặc định (`body_dtype` của hàm bao ngoài, thường `i32`). Statement
kế tiếp (vd `for y in ys:` desugar) đọc dtype SAI đó TRƯỚC KHI `declare_scalar`
thật (fpw) kịp ghi đè đúng - và `declared_names` đã đánh dấu nên không được
sửa lại.

**Hướng sửa đề xuất (chưa làm, cần task riêng có kế hoạch kỹ vì đụng cơ chế
first-pass 2 giai đoạn, rủi ro regression rộng)** (thực tế áp dụng CẢ HAI,
không phải chọn 1 - xem đoạn ĐÃ ĐÓNG bên dưới):
1. `_probe_names_declared` (`compiler/il_codegen.py` ~dòng 3299): bỏ qua tên
   nằm trong `func_table` khi kiểm tra node `'var'` (không coi là biến local
   chưa khai báo).
2. HOẶC: `_fpp_assign_scalar`'s fallback khi suy dtype trả `None` (phụ thuộc
   chưa sẵn sàng) nên BỎ QUA gán tạm thay vì gán 1 giá trị SAI có thể bị
   "khoá cứng" bởi statement sau đọc nhầm.

**Không chặn** Task 2/mục P: `map`/`filter`/`reduce`/`choice`/`shuffle`/
`sample` với dtype VÔ HƯỚNG THUẦN hoặc handle-type khi callback là 1 BIẾN
kiểu 'func' đã khai báo (không phải tên hàm top-level trực tiếp) hoạt động
bình thường. Chỉ pattern cụ thể "truyền thẳng TÊN hàm top-level làm callback
cho map/filter" bị ảnh hưởng.

**Cảnh báo mức độ nghiêm trọng**: bug này KHÔNG chỉ suy sai dtype gây crash rõ
ràng — case `map` trong `test/verify/list_handle_type_functional_test.py`
(chỉ assert `build_ok`, không assert output) (đã khôi phục đầy đủ - xem đoạn
ĐÃ ĐÓNG bên dưới) cho thấy BUILD THÀNH CÔNG nhưng sinh CIL SAI ÂM THẦM
(silent-wrong), nguy hiểm hơn crash vì không có tín hiệu báo lỗi nào lúc
build/run — cần ưu tiên cao hơn khi lên kế hoạch sửa.

**ĐÃ ĐÓNG (2026-08-19)** — xem
`docs/superpowers/specs/2026-08-19-two-phase-typeinfer-toplevel-callback-design.md`
+ `docs/superpowers/plans/2026-08-19-two-phase-typeinfer-toplevel-callback.md`.
2 fix độc lập: (1) `_probe_names_declared` bỏ qua tên hàm top-level (trong
`func_table`) khi kiểm tra "biến đã khai báo chưa" — statement không còn bị
hoãn mãi mãi; (2) `_fpp_assign_scalar` không còn fallback về `body_dtype`
khi suy kiểu thất bại — tên vắng mặt trong `infer_scope` được hiểu đúng là
"chưa biết", không còn giá trị SAI bị khoá cứng. `test/verify/
list_handle_type_functional_test.py`'s case `map`/`filter` đã khôi phục đầy
đủ assert output (bằng chứng silent-wrong đã hết).

---

## O. [2026-08-18, ĐÍNH CHÍNH LẦN 2] ĐÃ SỬA điểm thứ 5 CÙNG LOẠI —
audit lần 1 (bên dưới) đã KẾT LUẬN SAI rằng `duck_typing.py:478` là false
positive; review độc lập tái hiện crash thật, đã sửa. Tổng số điểm bug
CÙNG gốc trong lớp này giờ là **5** (không phải 4). Xem "ĐÍNH CHÍNH LẦN 2"
ở cuối mục này trước khi đọc phần audit lần 1 (giữ nguyên bên dưới làm hồ
sơ, nhưng kết luận của nó về điểm thứ 5 KHÔNG còn đúng).

---

## O. [2026-08-18] ĐÃ AUDIT + SỬA XONG (2026-08-18) — điểm thứ 4 CÙNG LOẠI
với 3 lỗi đã sửa ở plan `extern-class-list-container` (#1 Phase 5) đã
xác nhận crash thật và vá; audit rộng toàn `compiler/` không tìm thấy
điểm thứ 5+. **[ĐÍNH CHÍNH 2026-08-18 LẦN 2: kết luận "không có điểm thứ
5+" ở đây SAI — xem mục "ĐÍNH CHÍNH LẦN 2" ở cuối phần O.]**

Trong plan Phase 5 (`list[T]` container trên `__tkv_extern_class__`),
review phát hiện + sửa LIÊN TIẾP 3 lỗi CÙNG 1 gốc: các điểm suy `shape`
của 1 biến local từ dtype string chỉ biết nhánh `shape == 'record'`,
KHÔNG biết `shape == 'extern_class'` — khiến `list[HandleType]`/biến
handle-type suy sai `shape=None`, gây `KeyError`/`SyntaxError` ở
`il_type_str` hoặc tương đương. Đã sửa (commit `f4445da`/`9cfd017`):
(1) `il_type_str`'s dispatcher chính (`il_codegen.py`), (2) 9 file
`il_features/*.py` dùng `il_list_type(...)` trực tiếp thay vì
`ctx['il_type_str'](...)`, (3) `declare_scalar`/`_fpp_assign_scalar`
(nhánh suy shape cho `for item in items:` desugar thành
`item = items[idx]`).

**Điểm thứ 4 — XÁC NHẬN BUG THẬT, ĐÃ SỬA**: `compiler/il_features/list_type.py`,
hàm `fpw_for_in_call_list` (dòng ~544, cho `for x in f(...):` khi `f` là
1 hàm TỰ DO trả về `list[T]` — khác với `for x in <biến>:` đã sửa ở điểm
(3), đi qua nhánh code khác hẳn: `generator_lazy.py`'s `fpw_for_in_generator`
đổi `stmt['kind']` sang `'for_in_call_list'` rồi giao cho `list_type.py`)
dùng CÙNG pattern `elem_shape = 'record' if (...) else None` KHÔNG có
nhánh `extern_class` song song.

Repro xác nhận (script `.tkv`: `__tkv_extern_class__` khai `Sb` (bọc
`System.Text.StringBuilder`), hàm tự do `make_list() -> "list[Sb]"` trả
list 2 phần tử, `main()` viết `for item in make_list(): print(item.ToString())`):
chạy qua `compile_tkv_cli` với code CHƯA sửa (`git stash` 2 file thay đổi)
crash đúng như dự đoán — `KeyError: 'Sb'` tại `il_codegen.py`'s
`il_type_str` (gọi từ `_local_il_type` khi sinh `locals_sig` của `main()`).

Fix: thêm nhánh `extern_class` song song trong `fpw_for_in_call_list`
(kiểm tra `ret_ta.dtype in extern_class_defs` TRƯỚC nhánh `records`,
đúng thứ tự ưu tiên như `declare_scalar`/`_fpp_assign_scalar`). Vì
`list_type.py` KHÔNG được import trực tiếp `il_codegen.py`'s
`_EXTERN_CLASS_DEFS` (circular import, xem docstring đầu file), đã thêm
key `extra_class_defs`... (chính xác: `'extern_class_defs': _EXTERN_CLASS_DEFS`)
vào `walk_ctx` (dict tiêm cho mọi `FIRST_PASS_WALK`, xây trong
`_first_pass_collect_locals`, `il_codegen.py`) để `list_type.py` đọc qua
`ctx.get('extern_class_defs')` — cùng cơ chế "tiêm qua ctx" đã dùng cho
mọi callable khác của `il_features/*.py`, KHÔNG phát minh cơ chế mới.
Test hồi quy: `Case 4` mới trong `test/verify/extern_class_list_test.py`
(build+chạy `.exe` thật, đối chiếu output `Sb.ToString()`/`Sb.Length` qua
`for item in make_list():`) — xác nhận sập đúng lỗi trên với code cũ,
qua với code đã sửa. `OK 4/4`.

**Audit rộng (đã làm xong)**: grep toàn `compiler/` (cả `il_codegen.py`
và mọi file `il_features/*.py`) mọi chỗ `'record' if`/`shape == 'record'`/
`shape != 'record'`. Kết quả — KHÔNG có điểm thứ 5+ nào là bug thật:
- `il_codegen.py` dòng 173/396/434/1209/1787/2237/3455 và
  `record_feature.py`/`typecheck.py`: đều là chỗ TIÊU THỤ 1 shape ĐÃ
  suy xong (dispatch `il_type_str`, chặn `.field`/`.method()` ngoài
  record trong `compile_attr`/`compile_method_call`, dispatch `__len__`
  dunder...) — thiết kế CỐ Ý giới hạn phạm vi cho các hàm đó, ĐÚNG như
  mô tả nhiệm vụ, KHÔNG sửa.
- `compiler/il_features/control_flow.py` dòng 1139/1152/1277
  (`fpw_for_in_iter`, `fpw_with_ctx`): chặn CỐ Ý — iterator protocol
  (`__iter__`/`__next__`) và context-manager (`__enter__`/`__exit__`)
  là tính năng CHỈ record mới có (extern-class KHÔNG khai được các
  dunder này qua pragma `__tkv_extern_class__`), nên guard
  `shape != 'record': raise` ở đây ĐÚNG THIẾT KẾ, không phải lỗ hổng suy
  shape thiếu nhánh.
- `compiler/il_features/duck_typing.py` dòng 478 (`resolve_call_site`,
  gán `new_ta = TypeAnn(ct, 'record' if ct in records else None)` cho
  tham số `inferred` đã resolve): TRÔNG giống pattern lỗi nhưng KHÔNG
  thể tới nhánh `extern_class` — dòng 348 (`_check_constraint`) đã
  `raise TranspileError` NGAY khi `concrete_type in _EXTERN_CLASS_DEFS`
  ("tham số 'inferred' không thể là extern-class handle type"), chặn
  TRƯỚC khi luồng chạy tới dòng 478. Handle-type CỐ Ý không tham gia
  duck-typing (thiết kế đã ghi rõ trong message lỗi) — false positive.

Kết luận (SAI, xem đính chính bên dưới): đúng 4 điểm bug thật cùng 1 gốc
(3 đã sửa từ trước + điểm thứ 4 sửa hôm nay), không còn điểm thứ 5+ nào
sót lại trong `compiler/`.

### ĐÍNH CHÍNH LẦN 2 [2026-08-18] — điểm thứ 5 THẬT, audit lần 1 sai ở
đâu, ĐÃ SỬA

Review độc lập lần 2 KHÔNG chấp nhận kết luận "false positive" ở
`duck_typing.py` dòng 478 và tái hiện được crash thật với repro cụ thể.

**Sai lầm trong lập luận của audit lần 1**: đúng là `_check_constraint`
(dòng ~348) raise `TranspileError` NGAY khi `concrete_type in
_EXTERN_CLASS_DEFS` — NHƯNG audit lần 1 bỏ sót việc `_check_constraint`
CHỈ được gọi BÊN TRONG vòng `for c in constraints.get(p.name, [])`
(`resolve_call_site`, dòng ~467-469). Nếu 1 tham số `inferred` được khai
báo nhưng KHÔNG dùng trong thân hàm — trường hợp HỢP LỆ, chính docstring
của `collect_inferred_constraints` (Task 3) xác nhận tham số `inferred`
không dùng trong body vẫn hợp lệ, chỉ nhận `constraints[p.name] = []`
rỗng — thì vòng `for c in []` không chạy lần nào, `_check_constraint`
KHÔNG BAO GIỜ được gọi cho tham số đó, và luồng rơi thẳng xuống dòng 478
(`new_ta = TypeAnn(ct, 'record' if ct in records else None)`) HOÀN TOÀN
không qua kiểm tra extern-class nào — handle-type lọt qua với
`shape=None`, gây `KeyError` ở `il_type_str` giống hệt 4 điểm trước,
nhưng xảy ra khi CODEGEN THÂN HÀM CHỨA THAM SỐ ĐÓ (không phải lúc gọi
hàm dùng tham số).

**Repro xác nhận** (`.tkv`, chạy qua `compile_tkv_cli` với code TRƯỚC
khi sửa):
```python
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": ["str"], "methods": []},
]

def unused_param(x, y: "i32") -> "i32":
    return y          # x (inferred) KHONG dung trong than ham

def main() -> "i32":
    a = Sb("hello")
    return unused_param(a, 5)
```
Crash đúng như dự đoán: `KeyError: 'Sb'` tại `il_codegen.py`'s
`il_type_str` (gọi từ `_expr_call`, dòng ~2029, lúc sinh `params_il` cho
lời gọi `unused_param(a, 5)` trong `main()`).

**Fix**: thêm kiểm tra `concrete_type in il_codegen._EXTERN_CLASS_DEFS`
VÔ ĐIỀU KIỆN ngay sau khi resolve từng tham số `inferred` trong
`resolve_call_site` (trước vòng `for c in constraints.get(...)`, KHÔNG
phụ thuộc tham số đó có constraint nào hay không) — raise
`TranspileError` cùng nội dung với guard đã có trong `_check_constraint`.
Quyết định thiết kế: chọn phương án **từ chối vô điều kiện** (tham số
`inferred` không bao giờ nhận handle-type, dùng hay không dùng trong
thân hàm đều như nhau) thay vì phương án "cho qua nếu không dùng" —
nhất quán với nguyên tắc đã ghi rõ trong message lỗi gốc của
`_check_constraint` ("handle type khong tham gia co che suy kieu nay")
và với `docs/BUGS_TODO.md` mục M/L — không tài liệu thiết kế nào của dự
án (`docs/superpowers/plans/2026-08-17-duck-typing-inference.md`,
`docs/superpowers/plans/2026-08-18-extern-class.md`) đề cập ngoại lệ cho
"unused", nên chọn mô hình đơn giản nhất/an toàn nhất thay vì tự sáng
tạo một exception mới.

Vị trí sửa: `compiler/il_features/duck_typing.py::resolve_call_site`,
ngay sau dòng gán `resolved_by_param[p.name] = concrete_type`, trước
vòng `for c in constraints.get(p.name, [])`.

Test hồi quy: `test_duck_typing_rejects_handle_type_unused_param` mới
trong `test/verify/extern_class_test.py` (Step F) — dùng chính repro
trên, xác nhận raise `TranspileError` (không crash `KeyError`).

Chạy lại TOÀN BỘ 13 file test liên quan sau khi sửa — TẤT CẢ PASS:
`duck_typing_infer_test.py`, `extern_class_test.py`,
`extern_class_list_test.py`, `extern_class_list_codegen_gap_test.py`,
`extern_class_list_parse_test.py`, `extern_class_property_parse_test.py`,
`extern_class_property_test.py`, `extern_class_parse_test.py`,
`extern_class_typesystem_test.py`, `extern_class_ctor_test.py`,
`extern_class_method_test.py`, `extern_method_test.py`,
`extern_pinvoke_test.py`.

**Bài học về quy trình audit (quan trọng hơn bản thân bug)**: audit lần
1 KHÔNG sai vì thiếu 1 lượt grep — nó đọc ĐÚNG dòng code có guard, nhưng
suy luận SAI về ĐIỀU KIỆN guard đó được thực thi (giả định "constraint
list luôn được duyệt" mà không kiểm tra trường hợp danh sách RỖNG một
cách HỢP LỆ theo đúng thiết kế của chính hệ thống nó đang audit). Đây là
lỗi suy luận (reasoning gap), không phải lỗi phạm vi tìm kiếm (coverage
gap) — nghĩa là 1 audit tương lai CÓ THỂ lặp lại kiểu sai lầm này ở
những vị trí khác nếu chỉ xác nhận "có guard tồn tại" mà không xác nhận
"guard đó chạy trên MỌI đường dẫn control-flow tới điểm nguy hiểm". Do
đó **KHÔNG coi audit lần 1 (hoặc lần 2 này) là đã loại trừ hoàn toàn khả
năng có điểm thứ 6+** — chỉ có thể khẳng định các vị trí ĐÃ kiểm tra lại
kỹ (dòng 478) giờ đã đúng; các vị trí khác trong audit lần 1 (đã liệt kê
ở trên: `il_codegen.py` các dòng 173/396/434/1209/1787/2237/3455,
`control_flow.py` dòng 1139/1152/1277) CHƯA được re-audit theo tiêu
chuẩn "guard chạy trên mọi đường dẫn control-flow" này — nên xem là
CHƯA XÁC NHẬN LẠI, không phải đã loại trừ.

## N. [2026-08-18] ĐÃ AUDIT XONG (2026-08-18) — KHÔNG có bug thật ở các
plan trước. Test isolation ở các plan TRƯỚC có thể vacuous do import
`compiler.il_dispatch` (namespace-package) thay vì `il_dispatch` (flat).

Phát hiện khi review Task 3 của `extern-class-property`: `compiler/`
KHÔNG có `__init__.py`, và `tkv_compile.py` (dòng ~36-38, 67) tự thêm
`COMPILER_DIR` vào `sys.path[0]` rồi import `il_dispatch` theo đường
FLAT (`from il_dispatch import ...`), KHÔNG phải `from compiler.il_dispatch import ...`.
2 đường import này tạo ra **2 module object khác nhau**, mỗi cái giữ
`EXPR_METHOD_CODEGEN`/`EXPR_BUILTIN_CODEGEN` RIÊNG — nếu 1 test viết
`from compiler.il_dispatch import EXPR_METHOD_CODEGEN` để kiểm tra
isolation (assert key đã bị pop sau `compile_tkv_cli`), assertion đó sẽ
LUÔN đúng một cách vô nghĩa (vacuously true) — vì đang đọc dict SAI, không
phải dict `tkv_compile.py` thực sự mutate.

Đã xác nhận và sửa ĐÚNG trong `extern_class_property_test.py` (dùng flat
import). **Đã audit xong (2026-08-18)**: quét toàn bộ `test/verify/*.py`
tìm `from compiler.` import bất kỳ module nào `tkv_compile.py` cũng import
theo đường FLAT (`il_dispatch`, `il_core`, `il_codegen`, `typed_dsl_parser`,
`plugin_loader`, `il_features.*`). CHỈ có 1 kết quả duy nhất ngoài file đã
sửa: `test/verify/syntax_baseline_test.py` import `compiler.syntax_baseline`
— XÁC NHẬN VÔ HẠI vì `syntax_baseline` KHÔNG nằm trong danh sách
`tkv_compile.py` import flat (không có bản sao module thứ 2 để lệch). Mọi
file khác đã dùng ĐÚNG đường flat từ đầu (`extern_method_test.py`,
`extern_pinvoke_test.py`, `extern_class_test.py`, `extern_class_method_test.py`,
...). Kết luận: lỗi này CHỈ xảy ra 1 lần duy nhất (đã sửa), không phải
pattern lặp lại ở các plan trước.

## M. [ĐÃ ĐÓNG 2026-08-20] `extern-class` Task 5 — thiếu test `OperatorConstraint`
reject cho handle type trong duck-typing, không chặn đóng plan.

**ĐÃ ĐÓNG**: thêm `test_duck_typing_rejects_handle_type_operator` (Step G,
`test/verify/extern_class_test.py`, commit `a3f9a19`) — `def add_one(x) ->
"i32": return x + 1` gọi với `x` là handle type, xác nhận `TranspileError`
THẬT (không chỉ suy luận từ guard dùng chung code). PASS.

`compiler/il_features/duck_typing.py::_check_constraint` đã thêm guard
CHUNG (trước cả 3 nhánh `FieldConstraint`/`MethodConstraint`/
`OperatorConstraint`) chặn handle type tham gia duck-typing — đây chính
là fix cho lỗ hổng thật đã phát hiện (trước đây `OperatorConstraint` cho
handle type ÂM THẦM lọt qua, không raise). Test mới
(`test/verify/extern_class_test.py`) CHỈ có case cho `MethodConstraint`
(`x.ToString()`), CHƯA có case cho `OperatorConstraint` (vd `param + x`
với `param` suy ra concrete type là handle type). Vì guard DÙNG CHUNG
logic cho cả 3 nhánh nên khả năng cao vẫn đúng, nhưng nên thêm 1 test
riêng cho `OperatorConstraint` để xác nhận thật (không chỉ suy luận từ
code chung).

## L. [ĐÃ ĐÓNG 2026-08-20] `extern-class` Task 4 — thiếu test cho 2 handle-class
CÙNG tên method KHÁC chữ ký, không chặn việc đóng task (reviewer đã xác
minh đúng qua đọc code, chỉ là gap coverage).

**ĐÃ ĐÓNG**: thêm Test 7 (`test/verify/extern_class_method_test.py`, commit
`a3f9a19`) — `SbA.Foo(str) -> i32` + `SbB.Foo() -> str`, xác nhận THẬT bằng
đọc lại file `.il` sinh ra (`assemble_il_to_exe` ghi cạnh `.exe`, xem
`tokenvector_compile.py`) để kiểm 2 dòng `callvirt` tham chiếu ĐÚNG 2 chữ ký
riêng biệt — mạnh hơn chỉ đọc code vì xác nhận trực tiếp CIL sinh ra. PASS
(14/14).

`EXPR_METHOD_CODEGEN` (đăng ký bởi `compile_method_call`,
`compiler/il_features/record_feature.py`) khoá theo `(shape, method_name)`
— MỌI biến kiểu extern-class đều dùng CHUNG `shape='extern_class'`, khác
giả định ban đầu của plan (khoá theo `(tên_class, method_name)`). Task 4
implement dynamic-dispatch-theo-kiểu-khai-tĩnh: mỗi lời gọi tra
`obj_ta.dtype` (kiểu THẬT của biến receiver, biết tại compile-time) để
lấy đúng chữ ký method của CHÍNH class đó. Đã xác nhận đúng qua đọc code
(reviewer độc lập), nhưng **CHƯA có test case**: 2 handle-class KHÁC nhau
cùng khai method TRÙNG TÊN nhưng KHÁC chữ ký (số tham số/dtype/return
khác nhau) — vd `SbA.Foo(str) -> i32` và `SbB.Foo() -> str`. Nên thêm 1
test tương tự Test 6 (`test/verify/extern_class_method_test.py`) nhưng
với chữ ký thật sự khác nhau, xác nhận `a.Foo("x")` và `b.Foo()` sinh
ĐÚNG 2 dòng `callvirt` riêng biệt, không lẫn lộn.

## K. [ĐÃ ĐÓNG 2026-08-20] `duck-typing-inference` — 2 điểm minor tồn đọng từ
Task 4's fix report (`task4-critical-fix-report.md`), KHÔNG chặn việc đóng
plan `docs/superpowers/plans/2026-08-17-duck-typing-inference.md` — chỉ là
chất lượng thông báo lỗi, không phải silent-wrong.

**Item 2 ĐÃ ĐÓNG** (commit `6e03dd7`): đổi thông điệp lỗi khi `async def`
gọi hàm có tham số `inferred` sang dạng "giới hạn đã biết" thay vì "lỗi nội
bộ" — xác nhận qua repro thật (`async def run(x,y) -> "i32": return
add(x,y)` với `add` có tham số suy kiểu). Test mới: Step 11,
`test/verify/duck_typing_infer_test.py` (11/11 PASS).

**Item 1 ĐÃ ĐÓNG** (commit `676f3ee`): đính số dòng nguồn vào message của
guard `for...in gen_func(...)` bằng cách TÁI DÙNG cơ chế `src_line`/
`source_path` đã có sẵn cho mục đích debug PDB (`stmt['src_line']` gán bởi
`_parse_block`, `ctx['source_path']` — tham số có sẵn của
`gen_il_function`) — KHÔNG phải hạ tầng mới, ngược với ước lượng cũ trong
mục này. Trong lúc thực hiện (spike Step 1 của
`docs/superpowers/plans/2026-08-19-extern-class-list-of-list.md`'s Task 1
kế hoạch riêng) phát hiện `ctx['source_path']` KHÔNG tự động nằm trong
scope tại nơi khởi tạo `walk_ctx` như giả định ban đầu — `walk_ctx` được
khởi tạo trong `_first_pass_collect_locals` (`compiler/il_codegen.py`,
hàm top-level riêng, KHÔNG lồng trong `gen_il_function`) nên phải thread
thêm 1 tham số `source_path: str = None` qua chữ ký hàm này + qua lời gọi
từ `gen_il_function` (không đổi lời gọi từ `gen_il_generator_function` —
nhánh đó biên dịch THÂN của generator, không phải statement `for...in`
gọi generator, nên giữ mặc định `None`, không ảnh hưởng phạm vi sửa).
Kết quả test: `test/verify/fpw_generator_inferred_error_line_test.py`
(4/4 PASS — bao gồm 1 control case statement lồng trong `if` khác, xác
nhận message KHÔNG có số dòng khi `src_line` vắng mặt, không regression)
+ hồi quy `generator_test.py`, `generator_wide_test.py`,
`duck_typing_infer_test.py` đều PASS, không dòng `FAIL:` nào. Giới hạn
còn lại (KHÔNG thuộc phạm vi mục này): statement `for...in gen_func(...)`
LỒNG trong `if`/`for` khác vẫn CHƯA có số dòng — `_parse_block` hiện chỉ
gán `src_line` cho statement TOP-LEVEL trong thân hàm, giới hạn đã biết,
xem control case trong test trên.

1. **Guard `for...in gen_func(...)` (generator có tham số inferred chưa
   resolve) raise `SyntaxError` thô, không bọc thành `CliError` sạch như
   các lỗi khác, thiếu số dòng nguồn.** Vị trí:
   `compiler/il_features/generator_lazy.py`'s `fpw_for_in_generator` (guard
   thêm ở Important fix của `task4-critical-fix-report.md`). Message hiện
   tại: `SyntaxError: il_codegen: goi ham-generator '...' co tham so kieu
   suy tu dong 'inferred' qua 'for v in gen_func(...):' chua duoc ho tro`.
   Đúng về nội dung (rõ ràng, không phải crash âm thầm) nhưng thiếu bọc
   `CliError`/số dòng nguồn như các lỗi biên dịch khác trong compiler —
   người dùng khó định vị dòng lỗi trong file `.tkv` gốc.
2. **Message lỗi khi `async def` gọi hàm inferred gắn nhãn "lỗi nội bộ"
   (nghe như bug compiler) trong khi thực chất là giới hạn CHƯA hỗ trợ.**
   Vị trí: `_expr_call` (`compiler/il_codegen.py`) — khi 1 hàm `async def`/
   `gen_il_generator_function` khác (KHÔNG đi qua `gen_il_function`'s ctx
   đã có 3 khóa `monomorphize_cache`/`pending_monomorphize`/
   `monomorphize_body_of`) gọi 1 hàm có tham số inferred, hiện raise lỗi
   dạng "khong tim thay body goc... trong ctx['monomorphize_body_of']" —
   đọc như lỗi nội bộ/bug compiler. Nên đổi thông báo sang dạng "giới hạn
   CHƯA hỗ trợ" rõ ràng, cùng phong cách với guard `for...in` mới thêm ở
   mục 1 (vd "async def goi ham co tham so kieu suy tu dong ('inferred')
   chua duoc ho tro - gioi han da biet").

## J. [ĐÃ ĐÓNG 2026-08-20] `compiler/syntax_baseline.py` — false-negative nhỏ còn sót
(follow-up, KHÔNG chặn việc đóng plan `docs/superpowers/plans/2026-08-17-
syntax-baseline-linter.md`, phát hiện lúc re-review Task 4)

**ĐÃ ĐÓNG** (commit `fe5ebab`): áp dụng đúng fix gợi ý bên dưới — điều kiện
miễn trừ đổi từ "`v.value` là `Attribute` có `.value` là `Name`" (khớp 3
tầng) sang "`v.value` là `Name` trực tiếp" (khớp đúng 2 tầng). Xác nhận qua
compile THẬT trước khi sửa (`b.a.vals[0]` nem đúng `SyntaxError` như mô tả)
+ 2 test mới trong `test/verify/syntax_baseline_test.py` (86/86 PASS: 3
tầng bị bắt, 2 tầng vẫn được miễn trừ như cũ, không regression).

Nhánh `Subscript` của `_collect_exempt_attr_chains` miễn trừ nhầm chuỗi
attribute **3 tầng** dạng `ten.f1.f2[...]` (vd `v = b.a.vals[0]`), nhưng
macro thật `compiler/il_features/expr_hoist.py::_ATTR_INDEX_RE` CHỈ khớp
đúng **2 tầng** `ten.field[` — lookbehind `(?<![\w.])` chặn khớp giữa chuỗi
dài hơn. Hậu quả: `b.a.vals[0]` compile THẬT lỗi
(`SyntaxError: con thua token khong parse duoc sau bieu thuc: '.'`) nhưng
linter im lặng cho qua (không flag).

Fix gợi ý (1 dòng, đã xác nhận qua compile thật): trong nhánh `Subscript`
của `_collect_exempt_attr_chains` (`compiler/syntax_baseline.py`), bỏ điều
kiện miễn trừ cho chuỗi 3 tầng — CHỈ `ten.field[...]` (`node.value` là
`Attribute` có `.value` là `Name` trực tiếp) mới hợp lệ miễn trừ.

## I. [3/4 ĐÃ ĐÓNG 2026-08-20] Phát hiện 2026-08-10/11 khi viết `Testkit/check_file`

- **[ĐÃ ĐÓNG 2026-08-20] Chuỗi có `\\` (backslash escape) bị cắt cụt lúc
  CHẠY** — repro gốc: `s = "a\\b"; print(s)` biên dịch OK nhưng chỉ in
  `"a"`, mất hẳn `\b`. Kiểm tra lại HÔM NAY bằng build+run THẬT (không
  đoán): 4 dạng escape (backslash đơn/kép giữa chuỗi, ở CUỐI chuỗi, ở ĐẦU
  chuỗi) — TẤT CẢ đều cho kết quả ĐÚNG 100% (khớp chính xác độ dài + nội
  dung kỳ vọng, vd `"C:\\Users\\test"` in đúng `C:\Users\test`, `len` =
  13). **Bug KHÔNG còn tái hiện được nữa** — chưa xác định được commit cụ
  thể nào đã sửa (có thể đã được sửa GIÁN TIẾP qua 1 cải tiến khác về
  string-literal parsing/escape giữa lúc phát hiện 2026-08-10/11 và hôm
  nay 2026-08-20). Ghi lại thành test hồi quy chốt hành vi đúng:
  `test/verify/string_backslash_escape_test.py` (build+run thật, PASS).
- **[ĐÃ ĐÓNG 2026-08-20 — backlog ghi NHẦM] `.find(sub, start_pos)` (2
  tham số, tìm từ vị trí)** — backlog ghi là "KHÔNG được hỗ trợ", nhưng
  kiểm tra lại HÔM NAY bằng build+run THẬT (`compile_str_method_find`,
  `compiler/il_features/string_methods_batch3.py`): tham số 2 `start`
  **THẬT SỰ đã được hỗ trợ từ trước** (docstring hàm đó ghi rõ "Tham số 2
  'start' thêm 2026-08-11 (Phase 1.5)" — SAU thời điểm ghi backlog này
  1 ngày, có khả năng backlog được viết ngay trước khi tính năng được
  thêm, rồi quên cập nhật lại). `"hello world hello".find("hello", 1)`
  build+run cho kết quả `12`, khớp CHÍNH XÁC CPython thật. Test hồi quy:
  `test/verify/str_find_start_pos_test.py` (PASS).
- **[ĐÃ HỖ TRỢ THẬT 2026-09-11 — xem ghi chú cuối mục] String literal chỉ
  chấp nhận `"..."` (nháy kép), KHÔNG chấp nhận `'...'` làm dấu phân
  cách chuỗi** — ~~đây LÀ giới hạn thiết kế CÓ Ý~~ (xem đính chính bên
  dưới), chỉ sửa THÔNG BÁO LỖI:
  `compiler/il_core.py`'s `_tokenize_expr` giờ phát hiện riêng trường hợp
  ký tự không tokenize được là nháy đơn (`'`), báo `SyntaxError` CHỈ
  THẲNG nguyên nhân + hướng sửa ("... CHI ho tro dau nhay KEP, KHONG ho
  tro dau nhay DON ('...') - doi '...' thanh \"...\"") thay vì thông báo
  chung chung `khong tokenize duoc bieu thuc` như trước. Test hồi quy:
  `test/verify/single_quote_string_error_test.py` (PASS).

  **ĐÍNH CHÍNH 2026-09-11 — nháy đơn nay ĐƯỢC HỖ TRỢ THẬT.** Nhãn "giới
  hạn thiết kế CÓ Ý" ở trên là **sai**, và câu kèm ngay sau nó ("ngoài
  phạm vi đóng mục này") cho thấy nó vốn là một quyết định **phạm vi**,
  đưa ra khi đang đóng một mục bug khác — không phải một nguyên tắc ngôn
  ngữ được cân nhắc.

  Đo lại theo mục tiêu tự-host: **2575 chuỗi nháy đơn / 1238 nháy kép**
  trong 6 file lõi của compiler (67,5%). Và quyết định hơn: **parser
  native (P1) đã đọc được nháy đơn từ lâu** — rào chỉ nằm ở
  `il_core._tokenize_expr`, bộ tokenize VĂN BẢN đời cũ trên đường
  codegen. Tức đây không phải "mở rộng ngôn ngữ" mà là **hai bộ tokenize
  trong cùng dự án đang bất đồng**.

  Đã vá: thêm nhóm `STRDON` vào `_EXPR_TOKEN_RE` + hàm
  `_chuoi_don_sang_kep` chuẩn hoá sang nháy kép (bắt buộc, vì văn bản
  token đi THẲNG vào `ldstr` mà IL chỉ đọc nháy kép). `f'...'` vẫn bị
  chặn RÕ RÀNG — macro `fstring.py` chỉ trigger trên `f"`, để lọt thì
  `f'x={y}'` thành chuỗi literal chứa nguyên văn `{y}`: biên dịch trót
  lọt, chạy ra kết quả SAI.
- Không hỗ trợ nối dòng bằng `\` cuối dòng (đã biết từ trước, xem mục
  workaround trong `check_file`) — vẫn là giới hạn đã biết, KHÔNG thuộc
  phạm vi đóng mục này (không phải bug/thông báo lỗi tối, chỉ là cú pháp
  chưa hỗ trợ, chưa có nhu cầu thực tế nào cần).

## H. [ĐÃ SỬA 2026-08-10] Phát hiện khi điều tra lại `lcm_via_gcd` — bug
NGHIÊM TRỌNG, RỘNG HƠN framing cũ nhiều

**Nguyên nhân gốc tìm ra** (đọc IL sinh ra trực tiếp, không đoán):
`_widen_if_needed()` trong `il_codegen.tkv` **cố ý chỉ hỗ trợ 1 chiều**
(widen int→float — docstring ghi rõ "KHÔNG làm chiều ngược lại"). Khi
`return`/gán biến cần ép NGẦM f64→i32 (`return res` với `res` là f64
trong hàm khai bao `-> "i32"`), hàm này **im lặng không khớp nhánh nào,
không emit lệnh CIL nào** — để lại giá trị f64 (8 byte) trên stack nơi
chỗ chứa mong đợi i32 (4 byte) → **lệch kiểu ngay trên CIL stack**, giải
thích 3 dạng sai khác nhau tùy ngữ cảnh (không phải 3 bug riêng biệt, chỉ
là hệ quả khác nhau của cùng 1 kiểu undefined-behavior lúc stack lệch).

**Sửa tại gốc** (không sửa riêng từng điểm gọi như `/`): thêm nhánh
`actual_dtype in _FLOAT_DTYPES and requested_dtype in _INT_DTYPES` vào
`_widen_if_needed()`, dùng `conv.ovf.i4`/`conv.ovf.i8` (cắt cụt về 0 +
ném `OverflowException` nếu vượt phạm vi) — **theo đúng tiền lệ đã có
sẵn** trong cùng hàm cho nhánh `int`→`i32`/`i64` (thu hẹp CÓ KIỂM TRA
runtime, không phải bắt buộc `int()` tường minh). Nhất quán với triết lý
dự án "không lệch âm thầm, chỉ đổi chỗ phát hiện từ lúc biên dịch sang
lúc chạy".

**Đã xác nhận bằng test thật** (`release/3.code/examples/
native_test_suite.tkv`, case `lcm_via_gcd_implicit_narrow`):
- `res = a*b/g; return res` (nguyên bản gây bug) → `12` ĐÚNG.
- `return a/b` trực tiếp → `12` ĐÚNG.
- Số âm: `-7.0/2.0` → `-3` (cắt cụt về 0, khớp Python `int(-3.5)==-3`).
- Tràn số: giá trị vượt phạm vi `i32` → ném `OverflowException` (không
  quấn vòng âm thầm).
- Không regress: `native_test_suite.tkv` 16/16 PASS sau khi sửa.

Framing cũ dưới đây GIỮ LẠI làm hồ sơ tra cứu *quá trình tìm ra* (đọc khi
cần hiểu vì sao/cách điều tra), không còn là việc đang mở:

**Đính chính framing cũ**: bug `lcm_via_gcd` KHÔNG phải "sai 2/47 case" như
`_results.json` ghi — đây là **bug ép kiểu ngầm (implicit narrow) f64→i32
bị hỏng, ảnh hưởng RỘNG bất kỳ chỗ nào dùng `/` trên `i32` rồi gán/return
mà không ép kiểu tường minh**.

**Bản chất thật** (`/` trên 2 số `i32` trả về **f64 THẬT**, đúng ngữ nghĩa
Python `24/2 = 12.0` — ĐÂY LÀ ĐÚNG, không phải bug): vấn đề chỉ xảy ra khi
kết quả f64 đó cần **ép ngầm** về `i32` (vd `return` trong hàm `-> "i32"`,
hoặc gán vào biến đã suy kiểu `i32` trước đó qua ngữ cảnh khác) — MẤT
NGẦM, không lỗi biên dịch, ra kết quả SAI ÂM THẦM tùy ngữ cảnh:

```tkv
def calc() -> "i32":
    p = 24
    g = 2
    res = p / g      # res thuc chat la f64 (=12.0), NHUNG bien duoc suy
                      # kieu i32 do ngu canh ham tra "i32"
    return res        # -> tra ve 0 (SAI, phai la 12)
```
Đã đo thêm 2 biến thể của CÙNG lỗi cho ra 2 dạng sai KHÁC NHAU tùy ngữ
cảnh xung quanh (không nhất quán — dấu hiệu lỗi stack/slot, không chỉ 1
điểm ép kiểu sai đơn giản):
- Khi `g` là THAM SỐ hàm (không phải local): `res` = giá trị của `p` KHÔNG
  đổi (như thể phép chia bị bỏ qua hoàn toàn).
- Khi `p`/`g` đều là local trong 1 hàm riêng biệt gọi qua hàm khác: `res`
  ra **giá trị rác hoàn toàn** (`17821392` — không liên quan input).

**Workaround đã xác nhận hoạt động 100%**: **luôn ép kiểu tường minh**
bằng `int(...)` trước khi return/gán khi biểu thức có `/`:
```tkv
return int(res)   # -> tra ve 12 DUNG
```
Đã test: `to_int(x: "f64") -> "i32": return int(x)` hoạt động ĐÚNG mọi
trường hợp — bug KHÔNG nằm ở việc ép kiểu `int()` tường minh, mà CHỈ ở
đường ép kiểu NGẦM (chỗ gọi hàm nội bộ kiểu `widen_if_needed`/tương tự
khi PHÁT HIỆN cần ép nhưng KHÔNG có lời gọi `int()` tường minh trong
code người dùng).

**Mức độ nghiêm trọng**: CAO — đây là lớp lỗi ÂM THẦM (không báo lỗi biên
dịch, không crash runtime), sai số học cho BẤT KỲ ai viết `x / y` (rất phổ
biến, không phải cú pháp hiếm) rồi dùng kết quả ở ngữ cảnh cần `i32`.
Ảnh hưởng thật đến `manual_chat_math12_test.py`'s `lcm_via_gcd` VÀ khả
năng còn nhiều chỗ khác trong test suite/case study chưa phát hiện ra do
kết quả sai KHÔNG gây crash, dễ bị bỏ sót nếu không đối chiếu số cụ thể.
CHƯA điều tra được vị trí chính xác trong `il_codegen.tkv` gây ra 3 dạng
sai khác nhau tùy ngữ cảnh — cần thêm thời gian bisect qua nhiều test
case nữa để tìm đúng điểm codegen lỗi trước khi sửa được.

## Đã sửa 2026-08-10 (không còn trong danh sách mở)

- ~~4 khối IL thô (`ffi_feature.tkv`'s `FFI_CIL_HELPERS`,
  `dynamic_exec.tkv`, `stdlib_bcl.tkv`, `pycapi_shim.tkv`) hardcode chuỗi
  `"TKVApp"`~~ — **ĐÃ SỬA**. Không ảnh hưởng `compile_tkv_cli`/`dist/
  tkvc.exe` (luôn dùng class_name mặc định `"TKVApp"`), nhưng vỡ khi gọi
  `transpile_program(..., class_name=<khac>)` trực tiếp — đúng cách
  ~12/173 file `test/verify/*_test.py` dùng để lấy IL đối chiếu CPython
  (vd `while_test.tkv` dùng `class_name='WhileProgram'`) → `ilasm.exe`
  lỗi `Reference to undefined class 'TKVApp'`. Sửa bằng 1 điểm tập trung
  (`gen_il_program`, `il_codegen.tkv`): `.replace('TKVApp', class_name)`
  khi ghép cả 4 khối text thô vào chương trình, cộng với sửa từng điểm
  gọi (`out.append(f'call ... {ctx.get("class_name", "TKVApp")}::...')`)
  trong 8 hàm codegen liên quan (c_puts/ctypes_cdll/ctypes_call/
  eval_code/exec_code/re_replace/datetime_now/random_randint/
  py_tuple_new/py_dict_new). Đã build+chạy lại `while_test.tkv` qua
  `transpile_program(class_name='WhileProgram')`: **5/5 khớp CPython**
  (trước đó `ilasm` lỗi ngay). Đã kiểm không regress đường build thật
  (`c_puts`/`re_replace` qua `dist/tkvc.exe` mặc định vẫn đúng).

- ~~`thread_join()` luôn trả về `0`~~ — **ĐÃ SỬA**. Nguyên nhân:
  `compiler/il_features/threading_feature.tkv` dùng `System.Threading.
  Thread` + `ThreadStart` (delegate `void`, không có kênh trả giá trị) —
  giới hạn kiến trúc thật, không phải lỗi codegen vặt. Sửa bằng cách đổi
  sang `Task<T>` (`Task.Factory.StartNew<T>()` — LƯU Ý dùng `Factory.
  StartNew`, KHÔNG dùng `Task.Run()` vì `ilasm.exe` đang dùng assemble
  đối với mscorlib v4.0 (nằm trong thư mục Framework v4.0.30319), không
  có `Task.Run` (chỉ có từ .NET 4.5) — đã xác nhận bằng probe `.il` viết
  tay độc lập, `MissingMethodException` với `Task.Run`, chạy đúng với
  `Task.Factory.StartNew`). Kiểu trả về thật (`T`) được lưu qua
  `ctx['_thread_ret_types']`, gắn theo tên biến gán (`ctx['_assign_target_
  name']`, hook thêm 1 dòng trong `_stmt_assign_scalar`/il_codegen.tkv) từ
  lúc `thread_spawn` tới lúc `thread_join` cùng biến đó. Đã build+chạy lại
  ví dụ 2 luồng trong `SACH_HUONG_DAN...md` Bài 17: ra đúng
  `24999995000000`, khớp CPython 100%.
  **[ĐÃ SỬA 2026-08-31] Giới hạn còn lại (trước đây ghi "chưa tổng quát
  hoàn toàn") — thực ra là BUG THẬT, không chỉ là giới hạn thiết kế**:
  phát hiện lúc benchmark lại README (workload đa luồng FP64) —
  `bench_float_mt.exe` crash thật ngay ở runtime
  (`InvalidCastException: Unable to cast ... Task<Double> ... to ...
  Task<Int64>`), không phải chỉ suy kiểu sai âm thầm. Điều tra bằng cách
  đọc `.il` sinh ra: `StartNew<float64>` đúng (thread_spawn resolve đúng
  worker trả `f64`), nhưng `thread_join` luôn `castclass Task<int64>` dù
  worker là `f64`. Root cause KÉP, sâu hơn ghi chú cũ:
  1. **First-pass**: `EXPR_BUILTIN_DTYPE['thread_join']` là hằng số tĩnh
     `'i64'` — đúng như đã ghi.
  2. **Second-pass (phát hiện mới)**: `ctx['_assign_target_name']` được
     **ĐỌC** trong `threading_feature.py`/`compile_thread_spawn` nhưng
     **CHƯA TỪNG ĐƯỢC GHI** ở bất kỳ đâu trong `il_codegen.py` — dòng
     "hook thêm 1 dòng trong `_stmt_assign_scalar`" ghi ở trên **không hề
     tồn tại trong code thật** (`grep _assign_target_name` chỉ ra 2 dòng,
     cả 2 đều ở `threading_feature.py`, không có ở `il_codegen.py`).
     Nghĩa là `ctx['_thread_ret_types']` LUÔN RỖNG, `thread_join` LUÔN
     fallback `'i64'` — bug (1) "vô hại" trùng khớp với worker `i64` (mọi
     ví dụ tài liệu cũ), nhưng bug (2) khiến ngay cả cơ chế "sửa lại ở
     second-pass" cũng chưa từng chạy thật.
  **Sửa cả 2 nơi** (`compiler/il_codegen.py`):
  - `_first_pass_collect_locals`'s `declare_scalar`: thêm dict cục bộ
    `thread_ret_types` + 2 nhánh đặc biệt cho `thread_spawn`/`thread_join`
    (ghi/đọc dtype thật của worker theo TÊN BIẾN handle, đi qua tuần tự
    đúng thứ tự văn bản của câu lệnh — không dùng `EXPR_BUILTIN_DTYPE_FN`
    vì chữ ký `(args, scope, func_table)` không biết TÊN biến đang được
    gán).
  - `_stmt_assign_scalar`: thêm dòng `ctx['_assign_target_name'] = name`
    THẬT SỰ trước khi gọi `_compile_expr` (nhánh fallback chung) — khôi
    phục đúng ý định ban đầu chưa từng được thực thi.
  **Kiểm chứng**: `test/sample_thread_dtype.tkv` +
  `test/verify/thread_dtype_test.py` (3 test: worker `f64` 2 luồng cộng
  đúng `300.0`, worker `i32` vẫn đúng `200` — không regress trường hợp cũ,
  và 1 test xen kẽ `f64`/`i32`/`f64` trong CÙNG 1 hàm xác nhận tra cứu
  đúng theo từng tên biến, không lẫn lộn giữa các dtype khác nhau) — cả 3
  pass qua dev-mode (`tkv_compile.py`) LẪN `tkvc.exe` tự-host sau khi
  rebuild. Regression suite liên quan (extern_class/record/RamGuard-
  adjacent/array handle-type/attr_expr/i64 overflow) chạy lại sạch, không
  regress. Benchmark FP64 đa luồng (4×2M ops, trước đây crash) giờ chạy
  được thật: TokenVector 65ms (median) vs CPython 1222ms (~18.8×).

## F. Phát hiện 2026-08-10 khi rà soát toàn bộ `release/` (không đọc doc,
kiểm bằng cách chạy thật)

- **[ĐÃ SỬA 2026-08-10] `tkv_compile.tkv`'s `_transpile_extracted()` unpack
  sai số giá trị trả về của `_build_record_methods()`** — hàm đã đổi từ
  trả 2 giá trị sang 3 (thêm `record_methods_own`, dùng đúng ở dòng 1266)
  nhưng lời gọi ở dòng 962 (nhánh `transpile_program`, dùng bởi hầu hết
  test trong `test/verify/` để chạy phía CPython đối chiếu) chưa cập nhật
  theo → `ValueError: too many values to unpack (expected 2)` ngay khi
  gọi bất kỳ chương trình nào có `class` (kể cả không kế thừa). Đây là lý
  do CHÍNH khiến rà soát ban đầu tưởng 58/164 test lỗi compiler thật -
  thực ra phần lớn chỉ là 1 dòng unpack sai. Sửa: `record_methods, _, _ =
  _build_record_methods(...)`.
- **`tools/codestat.exe` crash `InvalidCastException` tại `deepest_indent`**
  khi phân tích file `.tkv` lớn (`compiler/il_codegen.tkv`, 3988 dòng) —
  repro: `codestat.exe compiler/il_codegen.tkv`. Tool này có vẻ chỉ được
  test với file `.py`, chưa test với file `.tkv` thật lớn/phức tạp trong
  chính bộ nguồn tự-host của nó. Chưa điều tra nguyên nhân gốc.
- Test `dist_tkvc_smoke_test.tkv` (chạy TRỰC TIẾP bằng `.tkv`, không cần
  đổi `.py` — vì không `import` module compiler nào, chỉ gọi
  `subprocess` ra `dist/tkvc.exe` có sẵn) tham chiếu `compiler/
  il_codegen.py` làm file mẫu để test — nhưng gói `release/` này compiler
  là `.tkv`, không có `.py` nào tồn tại → assertion fail. Cần sửa lại
  tham chiếu sang 1 file `.tkv` thật, và né bug `codestat.exe` ở trên khi
  chọn file mẫu thay thế.
- **Chạy lại 164 test sau khi sửa `_build_record_methods`**: từ 11/164 PASS
  (thiếu fixture `sample_*.tkv`) → 106/164 PASS (sau khi thêm fixture) →
  vẫn 106/164 sau khi sửa unpack (vì bug unpack chỉ chặn NGAY TỪ ĐẦU,
  sửa xong thì LỘ RA bug TKVApp hardcode ở trên cho ~12 test, cùng ~40
  test khác chưa phân loại nguyên nhân — cần điều tra riêng, không giả
  định tất cả đều là bug compiler thật, vì đã có 2 tiền lệ hôm nay
  (unpack + TKVApp) chỉ là lỗi hạ tầng test, không phải bug compiler.

- **`release/3.code/test/verify/*_test.py` (173 file, bộ test thật của cây
  `.tkv` tự-host) KHÔNG chạy được nguyên trạng như đóng gói** — thiếu toàn
  bộ 113-115 file mẫu (`sample_*.tkv`) mà các test này cần đọc (vd
  `while_test.py` đòi `test/sample_while.tkv`). File mẫu này CÓ đủ ở gốc
  repo (`test/*.tkv`) nhưng KHÔNG được copy vào `release/3.code/test/` khi
  đóng gói — `release/3.code/test/` chỉ có `test/verify/` (test logic)
  chứ không có `test/` (file mẫu ở tầng cha). Hệ quả: ai tải `release/` về
  muốn tự chạy lại bộ test đi kèm sẽ gặp `FileNotFoundError` hàng loạt,
  KHÔNG phải vì compiler sai mà vì thiếu fixture. Chưa quyết định hướng
  sửa (copy 115 file mẫu vào release/ sẽ phình dung lượng đáng kể, hay chỉ
  ghi rõ trong README rằng bộ test cần chạy từ repo đầy đủ, không chạy độc
  lập từ `release/`) — cần hỏi ý kiến trước khi làm.
- **3 bản `tkvc.exe` khác nhau tồn tại trong dự án, không đồng bộ**:
  `dist/tkvc.exe` (gốc), `release/3.code/dist/tkvc.exe`, `TokenVector -
  Only/tkvc.exe`. Xác nhận bằng cách chạy thật: bản thứ 3 vẫn còn bug hằng
  số cấp module đã ghi trong `PARITY_GAPS_2026-08-04.md` (lẽ ra đã sửa ở
  compiler nguồn từ lâu) — nghĩa là KHÔNG ai rebuild lại bản đó sau khi
  sửa. Không có quy trình đảm bảo "1 nguồn chân lý" cho binary phát hành.
- **2 cây compiler (`.py` gốc và `.tkv` tự-host trong `release/`) đã lệch
  bug theo CẢ HAI HƯỚNG**, xác nhận bằng chạy test sống (không phải đọc
  cache `_results.json` cũ):
  - Cây `.py` gốc (129/133 PASS hôm nay): lỗi `group8_expr_test.py`
    (`TypeError: 'tuple' object is not callable` trong
    `stdlib_cjson.py:59 push_json_get_str`, khi `json_get_str()` lồng
    trong biểu thức nối chuỗi khác) — KHÔNG xuất hiện ở cây `.tkv`.
  - Cây `.tkv` tự-host: bug kế thừa field (đã sửa), `ctxpack`/`lcm_via_gcd`
    — KHÔNG xuất hiện ở cây `.py`.
  Kết luận: sửa 1 bên KHÔNG tự động sửa bên kia, cần đối chiếu định kỳ.
  **[KHÔNG CÒN TÁI HIỆN 2026-08-10]** `json_dumps` sai dấu cách (dict,
  list, và ghép trong biểu thức đều đã test qua `dist/tkvc.exe` hiện tại
  — cả 3 case ĐÚNG, khớp CPython compact separator) — con số cũ trong
  `_results.json` đã lỗi thời, không phải bug đang mở.

## E. Phát hiện 2026-08-10 khi viết `release/3.code/e2e_test.tkv`

- **[ĐÃ SỬA 2026-08-10] Method của lớp con truy cập field kế thừa (khai báo
  ở lớp cha) → crash runtime** — `System.MissingFieldException: Field not
  found: 'Dog.name'`. Repro: `class Animal: name: "str" ... class
  Dog(Animal): def fetch(self): return self.name`. Nguyên nhân THẬT (xác
  minh qua debug print trực tiếp vào `_field_owner_class`, không đoán):
  hàm này trong `release/3.code/compiler/il_features/record_feature.tkv`
  đã bị viết lại kiểu BFS (để hỗ trợ đa base cho interface) nhưng LÀM MẤT
  bước trừ field kế thừa trước khi so sánh — dùng thẳng
  `records.get(cur, [])` (danh sách field ĐÃ FLATTEN, gồm cả field kế
  thừa) thay vì chỉ xét field RIÊNG của `cur`, nên luôn khớp ngay ở lớp
  con đầu tiên (`Dog`) thay vì leo lên đúng lớp khai báo (`Animal`). Bản
  `compiler/il_features/record_feature.py` ở GỐC repo (dùng cho `tkv.py`)
  KHÔNG có bug này (hàm dùng vòng `while cur:` đơn giản, có trừ
  `base_fields` đúng) — 2 cây compiler (`.py` gốc và `.tkv` tự-host trong
  `release/`) đã lệch nhau, bug chỉ tồn tại ở bên tự-host.
  Sửa: khôi phục bước trừ field của base (base đầu tiên nếu là list, các
  base sau là interface không đóng góp field) trước khi so sánh
  `field_name`, giữ nguyên phần BFS đa-base. Đã kiểm bằng 3 case (field kế
  thừa trực tiếp qua 1 cấp, qua 3 cấp `A→B→C`, và record không kế thừa để
  chống regress) — cả 3 khớp 100% với CPython thật. Đã rebuild
  `dist/tkvc.exe`, cập nhật `e2e_test.tkv` dùng lại `self.name` trực tiếp
  (bỏ workaround). CHƯA áp bản vá tương tự vào `compiler/*.py` gốc (không
  cần, vì gốc không có bug này) — chỉ sửa trong `release/3.code/compiler/
  il_features/record_feature.tkv`.
- **`str(<gọi hàm trực tiếp>)` không suy được kiểu** — vd `str(inc())` với
  `inc` là closure trả về `-> "i32"` báo lỗi "khong suy duoc kieu cua bieu
  thuc". Không phải bug (đã có thông báo lỗi rõ ràng hướng dẫn gán ra biến
  trước), nhưng nên ghi lại vì không match hành vi Python thật (Python cho
  phép `str(f())` trực tiếp).
- **Constructor tự suy tham số theo TỔNG số field kế thừa, không theo số
  tham số của `__init__` tự định nghĩa** — vd `Dog(Animal)` có
  `__init__(self, name)` (1 tham số, tự gọi `super().__init__(name,
  "Woof")` với hằng số) nhưng gọi `Dog("Rex")` báo "record 'Dog' can 2
  tham so (name, sound), gap 1" — dùng số field thay vì số tham số
  `__init__`. Không phải lúc nào cũng sai (nếu số tham số `__init__` khớp
  số field thì không gặp), nhưng khi `__init__` "che" bớt tham số bằng hằng
  số cố định (pattern phổ biến, vd `Dog(Animal)` mọi con đều "Woof") thì
  không dùng được.

Cập nhật 2026-08-06: **A1, A2, B1–B6 (toàn bộ nhóm A và B dưới đây) đã XONG
VÀ COMMIT**, kiểm bằng compile+run `.exe` thật + `test/verify/` 119/119
xanh. Commit: A1 `964ff3a`, A2+B1 `b6486b5`, B2 `964516c`, B3 `f8527ec`,
B4 `01f747e`, B5 `085d595`, B6 `8362a44`. Việc còn mở đã chuyển sang
`docs/PARITY_GAPS_2026-08-04.md`'s mục "Đợt 1" (chưa kiểm lại) — xem đó
trước khi bắt tay phiên sau, ĐỪNG làm lại các mục A/B ở dưới (đã đóng).

---

Phần dưới đây giữ nguyên làm hồ sơ tra cứu *vì sao*/*cách sửa* — không còn
là việc đang chờ.

---

## A. ✅ XONG 2026-08-04 (`bba8373`, `632cb40`)

| | Nội dung | Trạng thái |
|---|---|---|
| A1 | `il_features/fstring.py` — regex `f"([^"]*)"` khớp nhầm chữ `f` **cuối một chuỗi thường**. `if w == "def" or w == "class":` bị viết lại thành `"de(" … ")class"`, điều kiện **luôn sai, không báo gì**. Là nguyên nhân thật của cả mục 9, 11, 12 trong PARITY_GAPS. | ✅ quét có trạng thái chuỗi thay regex |
| A2 | `il_codegen.py` — `.maxstack` là hằng số 8, nên gọi hàm **≥ 9 tham số** ném `InvalidProgramException` lúc chạy. | ✅ `_max_stack_for()` tính từ thân hàm |
| A3 | **Phát sinh:** A2 chỉ vá `gen_il_function`. Generator đi đường sinh mã KHÁC nên `MoveNext()` và wrapper vẫn giữ hằng số 8 — generator ≥ 9 tham số, hoặc lời gọi 9 đối số *bên trong* generator, vẫn ném `InvalidProgramException`. | ✅ đã đo hỏng trước, sửa, đối chứng đột biến 2/2 |

Test: `parity_traps_test.py` (18/18), `generator_wide_test.py` (2/2), đều đối
chiếu CPython chạy chính file `.tkv` đó.

## A'. ✅ XONG 2026-08-04 — hạ tầng kiểm thử (`1d8c8ac`, `1739232`)

- **`test/run_tests.py`** — trước đó **không có trình chạy nào**. "Tất cả đều
  xanh" luôn là *lời người nói*, không bao giờ là sự thật máy kiểm được. Nay là
  một mã thoát: `python test/run_tests.py`. Nhãn `net`/`native`/`repo` khai báo
  ở `test/verify/_manifest.py`, kèm luật: **chỉ được gán nhãn SAU KHI đã chứng
  minh test đỏ vì môi trường.**
- **`test_office_db.tkv`** mã cứng đường dẫn tuyệt đối vào checkout gốc → chạy
  từ worktree thì `.exe` ghi ra repo gốc còn test tìm trong worktree. Đỏ vĩnh
  viễn, và bộ test lâu nay vẫn lặng lẽ ghi vào checkout chính. Đã dùng đường
  dẫn tương đối.
- **Segfault `dict[str,i32]` làm tham số** (PARITY_GAPS mục 6) — xem mục D.

**Hiện trạng: 117/121 đạt.** Bốn file trượt còn lại đều đã gán nhãn và đã kiểm
chứng là do môi trường (thiếu `sqlite3.dll`; manifest CodeGraph trỏ ra ngoài
TokenVector nên worktree không chạy được).

---

## B. [ĐÃ ĐÓNG — xác nhận lại 2026-08-20] Chưa có bản vá — xếp theo mức thiệt hại

**Đã đóng từ 2026-08-06** (xem ghi chú "Cập nhật 2026-08-06" ở mục E cũ
bên dưới — A1, A2, B1-B6 đã sửa+commit từ lâu, nhưng TIÊU ĐỀ mục này
chưa được cập nhật theo, gây hiểu lầm là còn mở). Xác nhận lại HÔM NAY
(2026-08-20) bằng build+run THẬT cả 6 case (B1 `for k in dict`, B2
`not in` trên set, B3 `d[f(a,b)]=v`, B4 method trên biểu thức, B5
`for x in expr.split()`, B6 `.rfind`) — TẤT CẢ đều hoạt động đúng, khớp
CPython thật. Không mở test/commit mới cho việc này (đã có commit gốc
từ 2026-08-06 nêu trên).

### B1. `for k in dict` — biên dịch được, **chết lúc chạy**

```python
d = {}
d["x"] = "1"
for k in d:          # bien dich OK, chay -> nem exception
    n = n + 1
```

Nguy hiểm nhất trong nhóm này vì **lọt qua khâu biên dịch**. Né: gom danh sách
khoá vào một `list` ngay lúc thêm phần tử. Đã phải né ở `domain.tkv`,
`typegraph.tkv`, `impact.tkv`.

### B2. `x not in <set>` — không parse được

```python
s = set()
if x not in s:       # SyntaxError: con thua token 'not'
```

Với `dict` thì `not in` chạy bình thường; **chỉ `set` hỏng**. Né: dùng `dict`
rồi so `len(d.get(k, "")) == 0`. Gặp khi viết `domain.tkv`.

### B3. `d[f(a, b)] = v` — không parse được

```python
d[cut_at(rest, "\"")] = "1"    # SyntaxError: ky vong ')', gap None
```

Bộ tách chỉ số cắt tại **dấu phẩy bên trong lời gọi hàm** (`idx_str.split(',')`
trong `il_codegen.py`). Thông báo lỗi không gợi ý gì về nguyên nhân. Né: gán ra
biến trung gian. Gặp khi viết `impact.tkv`.

### B4. Method gọi trên BIỂU THỨC (mục 13 cũ)

```python
if blob().find("|a|") >= 0:    # KeyError: 'str' luc bien dich
blob_v = blob()                # dung
if blob_v.find("|a|") >= 0:
```

Chặn ngay lúc biên dịch nên không nguy hiểm, chỉ bất tiện. Thông báo
(`KeyError: 'str'` từ `IL_LDC_OP[dtype]`) không nói gì về nguyên nhân thật —
sửa được thông báo cũng đã đỡ.

### B5. `for x in expr.split(...)` — không dịch được

```python
for ln in doc.split(SEP):      # il_codegen: khong dich duoc dong

rows = doc.split(SEP)          # dung
for ln in rows:
```

Chỉ nhận biến, không nhận biểu thức trong mệnh đề `in` của `for`. Gặp khi
viết `ctxpack.tkv`.

### B6. Thiếu `.rfind`

Chỉ có `.find`. Né: tự quét lấy vị trí cuối (xem `node_file` trong
`impact.tkv`). Nhỏ, nhưng gặp thường xuyên khi cắt chuỗi id.

---

## C. Lớp mù về ngữ nghĩa — không phải lỗi compiler, nhưng ảnh hưởng công cụ

**Hàm truyền như giá trị** không được coi là lời gọi:

```python
pool.submit(_convert_one, src, self.fmt)   # _convert_one KHONG bi tinh la duoc goi
```

Phát hiện khi đối chiếu với Graphify — cả `typegraph` **lẫn trọng tài `ast`**
của nó đều mù, nên nó không hiện ra dưới dạng "sót recall" mà biến mất khỏi
thước đo. Cùng nhóm: `functools.partial`, decorator, bảng dispatch.

Thuộc về CodeGraph nhiều hơn TokenVector, ghi ở đây để không quên.

---

## D. Đợt 1 — xem `PARITY_GAPS_2026-08-04.md` mục 1-8

- ✅ **`dict[str,i32]` làm tham số → segfault** — SỬA 2026-08-04 (`1739232`).
  Nguyên nhân: hàm gọi không có `d[k] = v` nào nên `declare_dict` rơi về
  `body_dtype` (**kiểu trả về của chính hàm đang biên dịch**) cho cả khoá lẫn
  giá trị. Sửa bằng `find_first_dict_arg_param_ta()` — suy từ chú thích tham số
  của hàm nhận.
- ⚠️ **`dist/tkvc.exe` bị regress** so với compiler nguồn — luôn dùng
  `python tkv.py build`.
- 📉 **Dồn chuỗi trong vòng lặp chậm ~68 lần** — hiệu năng, **không phá bất
  biến**, nên không thuộc sổ lệch parity; tách sang tồn đọng hiệu năng riêng.

> **Luôn chạy lại repro TRƯỚC KHI sửa.** Đã kiểm 2026-08-04: `json_dumps` **CÓ**
> thoát ký tự (`_emit_escape_json_string`, `stdlib_json.py:38`) và
> `json_dumps_test.py` đã đối chiếu `json.dumps` thật trên nháy kép/backslash/
> xuống dòng/tab — nhưng **docstring `stdlib_json.py:16` vẫn ghi "string KHÔNG
> được escape"**, và PARITY_GAPS chép lại điều đó. Mã đã sửa 2026-08-03, tài
> liệu thì chưa. Một "giới hạn đã biết" sai cũng là một dạng false-green: nó
> khiến người ta né tránh thứ vốn đang chạy tốt.

---

## Cách làm đã chứng minh có hiệu quả

1. **Đọc IL sinh ra trước khi đoán.** Mục 9/11/12 là một lỗi ghi ba lần; IL
   nói ra nguyên nhân trong ba mươi giây, suy luận từ triệu chứng dẫn nhầm
   sang `compile_boolop` và tốn gần một giờ.
2. **Viết công cụ thật, chạy trên dữ liệu thật.** Cả 5 lỗi nhóm B đều lộ ra
   khi viết công cụ CodeGraph, không lỗi nào do test tổng hợp tìm ra.
3. **Đối chứng bằng đột biến.** Test viết sau khi công cụ đã chạy ổn mà pass
   ngay lần đầu là điều đáng nghi — cố tình làm hỏng rồi xem test có bắt không.

---

## E. [ĐÃ ĐÓNG 2026-08-20] `_known_record_vars` bỏ sót "gán từ hàm khác trả record"

Phát hiện 2026-08-13 lúc review commit `165d116` (iterator protocol
`__iter__`/`__next__`, xem `docs/superpowers/specs/2026-08-13-iterator-protocol-design.md`).

`_known_record_vars` (`compiler/il_codegen.py`, hàm `_expand_macros`, quét
trước khi macro `for_in_list` chạy) hiện chỉ nhận diện 1 biến là "record"
qua 2 dạng:

- (a) tham số hàm có chú thích kiểu record (`sig.params[i].type_ann.shape == 'record'`)
- (b) gán TRỰC TIẾP từ lời gọi constructor record (`r = Res(...)`, khớp
  `record_ctor_re` và `m.group(2) in records`)

**Bỏ sót:** biến record được gán từ 1 HÀM KHÁC trả về record, vd:

```python
r = get_record()      # get_record() tra ve 1 record, khong phai constructor truc tiep
for x in r:            # KHONG duoc nhan la record -> macro for_in_list co the viet nham
```

Hậu quả tuỳ theo record đó có gì:

- Nếu record chỉ có `__iter__`/`__next__` (không có `__len__`/`__getitem__`)
  → lỗi RÕ RÀNG lúc biên dịch/chạy (không có `len()` mặc định). An toàn.
- Nếu record có **cả** `__iter__`/`__next__` **lẫn** `__len__`/`__getitem__`
  (dunder 6.5) → **ÂM THẦM SAI**: macro viết lại thành `range(len(r))`/index,
  duyệt qua index thay vì qua iterator protocol mới — không báo lỗi gì cả.

Cùng bản chất với giới hạn đã biết từ trước của `_known_dict_vars` (xem
mục B1/comment tại `_expand_macros`, dòng ~2033-2041): quét đơn giản,
KHÔNG theo dõi gán-lại/gián tiếp qua lời gọi hàm khác — chấp nhận được vì
phần lớn trường hợp lỗi RÕ RÀNG, nhưng case dunder 6.5 phá vỡ giả định đó.

**ĐÃ ĐÓNG**: thread `func_table` vào `_expand_macros` (cả 3 điểm gọi —
`_gen_async_def`, `gen_il_function`, `gen_il_generator_function` — đều đã
có `func_table` sẵn trong scope, chỉ chưa truyền), thêm case (c): tái
dùng `record_ctor_re` sẵn có, tra `func_table[callee].return_type.shape
== 'record'` để nhận thêm biến. Xem
`docs/superpowers/plans/2026-08-20-known-record-vars-func-return.md`.

Xác nhận bằng repro THẬT trước/sau (không đoán): record có cả
`__iter__`/`__next__` lẫn `__len__`/`__getitem__` (dunder 6.5), gán qua 1
hàm khác trả record, rồi `for x in r:` — TRƯỚC fix output SAI ÂM THẦM
`2997` (999×3, đi qua đường `range(len(r))`/index), SAU fix output ĐÚNG
`60` (10+20+30, đi qua `__iter__`/`__next__` như thiết kế). Test mới
`test/verify/known_record_vars_func_return_test.py` (build+run thật, 2
case — case (c) mới + case (b) cũ làm control không regression, 4/4
PASS). Regression liên quan (`record_test.py`, `record_method_test.py`,
`container_record_test.py`, `duck_typing_infer_test.py`,
`generator_test.py`, `generator_wide_test.py`,
`extern_class_dict_generator_test.py`) đều PASS.

**KHÔNG sửa** `release/3.code/compiler/il_codegen.tkv` (mirror tree
tự-host) dù đề xuất cũ ở trên có nhắc tới — đúng tiền lệ đã thiết lập
xuyên suốt phiên làm việc (mirror tree CỐ Ý không được cập nhật khi sửa
compiler Python-hosted, xem mục S/F ở trên làm ví dụ).

---

## F. [ĐÃ ĐÓNG 2026-08-20] Trùng lặp cơ chế "TypeAnn → chuỗi IL đệ quy" (Phase 7 re-review round 2, 2026-08-19)

**ĐÃ ĐÓNG**: hợp nhất thành `il_container_type_of_spec`
(`compiler/il_features/list_type.py`, xem
`docs/superpowers/plans/2026-08-20-unify-container-il-spec.md` +
`.superpowers/sdd/task-1-report.md`). `_il_list_of`/`_il_ctor_param_type`
giờ là 2 wrapper mỏng gọi vào hàm này — chỉ còn 1 nơi sinh logic đệ quy
`list[`/`dict[`. Investigation (Task 1) xác nhận 3 điểm lệch: (1)
`_il_list_of` thiếu `extern_class_defs` là 1 bug THẬT đang active
(list-literal lồng nhau chứa handle-type build FAIL) — ĐÃ ĐÓNG bằng cách
thêm tham số + thread từ `ctx`; (2) `_il_ctor_param_type` thiếu `records`
là gap có thật trong code nhưng bị validate-level chặn hoàn toàn, không
active — CỐ Ý giữ nguyên (`records=None` cứng), không mở validate (ngoài
phạm vi refactor này, ghi backlog riêng nếu cần record trong container
constructor extern-class sau này); (3) fallback cuối đổi từ `KeyError`
thô sang `SyntaxError` rõ ràng — an toàn, không có test nào phụ thuộc
`KeyError`.

### Bối cảnh gốc (trước khi đóng)

Trước khi hợp nhất, có **hai** implementation riêng biệt của **cùng một**
quy ước "dtype có thể là chuỗi mang shape (`'list[i32]'`,
`'list[list[i32]]'`) → chuỗi IL `List<List<int32>>`":

- `compiler/il_features/list_type.py::_il_list_of` (đường list thuần .tkv)
- `compiler/il_codegen.py::_il_ctor_param_type` (đường extern-class ctor/method)

Cả hai đọc/bóc lớp `list[...]` bằng logic riêng. Đây đúng loại lỗi đã lặp lại
ở Phase 5/6/7: một bên được sửa/mở rộng (thêm lớp lồng, thêm handle-type,
thêm dict lồng) còn bên kia không, gây IL sai âm thầm.

**Đề xuất (đã thực hiện ở round hợp nhất trên):** hợp nhất thành một helper
duy nhất (`il_container_type_of_spec`, đặt ở `il_features/list_type.py`),
nhận `spec` (chuỗi shape) + `records` + `extern_class_defs`, trả chuỗi IL;
hai call site cũ giờ gọi vào đó. Kèm theo helper `ta_list_spec`/
`value_dtype_spec_for_ta` (thêm ở round 2) là nguồn duy nhất sinh chuỗi
shape từ `TypeAnn`.

### Phạm vi ĐÃ ĐÓNG và phần CÒN LẠI (final-review round 3, 2026-08-20)

Phần "chỉ còn 1 nơi sinh logic đệ quy" ở trên **chỉ đúng trong phạm vi
domain "chuỗi shape" (`spec: str` như `'list[i32]'`)** - domain của
`il_container_type_of_spec` và 2 wrapper `_il_list_of`/`_il_ctor_param_type`.

Vẫn còn một cơ chế đệ quy container→CIL THỨ BA, KHÁC domain, KHÔNG thuộc
phạm vi round hợp nhất này: `il_type_str` (`compiler/il_codegen.py:155-190`)
đệ quy trực tiếp trên object `TypeAnn` (không phải chuỗi shape), dùng bởi
đường codegen list-literal cấp câu lệnh
(`codegen_assign_list_literal`/`codegen_assign_list_new`/
`codegen_list_append`) - KHÔNG phải đường expression-level mà
`_il_list_of` xử lý. Đây là twin ở domain `TypeAnn`, cố ý ngoài phạm vi
refactor này (khác kiểu input, đổi sang chuỗi shape sẽ là 1 refactor rộng
khác, rủi ro cao hơn).

**ĐÃ ĐÓNG (2026-08-20, commit `0d7fbd1`):** nhánh dict-key của
`il_type_str` từng gọi thẳng `IL_SCALAR[type_ann.key_dtype]`
(`il_codegen.py:188`) - ném `KeyError` thô nếu `key_dtype` không phải
scalar hợp lệ, trong khi `il_container_type_of_spec` (hàm vừa hợp nhất)
đã đổi sang ném `SyntaxError` rõ ràng cho trường hợp tương đương. Đã đổi
sang gọi `il_list_elem_ilstr(type_ann.key_dtype, records, _EXTERN_CLASS_DEFS)`
(cùng khối xây dựng chung `list_type.py`) - input hợp lệ cho kết quả giống
hệt (`IL_SCALAR.get(dtype)` là nhánh đầu tiên của hàm đó), input không hợp
lệ giờ báo `SyntaxError` rõ ràng thay vì `KeyError`.

Điều tra thật (spike compile, không đoán) trước khi sửa: quét toàn bộ
call site tạo `TypeAnn(shape='dict', elem_ta=...)` trong compiler
(`typed_dsl_parser.py`'s `parse_type_ann` dòng ~225 kiểm tra
`k_val not in DTYPES` TRƯỚC khi tạo `TypeAnn`; 2 call site còn lại hardcode
`key_dtype='str'`) - xác nhận nhánh `key_dtype` không hợp lệ là **dead
code thật sự**, không có đường build nào chạm tới. Sửa an toàn (không đổi
hành vi đường hợp lệ nào) nhưng không chứng minh được bằng test
build-fail-trước/pass-sau; test hồi quy
(`test/verify/il_type_str_dict_key_error_test.py`) chỉ xác nhận đường hợp
lệ (`dict[str, list[i32]]` làm kiểu trả về hàm) không regression.

## Parser native: bytes literal chua dien giai escape (phat hien 2026-09-09)

`b"AB\x00C"`: parser native tra `b'AB\x00C'` (giu nguyen hai ky tu `\` va
`x`), CPython tra `b'AB\x00C'` (mot byte NUL that). Lo ra khi them
`test/sample_p8_raise_yield.tkv` cho P8 Task 3/4 - `ast_compat_test.py` doi
chieu 1096 file, lech dung 1.

Loi CO SAN, khong lien quan P8 (duong parse khong bi P8 cham toi). Mau da
duoc ha xuong `b"ABC"` de khong chan tien do; **chua sua goc**. Khi sua, kiem
ca cac escape khac (`\n`, `\t`, `\`) trong bytes literal, va them mau doi
chieu vao ast_compat_test.

## Thong bao loi LAC DE khi lap tren file handle (phat hien 2026-09-09)

`with open(p, "r") as f:` roi `for dong in f:` - compiler bao:

    kieu 'r' khong hop le cho tham so/tra ve cua 'func(...)' - phai la dtype
    vo huong hoac 1 handle type da khai qua __tkv_extern_class__

Nguyen nhan that la "chua ho tro lap truc tiep tren file handle", nhung thong
bao noi ve kieu tham so HAM va nhac `__tkv_extern_class__` - nguoi doc se di
tim sai cho hoan toan. Nhanh phan tich da di nham truoc khi kip nhan ra cu
phap khong ho tro.

Lo ra khi viet `test/sample_p8_try_with.tkv` cho P8 Task 3/4 (mau da doi sang
`f.read()`). CHUA sua. Khi sua: nhan dien som "bien la file handle" o nhanh
`for ... in <bien>` va bao dung thu ("chua ho tro 'for x in <file>', dung
f.read() roi tach dong").

## 25 file cong IL khong bien dich duoc - DA PHAN LOAI (do 2026-09-09)

Con so 25 nay KHONG doi suot ca 8 lo cua P8 Task 3/4, tuc chung hong TU TRUOC
P8. Nhung no cung nghia la 25 file nam NGOAI tam kiem chung cua cong - neu mot
kind chi song trong dam do thi cong khong noi gi ve no. Da do de biet ro:

- **6 file: import module helper** (`_file_io_helpers`, `_json_helpers`,
  `_repeat_helpers`, `_re_helpers`) - sample_file_io, sample_json,
  sample_repeat, sample_stdlib_re, sample_read_file_crlf, sample_except_finally.
- **~~~6 file: record khong co method~~ - PHAN LOAI SAI, DA SUA 2026-09-10.**
  Method ke thua KHONG thieu. Nguyen nhan that: `transpile_file` giai nen
  `record_bases` vao `_rb` roi **VUT DI** - `_transpile_extracted` khong he
  nhan no, nen `_build_record_methods`/`gen_il_program` chay voi bang ke thua
  RONG tren duong do. Method ke thua vi vay TRONG NHU khong ton tai.

  Sau khi luon `record_bases` xuong (lo B cua plan da-hinh-record), **7 file
  het chan**: sample_inheritance, sample_multi_inherit, sample_user_exception,
  sample_container_fields, sample_duck_typing, tools/tkvcalc, tools/tkvcalc_ast.
  Cong IL: "khong bien dich duoc ca hai" **17 -> 10**.

  BAI HOC: day la LAN THU HAI cung mot lo hong o CUNG mot ham. Lan thu nhat la
  `extern_classes` (vá o P8 Task 7) - cung hinh dang: gia tri duoc giai nen roi
  bo di, khong ai bao. Va vi cong IL dung chinh `transpile_file`, ca hai lan
  deu lam mot mang hanh vi nam NGOAI tam kiem cua cong.

  CANH BAO CHO NGUOI SAU: khi mot nhom file "khong bien dich duoc", dung tin
  ngay thong bao loi de phan loai NGUYEN NHAN. Thong bao noi "khong co method"
  hoan toan that - no chi khong noi VI SAO khong co.
- **~7 file: extern-class / pinvoke** can pragma/ngu canh rieng.
- **~6 file: mau AM tinh** (co y khong hop le: sample_set_annot_neg,
  sample_user_exception_neg, ...).

### Phat hien dang chu y: 5 trong 17 FAIL NEN cung MOT goc

`file_io_test.py`, `read_file_crlf_test.py`, `repeat_test.py`,
`stdlib_re_test.py`, `except_finally_test.py` - ca nam deu FAIL o NEN, va deu
dung nhom "import module helper" tren.

Cac helper la module CPython CO Y (docstring cua chung noi ro: "de file .tkv
van la Python THAT chay duoc ma khong bi hieu nham la than ham can bien dich").
Chung khong co annotation kieu TokenVector. Khi them `test/verify` vao sys.path
thi compiler TIM THAY module va co gang TRANSPILE no -> "thieu return-type
annotation". Tuc duong `import` nay dang KHONG duoc bo qua nhu docstring mo ta.

CHUA SUA - ngoai pham vi Task 3/4. Nhung day la mot goc chung cho gan MOT PHAN
BA so FAIL nen, dang uu tien khi quay lai don FAIL nen.

## Handle type khong dung duoc lam THAM SO cua `func(...)` trong field record (2026-09-09)

Thong bao loi cua chinh compiler quang cao rang duoc:

    kieu 'X' khong hop le cho tham so/tra ve cua 'func(...)' - phai la dtype
    vo huong hoac 1 handle type da khai qua __tkv_extern_class__

Nhung khi lam that:

    __tkv_extern_class__ = [{"name": "Ctx", "assembly": "mscorlib",
                             "class": "System.Text.StringBuilder",
                             "ctor": [], "methods": []}]
    class Reg:
        stmt_codegen: "dict[str, func(i32, Ctx)->void]"

-> `KeyError: 'Ctx'` tai `il_codegen.py:257` (`_EXTERN_CLASS_DEFS[type_ann.dtype]`
trong `il_type_str`). Handle type DA duoc nhan dien (shape='extern_class')
nhung `_EXTERN_CLASS_DEFS` chua co ten do luc sinh IL cho FIELD cua record -
mot van de THU TU/luong du lieu, khong phai gioi han thiet ke.

VI SAO DANG GIA: day co the la duong RE NHAT de `il_dispatch.tkv` bien dich
duoc ma KHONG phai bien `ctx` thanh record (rao R1, ~1264 cho dung). Neu handle
type duoc luong dung qua duong nay thi `ctx`/`scope`/`sig` khai duoc nhu tham
chieu DUC ngay, va 11 bang con lai cua Registry khai kieu duoc.

Lo ra khi do R1 (P8 Task 7). CHUA sua.

## `in` khong chay tren FIELD cua record (2026-09-10)

`_expr_in` (il_codegen.py:1887) tu choi khi ve phai khong phai node 'var':

    if name in reg.expr_builtin_codegen:   # ('attr', 'reg', '...') -> LOI
    tbl = reg.expr_builtin_codegen         # bi danh cuc bo -> chay duoc
    if name in tbl:

Loi: "'in' hien CHI ho tro kiem tra tren 1 bien dict/set/list/chuoi don".

Gap trong il_dispatch.tkv bang BI DANH CUC BO (dict la tham chieu nen khong
sao chep, ngu nghia giu nguyen) - CHUA sua o ngon ngu. Chi co DUNG MOT cho
can no trong toan bo il_dispatch, nen chua du ap luc de doi lo codegen.

## Handle type mo khoa TRUYEN QUA, khong mo khoa DOC TRUONG (2026-09-10)

Bai hoc gom lai sau khi go 7 rao cua il_dispatch.tkv:

- `TkvFn` NUOT DUOC moi chu ky ham - da kiem chung CHAY THAT (hai chu ky
  khac nhau qua mot tham so `dict[str, TkvFn]`, lay ra goi lai, dung ket
  qua). Vi khong ai DOC gi ben trong no.
- `TkvTypeAnn` thi VO DUNG cho `return_ta.shape` - handle khong co truong.

Nghia la handle type giai quyet duoc MOI cho chi CHUYEN TIEP gia tri, va
KHONG giai quyet duoc cho nao DOC trang thai. Rao R1 (ctx/scope/Signature/
TypeAnn thanh record that) chi con can cho nhom thu hai.

Trong il_dispatch.tkv nhom thu hai chi con **3 cho**, deu tren `return_ta`
trong `register_expr_builtin` (dong ~310/315/316).

CANH BAO: KHONG "sua" bang cach khai `shape`/`dtype` lam property cua
TkvTypeAnn trong pragma - se sinh IL goi property getter tren System.Object
von khong ton tai. XANH luc build, CHET luc chay.

## Da hinh record: isinstance giai TINH (THIET KE), nhung che do HONG thi im lang (2026-09-10)

Do khi kiem "P7 can gi" - thu that bang 3 probe (scratchpad/probe_poly*.tkv):

| Phep thu | Ky vong | Thuc te |
|---|---|---|
| `isinstance(a, Name)` truc tiep | OK | **OK** |
| Truyen `Name` qua tham so kieu `Node` roi `isinstance(n, Name)` | 1 | **0** |
| `ds = [a, b]` tron `Name` voi `Num` | chay | **ArrayTypeMismatchException** |

Ke thua record BIEN DICH DUOC va TRONG NHU DANG CHAY (`class Name(Node)`
nhan du ca field cua Node), nen rat de tuong la dung.

DINH CHINH (doc codegen 2026-09-10, sau khi ghi muc nay): day KHONG PHAI BUG.
`compiler/il_features/typecheck.py` noi thang trong docstring tu Phase 4
(2026-08-11): "TokenVector la static-typed ... nen ca 3 ham nay duoc GIAI QUYET
HOAN TOAN LUC COMPILE, khong co runtime type check that: isinstance/issubclass
tra ve HANG SO True/False (ldc.i4)". `push_isinstance_builtin` sinh dung mot
lenh `ldc.i4.0/1`.

CAI HONG THAT SU khong phai thiet ke ma la CHE DO HONG: khi code phu thuoc da
hinh luc chay, compiler KHONG canh bao gi - no gap hang so sai roi chay tiep
(truong hop 2), hoac de chuong trinh chet giua chung (truong hop 3). Mot thiet
ke "giai quyet luc compile" nen TU CHOI ro rang o cho no khong dien dat duoc,
thay vi tra loi sai.

CO CHE: `isinstance` giai TINH theo kieu KHAI BAO chu khong theo kieu luc CHAY. `isinstance(a, Node)` dung vi
`a` tinh la Name; `isinstance(n, Name)` sai vi `n` tinh la Node. Chieu NANG
KIEU mat danh tinh. Loi list la van de rieng: codegen sinh mang KIEU CU THE.

MUC DO NGUY HIEM: truong hop 2 KHONG bao loi gi ca - bien dich xanh, chay
xong, rc=0, in ra mot con so hop ly va SAI. Khong co luoi nao trong repo bat
duoc vi khong mau .tkv nao dung isinstance.

HE QUA CHO P7: phuong an 1 cua spec (muc 8septies - viet lai _ast_compat
thanh 46 lop node tinh) DUA HAN vao da hinh nay: doc AST la "duyet list node
tron kieu roi isinstance de phan nhanh", dung 134 cho. Phuong an 1 KHONG DI
DUOC cho toi khi da hinh record duoc sua.

### Chi phi mo da hinh luc chay - DA DO (2026-09-10)

Tin tot: **record DA duoc sinh thanh lop CIL that voi `extends <Base>`**
(`il_codegen.py:4944`), tuc CLR DA san thong tin kieu luc chay - compiler chi
dang khong dung. Khong co MOT `isinst`/`castclass` nao trong toan bo codegen.

Ba phan viec, do lon RAT khac nhau:

1. **isinstance thanh runtime** - doi `push_isinstance_builtin`
   (typecheck.py:47-65) tu `ldc.i4` sang `isinst <Class>`. NHO (~15 dong, 1
   ham). RUI RO: doi ngu nghia cho code hien co dang dua vao hang so.
2. **Container tron lop con** - element type phai la BASE CHUNG
   (`List<Base>`), hien suy tu phan tu dau nen `[Name, Num]` chet
   ArrayTypeMismatchException. VUA - cham suy kieu list.
3. **THU HEP KIEU sau isinstance** (`if isinstance(x, T): x.field`) - can kieu
   NHAY CAM THEO LUONG trong _Scope + sinh `castclass`. LON, la tinh nang he
   kieu that su.

Phan 3 moi la thu 134 cho consumer can: do `tkv_compile.py` toan la
`isinstance(node, ast.Assign)` roi `node.targets`/`node.value` (dem: targets
26, value 24, id 5, decorator_list 5...).

KET LUAN: day la mot PHA ngon ngu co do lon ngang Task 3/4, khong phai mot ban
va. Dung uoc luong no la "sua bug".

## Vong lap duyet TO TIEN record co BA ban (2026-09-10)

- `duck_typing._ancestors(record_bases, ten)` - tra ve TAP.
- `operators.compile_binop` - lap lai cung vong lap TRUC TIEP (xem docstring
  cua `_ancestors`).
- `list_type._chuoi_to_tien(record_bases, ten)` - tra ve CHUOI CO THU TU
  (them 2026-09-10; can thu tu de lay to tien GAN NHAT, ban tra ve tap khong
  dung duoc).

Gom ba ban lam mot la tai cau truc code khong lien quan -> chua lam. Ghi ra
day de nguoi sau sua luat ke thua biet phai sua BA cho, khong phai mot.

GIOI HAN CHUNG cua ca ba: `record_bases[x]` co the la mot LIST khi record co
nhieu base - luc do vong lap dung lai. Da ke thua GIUA NHIEU RECORD von khong
duoc CLR ho tro (1 base class that) nen day khong phai thieu sot moi.

## ~~Method chuoi DANG KY KIEU MOI khong dung duoc tren BIEU THUC~~ - DA SUA 2026-09-11

`s.split(",")` chay; `xs[0].split(",")` hoac `s.strip().split(",")` bao
"'<bieu thuc>.split(...)' khong phai method chuoi da biet". CUNG mot method,
cung mot kieu.

NGUYEN NHAN: `_compile_str_method_on_expr` (string_join.py) chi tra
`_STR_METHODS` - danh sach method CU, la NHANH DU PHONG (xem chu thich
record_feature.py ~dong 28). Method dang ky kieu MOI qua `register_expr_method`
khong nam trong do. CHIN method bi anh huong:
  center, count, ljust, match, rjust, search, split, title, zfill

DA THU SUA VA DA HOAN TAC - GHI RO DE NGUOI SAU KHONG LAP LAI:

Ban sua "hien nhien" la cho `_compile_str_method_on_expr` tra THEM registry
(`reg.expr_method_codegen[khoa_method('str', name)]`). No BIEN DICH QUA va
CHAY, nhung tra ve RAC:

    parts = s.strip().split(",")   # s = "  a,b,c  "
    return len(parts)              # CPython: 3, exe: 40840768

Tuc ban sua do bien mot LOI RO RANG thanh mot KET QUA SAI IM LANG - te hon
han tinh trang ban dau.

VI SAO: co che "ten AO trong scope" cua `_compile_str_method_on_expr` gan cho
ben nhan `TypeAnn('str', None)` va chi lo phan NAP DOI TUONG NHAN. No khong xu
ly (a) SHAPE cua ket qua - `split` tra `list[str]` chu khong phai `str`, nen
bien nhan ket qua bi khai sai kieu; (b) TEMPS o first-pass - `count` can local
an `__strcnt<N>_sub` ma duong bieu thuc khong di qua first-pass, bao "bien
chua duoc khai bao".

SUA DUNG phai lam CA BA: nap doi tuong nhan (da co), lan truyen shape ket qua,
va khai temps o first-pass cho duong bieu thuc. Do la mot viec THAT SU, khong
phai mot dong tra cuu them.

### DA SUA (2026-09-11) - va cach sua DUNG khac han cach sua dau

Ban sua DUNG: **NANG ben nhan len bien tam** (`expr_hoist._hoist_call_receiver`
/ `_hoist_index_receiver`):

    parts = s.strip().split(",")   ->   __hoist0 = s.strip()
                                        parts = __hoist0.split(",")

Sau khi nang, ben nhan la mot BIEN - va tren bien thi ca chin method DA chay
dung tu truoc, di qua first-pass va suy kieu binh thuong. DUA TRUONG HOP KHO VE
TRUONG HOP DA GIAI, thay vi mo rong co che "ten ao" de no ganh them shape ket
qua + temps (ban sua dau, cho ra RAC).

RAO NAY HONG HAI KIEU KHAC NHAU - dang ghi lai vi khong luoi nao bat duoc ca
hai:

  Lan 1: tra them registry. Compiler het bao loi, chuong trinh CHAY, tra ve
         40840768 thay vi 3. Hong o cau hoi "CO DUNG KHONG" - chi lo khi so
         voi CPython. Regression khong bat duoc vi khong mau nao dung split
         tren bieu thuc.

  Lan 2: nang bien tam nhung nang CA nhung cho VON DA CHAY DUNG (`strip` nam
         trong bang cu). Ket qua DUNG TUYET DOI (3122 = 3122, ba truong hop),
         nhung 17 file CO SAN doi IL (typegraph, pytok, codestat, ctxpack...),
         cong IL 148 -> 131 giong het. Hong o cau hoi "CO PHA GI KHONG" - chi
         lo qua so TUNG BYTE. Regression khong bat duoc vi them mot bien tam
         khong doi ket qua.

Ban cuoi GIOI HAN: chi nang khi method dung sau KHONG nam trong bang cu
`_STR_METHODS` - tuc dung chin method dang ky kieu moi.

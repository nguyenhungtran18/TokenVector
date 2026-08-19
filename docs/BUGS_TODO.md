# TokenVector — danh sách lỗi cần sửa (bản làm việc)

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

## M. [2026-08-18] `extern-class` Task 5 — thiếu test `OperatorConstraint`
reject cho handle type trong duck-typing, không chặn đóng plan.

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

## L. [2026-08-18] `extern-class` Task 4 — thiếu test cho 2 handle-class
CÙNG tên method KHÁC chữ ký, không chặn việc đóng task (reviewer đã xác
minh đúng qua đọc code, chỉ là gap coverage).

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

## K. [2026-08-17] `duck-typing-inference` — 2 điểm minor tồn đọng từ
Task 4's fix report (`task4-critical-fix-report.md`), KHÔNG chặn việc đóng
plan `docs/superpowers/plans/2026-08-17-duck-typing-inference.md` — chỉ là
chất lượng thông báo lỗi, không phải silent-wrong.

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

## J. [2026-08-17] `compiler/syntax_baseline.py` — false-negative nhỏ còn sót
(follow-up, KHÔNG chặn việc đóng plan `docs/superpowers/plans/2026-08-17-
syntax-baseline-linter.md`, phát hiện lúc re-review Task 4)

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

## I. Phát hiện 2026-08-10/11 khi viết `Testkit/check_file` — 2 bug/giới
hạn cú pháp mới, chưa sửa

- **Chuỗi có `\\` (backslash escape) bị cắt cụt lúc CHẠY** — repro:
  `s = "a\\b"; print(s)` biên dịch OK nhưng chỉ in `"a"`, mất hẳn `\b`
  (đúng ra phải in `a\b`, 3 ký tự). Chưa điều tra nguyên nhân (nghi vấn
  `ldstr` trong IL sinh ra bị cắt tại byte backslash, hoặc bước
  escape/unescape string literal lúc parse AST). Ưu tiên thấp (hiếm dùng
  backslash trong chuỗi thật), nhưng im lặng sai — nguy hiểm nếu ai dùng
  đường dẫn Windows (`"C:\\Users\\..."`) trong chuỗi.
- **`.find(sub, start_pos)` (2 tham số, tìm từ vị trí) KHÔNG được hỗ trợ**
  — chỉ chấp nhận đúng 1 tham số, khác Python (`str.find` cho phép tham
  số `start` tùy chọn). Gọi 2 tham số báo lỗi biên dịch rõ ràng
  (`s.find(x) can dung 1 tham so`) — không phải bug âm thầm, chỉ là giới
  hạn cần biết trước. Workaround: cắt chuỗi bằng slice (`s[pos:len(s)]`)
  rồi `.find()` trên chuỗi con.
- **String literal chỉ chấp nhận `"..."` (nháy kép), KHÔNG chấp nhận
  `'...'` làm dấu phân cách chuỗi** (khác Python, cho phép cả 2). Dùng
  `'...'` làm chuỗi gây lỗi tokenize khó hiểu (`khong tokenize duoc bieu
  thuc`) — không phải bug, nhưng thông báo lỗi không chỉ thẳng nguyên
  nhân, dễ mất thời gian debug (đã tự trải nghiệm khi viết `check_file`).
- Không hỗ trợ nối dòng bằng `\` cuối dòng (đã biết từ trước, xem mục
  workaround trong `check_file` — bỏ check này vì gặp bug backslash ở
  trên khi thử cài).

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
  **Giới hạn còn lại (chưa tổng quát hoàn toàn)**: `register_expr_builtin
  ('thread_join', ..., 'i64')` gán TĨNH kiểu trả về mặc định `i64` cho
  biến nhận (`r1 = thread_join(t1)`) tại bước first-pass — nếu worker trả
  về `f64`/`str` (khác `i64`), biến `r1` vẫn bị suy kiểu `i64` ngay từ đầu
  (SAI) trước khi `compile_thread_join` kịp tra `ctx['_thread_ret_types']`
  để sửa. Chỉ đúng hoàn toàn khi worker trả `i64` (đúng mọi ví dụ tài liệu
  hiện có) — cần nâng cấp first-pass để tổng quát cho mọi dtype nếu có
  use-case thật cần worker trả `f64`/`str`.

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

## B. Chưa có bản vá — xếp theo mức thiệt hại

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

## E. Giới hạn đã biết (chưa sửa) — `_known_record_vars` bỏ sót "gán từ hàm khác trả record"

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

**Hướng sửa (chưa làm, ưu tiên thấp):** thread `func_table` vào
`_expand_macros` (hiện `_gen_async_def` và 2 điểm gọi khác tại dòng ~3623,
~3814, ~3991 đều có `func_table` trong scope nhưng không truyền), rồi thêm
case (c): quét `record_var_re = r'^(\w+)\s*=\s*(\w+)\(.*\)\s*$'` (đã có sẵn
regex tương tự cho constructor), tra `func_table[callee].return_type.shape
== 'record'` để nhận thêm biến. Phải sửa đồng thời cả
`compiler/il_codegen.py` và bản mirror tự-host
`release/3.code/compiler/il_codegen.tkv`.

# TokenVector — Tóm tắt phiên & bàn giao cho phiên sau

**Cập nhật lần cuối: 2026-08-11 (phiên 5 trong ngày, mục 9 trong phiên)** —
**Phase 0-4 ĐÃ HOÀN TẤT TOÀN BỘ 100%.** SAU Phase 4, người dùng hỏi ý
nghĩa `turtle`/`pickle`/`logging`/`pdb` rồi chọn làm thêm 2/4: `logging`
✅ + `pickle` ✅ (cả 2 XONG, thu hẹp phạm vi — xem mục 9). `turtle`/`pdb`
vẫn hoãn. Đã test qua cả 2 cây, không regression (`native_test_suite.tkv`
vẫn 16/16). File này ghi đè mỗi phiên — đọc ĐẦU TIÊN khi mở phiên mới,
nhưng **kế hoạch gốc là `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`**, file
này chỉ là bàn giao/nhật ký.

---

## 0. NHIỆM VỤ CHÍNH CHO PHIÊN SAU

**Phase 0-4 ✅ HOÀN TẤT TOÀN BỘ + `logging`/`pickle` ✅ XONG. Không còn
hạng mục nào đang mở trong kế hoạch gốc.** Việc còn lại (CHỈ làm khi
được yêu cầu lại, KHÔNG tự ý bắt đầu):

- **`turtle`/`pdb`** — CHỈ làm nếu người dùng yêu cầu cụ thể lại. `pdb`
  gần như vô nghĩa với 1 chương trình đã biên dịch thành exe tĩnh (không
  có REPL/interactive runtime). `turtle` cần 1 cửa sổ GUI riêng (như
  `win32_gui_window.py` đã có cho Pac-Man) — effort lớn hơn nhiều so với
  `logging`/`pickle`.
- Nếu người dùng không yêu cầu gì cụ thể ở đầu phiên sau: hỏi lại xem có
  hạng mục mới nào muốn thêm vào kế hoạch không, KHÔNG tự suy đoán tiếp
  tục làm gì (Zero Assumptions Policy).
- **Ghi chú kỹ thuật quan trọng cho bất kỳ hạng mục nào đụng đến cây
  `.tkv`**: LUÔN kiểm tra cây `.tkv` trước khi thiết kế (bài học Phase
  3.1, lặp lại đúng ở `async`/`await` — cây `.tkv` thường có SẴN tính
  năng chưa port sang `.py`). Nhưng đừng tin tưởng mù quáng thiết kế có
  sẵn — TỰ TEST KỸ bằng case phức tạp hơn test gốc trước khi coi là
  "hoàn chỉnh" (xem mục 1 dưới — 2 bug thật đã ẩn trong `.tkv` suốt vì
  test gốc quá đơn giản).

---

## 1. Việc đã làm trong phiên này (2026-08-11, phiên 5) — mục `async`/`await`

(Các mục `namedtuple`/`defaultdict`/`Counter` đã ghi ở lần cập nhật
trước của file này/đã commit — xem `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`.)

1. Người dùng yêu cầu chuyển sang Phase 4. Do 4 hạng mục kiến trúc khác
   nhau hoàn toàn (`isinstance`/`datetime`/decorators-async-await/
   `turtle`-`pickle`-`logging`-`pdb`), dùng `/plan` (plan mode) — trình
   bày chi tiết cho người dùng qua AskUserQuestion, người dùng giao lại
   quyền chọn thứ tự.
2. Khảo sát TRƯỚC khi quyết định thứ tự: phát hiện cây `.tkv` tự-host ĐÃ
   CÓ SẴN `async`/`await` hoạt động (`il_features/async_await.tkv` +
   test `async_await` đang PASS trong `native_test_suite.tkv`), trong
   khi cây `.py` hoàn toàn không có (`grep -rn "await" compiler/il_core.py
   compiler/il_codegen.py` → 0 kết quả) — chọn làm mục này TRƯỚC vì rẻ
   hơn nhiều so với đánh giá "MISSING, cả 4 mục" trong
   `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (đã đính chính dòng đó).
3. Đọc kỹ thiết kế `.tkv` (KHÔNG suy đoán) rồi port sang `.py`:
   - `typed_dsl_parser.py`: `Signature` thêm `is_async`; `parse_signature()`
     detect prefix `async` trước tên hàm.
   - `il_core.py`: thêm nhánh parse `await` trong `_parse_factor_primary`.
   - `il_codegen.py`: `gen_il_function` bọc `ret_type` thành
     `Task<T>` khi `is_async`, thêm `ctx['is_async']`; `_expr_call` bọc
     kiểu trả về của lệnh `call` tương tự khi gọi 1 hàm async.
   - `il_features/control_flow.py`'s `codegen_return`: bọc
     `Task.FromResult<T>()` trước `ret`/`leave` khi `ctx.get('is_async')`.
   - File mới `il_features/async_await.py`: `compile_await_expr` — gọi
     `.get_Result()`. Đăng ký `register_expr_codegen('await', ...)` +
     import side-effect vào đầu `il_codegen.py`.
   - `tkv_compile.py`: `_parse_program_ast` mở rộng nhận
     `ast.AsyncFunctionDef` (trước đây CHỈ `ast.FunctionDef`);
     `_extract_signature_line` thêm prefix `"async "` khi node là
     `ast.AsyncFunctionDef`. CHƯA hỗ trợ `async def` làm record method
     (chỉ hàm top-level — khớp giới hạn của chính cây `.tkv` gốc, không
     tự mở rộng thêm).
4. Viết test `release/3.code/Testkit/async_await_py_tree_test.tkv` (3
   case, CÓ Ý THỨC test case combine 2 `await` trong 1 biểu thức — KHÔNG
   chỉ lặp lại test gốc đơn giản của `native_test_suite.tkv`).
5. **Bug thật #1 tự phát hiện qua chính test này (chưa từng lộ ở cây
   `.tkv` gốc vì test gốc CHỈ dùng 1 `await` đơn lẻ)**: `total = await
   f(5) + await f(10)` crash `NullReferenceException` lúc chạy. Đọc lại
   `.il` sinh ra: `call, call, callvirt, add.ovf, callvirt` — 2 lệnh
   `call` (2 Task) chạy LIÊN TIẾP trước khi có `callvirt` nào — chứng tỏ
   `await` KHÔNG bắt đúng phạm vi. Nguyên nhân: cả `.py` (vừa port) VÀ
   `.tkv` GỐC đều viết `return ('await', self.parse_expr())` —
   `parse_expr()` là mức ưu tiên THẤP NHẤT, nuốt luôn phần còn lại của
   biểu thức (`+ await f(10)`) vào bên trong `await` đầu tiên, thay vì
   dừng lại đúng ở 1 lời gọi hàm. Sửa: đổi thành `self.parse_factor()`
   (mức ưu tiên của toán tử một ngôi, giống `-`/`not`, đúng ngữ nghĩa
   Python thật) — **sửa CẢ 2 CÂY** (kể cả `.tkv` gốc, dù nó "đã hoạt
   động" — vì đây là bug thật, không phải chỉ giới hạn phạm vi, và để 2
   cây không lệch hành vi).
6. **Bug thật #2 phát hiện cùng lúc**: sau khi sửa bug #1, `total` vẫn bị
   khai báo sai kiểu `TkvInt` (`'int'`) thay vì `i32` — do `_infer_dtype`
   (cả `il_codegen.py` VÀ `il_codegen.tkv`) thiếu hẳn 1 nhánh cho tag
   `'await'`, rơi vào `return None` mặc định rồi `declare_scalar` fallback
   sai. Sửa: thêm nhánh `if tag == 'await': return _infer_dtype(node[1],
   ...)` (dtype của `await X` = dtype của giá trị bên trong `X`) — sửa
   CẢ 2 cây.
7. Build+test qua `python tkv.py build` (cây `.py`) — 3/3 PASS sau khi
   sửa cả 2 bug. Chạy lại `namedtuple_test`/`defaultdict_test`/
   `counter_test`/`funcvar_test`/`inheritance_py_tree_test` — không
   regression.
8. Rebuild `tkvc.exe` thật (`build_tkvc.ps1` — lần build đầu tiên gặp 1
   traceback KHÔNG liên quan, lỗi `platform.win32_ver()` đọc WMI
   (`KeyError: 'Version'`) nhưng vẫn in "Da build" — PHÁT HIỆN exe KHÔNG
   thật sự được rebuild (timestamp cũ) — chạy LẠI lần 2 thành công thật
   sự, không có traceback. **Bài học: luôn kiểm tra timestamp/log đầy đủ
   của `dist/tkvc.exe` sau build, đừng tin thông báo "Da build" một mình
   nếu có traceback phía trên** — script có thể in dòng đó vô điều kiện
   ở cuối dù bước trước lỗi.**
9. Test qua `tkvc.exe` thật — 3/3 PASS. Chạy LẠI toàn bộ
   `native_test_suite.tkv` (16/16, gồm `async_await` gốc) +
   `namedtuple_test`/`defaultdict_test`/`counter_test`/`funcvar_test`/
   `inheritance_py_tree_test` qua `tkvc.exe` thật — không regression.
10. Cập nhật `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` (Phase 4 mục
    `async`/`await` ✅) và `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md`
    (đính chính dòng "MISSING, all four").

**Lưu ý quy trình (nhắc lại, vẫn đúng)**: làm TRỰC TIẾP trong session
chính (không giao Agent tool nền) — vòng lặp sửa→build→test→mirror→
rebuild `tkvc.exe`→test lại phù hợp làm tuần tự tương tác, không hợp
giao subagent nền.

---

## 2. File đã đổi mục `async`/`await` (đã commit `1039cb7`)

- `compiler/typed_dsl_parser.py`: `Signature.is_async` + parse prefix
  `async`.
- `compiler/il_core.py`: parse `await` (dùng `parse_factor()`, ĐÃ sửa
  bug #1 ngay từ đầu ở cây `.py` — chỉ phát hiện cần sửa cả `.tkv` SAU
  khi test).
- `compiler/il_codegen.py`: `gen_il_function`/`_expr_call` bọc `Task<T>`;
  thêm nhánh `_infer_dtype` cho tag `'await'` (bug #2); import
  `il_features.async_await`.
- `compiler/il_features/control_flow.py`: `codegen_return` bọc
  `Task.FromResult<T>()`.
- `compiler/il_features/async_await.py` (MỚI).
- `tkv_compile.py`: `_parse_program_ast`/`_extract_signature_line` nhận
  `ast.AsyncFunctionDef`.
- `release/3.code/compiler/il_core.tkv`: sửa bug #1 (`parse_factor()`).
- `release/3.code/compiler/il_codegen.tkv`: sửa bug #2 (nhánh `'await'`
  trong `_infer_dtype`) — CÁC PHẦN KHÁC của `async`/`await` ĐÃ CÓ SẴN,
  không đổi.
- `release/3.code/dist/tkvc.exe`: rebuild.
- `release/3.code/Testkit/async_await_py_tree_test.tkv` (MỚI).
- `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`,
  `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md`: cập nhật.
- File này: ghi đè.

Đã commit `1039cb7` ("feat(compiler): them async/await (Phase 4, hang
muc 1)").

---

## 3. Việc đã làm trong phiên này — mục `isinstance`/`type`/`issubclass`

1. Hỏi người dùng trước khi code (Zero Assumptions — tính năng này với
   static typing của DSL có ý nghĩa gì): người dùng chọn **"hỗ trợ cả
   scalar dtype đơn giản"** (không chỉ record) — tức `isinstance(x, int)`
   vẫn hợp lệ dù `x` đã biết kiểu lúc compile, luôn compile-fold thành
   hằng `True`/`False` dựa vào `TypeAnn`.
2. Khảo sát cả 2 cây trước khi thiết kế: `grep isinstance/issubclass`
   không thấy ở đâu — file gần nhất là `metaprogramming.tkv`
   (`hasattr`/`getattr`, KHÁC tính năng) — xác nhận đây là hạng mục PHẢI
   tự thiết kế mới, không phải port (khác `async`/`await`).
3. Thiết kế: KHÔNG runtime check thật — cả 3 hàm compile-fold ngay lúc
   biên dịch (nhất quán style `hasattr`/`getattr` sẵn có — cùng emit
   `ldc.i4.0/1` hằng số):
   - `isinstance(x, int/float/str)`: so `TypeAnn.dtype` với bảng alias
     (`int`↔{i32,i64,int}, `float`↔{f32,f64}, `str`↔{str}). Không có
     `bool` (TokenVector không có dtype bool riêng, dùng i32).
   - `isinstance(obj, ClassName)`: `obj_ta.shape=='record'` +
     `_is_record_subclass` BFS qua `record_bases` (tái dùng hạ tầng kế
     thừa Phase 3.1, hỗ trợ cả đa kế thừa).
   - `issubclass(A, B)`: y hệt BFS trên nhưng A/B là TÊN class trần trụi
     (không phải biến — đọc trực tiếp từ node AST `('var', name)`, không
     tra `scope`).
   - `type(obj)`: `ldstr "<obj_ta.dtype>"` — trả tên record/dtype dạng
     hằng số string.
4. File mới `compiler/il_features/typecheck.py` (cả 2 cây, mirror y hệt
   — không có khác biệt giữa 2 cây vì thiết kế mới hoàn toàn không phụ
   thuộc hạ tầng riêng của cây nào). Đăng ký qua
   `register_expr_builtin('isinstance'/'issubclass'/'type', ...)`.
5. Test mới `release/3.code/Testkit/typecheck_py_tree_test.tkv` (10 case:
   scalar int đúng/sai, str đúng, record isinstance chính lớp/lớp cha/
   anh em sai, issubclass đúng/sai/chính nó, `type()` trả tên record).
   10/10 PASS qua `python tkv.py build` (cây `.py`).
6. Import `il_features.typecheck` thêm vào `il_codegen.py` VÀ
   `il_codegen.tkv` (2 dòng riêng biệt, cùng vị trí cạnh
   `stdlib_functional`).
7. Rebuild `tkvc.exe` thật (`build_tkvc.ps1`) — lần này KHÔNG gặp
   traceback, build sạch ngay lần đầu.
8. Test qua `tkvc.exe` thật — 10/10 PASS. Chạy LẠI toàn bộ
   `native_test_suite.tkv` (16/16) + `namedtuple_test`/`defaultdict_test`/
   `counter_test`/`funcvar_test`/`inheritance_py_tree_test`/
   `async_await_py_tree_test` qua `tkvc.exe` thật — không regression.
9. Cập nhật `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` (Phase 4 mục
   `isinstance`/`type`/`issubclass` ✅, 2/4) và
   `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (đính chính dòng MISSING).

**File đã đổi (mục này)**: `compiler/il_features/typecheck.py` (MỚI),
`compiler/il_codegen.py` (+1 dòng import), `release/3.code/compiler/
il_features/typecheck.tkv` (MỚI, mirror), `release/3.code/compiler/
il_codegen.tkv` (+1 dòng import), `release/3.code/dist/tkvc.exe`
(rebuild), `release/3.code/Testkit/typecheck_py_tree_test.tkv` (MỚI),
`docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`/
`docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (cập nhật).

Đã commit `32e840b` ("feat(compiler): them isinstance()/issubclass()/
type() (Phase 4, hang muc 2)").

---

## 4. Việc đã làm trong phiên này — mục `datetime` (kiểu thật + method)

1. Người dùng hỏi trước khi code (Zero Assumptions): DSL không có "kiểu
   datetime" (chỉ 2 hàm tự do cũ `datetime_now_utc()->str`/
   `datetime_ticks()->i64`) — chọn hướng "kiểu datetime RIÊNG" (dtype/
   shape mới + method thật, giống Python hơn), KHÔNG phải phương án rẻ
   hơn "hàm tự do trên i64 ticks thô".
2. Khảo sát cả 2 cây trước khi thiết kế: phát hiện bug `datetime_ticks`
   trả hash (ghi trong kế hoạch cũ là "chưa sửa") THỰC RA đã sửa từ commit
   `3423ef5` (trước phiên này) — kế hoạch bị lạc hậu, đính chính lại,
   KHÔNG phải việc cần làm trong phiên này nữa.
3. Thiết kế: 2 DTYPE mới `'datetime'`/`'timedelta'`
   (`typed_dsl_parser.py`'s `DTYPES`), vật lý đều `int64` ticks nhưng
   phân biệt ở tầng kiểu — `_shape_key(ta) = ta.shape or ta.dtype` (đã
   có sẵn trong `il_codegen.py`) khiến dtype 'datetime' TỰ ĐỘNG hoạt
   động như 1 "shape key" cho `register_expr_method` (giống cách `'str'`
   đã hoạt động từ trước — không cần sửa `_shape_key`).
4. `il_type_str`: `IL_SCALAR['datetime']`/`IL_SCALAR['timedelta']` = 
   `'int64'` (đăng ký qua side-effect lúc import module mới, giống
   cách `int_type.py` đã làm với `IL_SCALAR['int']`).
5. **Phát hiện xung đột tên TRƯỚC khi build** (đọc kỹ cây `.tkv` trước,
   đúng bài học đã ghi từ Phase 4 async): `stdlib_bcl.tkv` ĐÃ CÓ SẴN
   `datetime_now()` (trả `str` giờ ĐỊA PHƯƠNG qua `DateTime.Now.ToString()`,
   không phải UTC/ticks, không test nào dùng) — đổi tên hàm mới thành
   `datetime_utcnow()` để không đè lên hàm cũ (không sửa code ngoài
   phạm vi).
6. File mới `compiler/il_features/datetime_type.py` (cả 2 cây, mirror y
   hệt): `datetime_utcnow()->datetime` (tái dùng nguyên mẫu IL của
   `_push_datetime_ticks` có sẵn), `datetime_strptime(s,fmt)->datetime`,
   `d.strftime(fmt)->str` (method thật qua `register_expr_method('datetime',
   'strftime', ...)`), `timedelta_days/hours/minutes/seconds(n)->timedelta`.
   `fmt` BẮT BUỘC là chuỗi hằng (dịch `%Y`/`%m`/`%d`/`%H`/`%M`/`%S`/`%B`/
   `%b`/`%A`/`%a`/`%I`/`%p`/`%%` sang .NET custom format NGAY LÚC BIÊN
   DỊCH — macro text-level, không hỗ trợ biến, giống `.format()`).
7. **Thu hẹp phạm vi có ý thức**: `datetime +/- timedelta` KHÔNG dùng
   toán tử `+`/`-` tổng quát (né sửa binop dùng chung mọi dtype — rủi ro
   cao, effort lớn) — thay bằng 3 hàm tự do `datetime_add`/`datetime_sub`/
   `datetime_diff`, mỗi hàm chỉ là `add`/`sub` int64 THƯỜNG (không gọi
   BCL — vì datetime và timedelta đã cùng đơn vị ticks vật lý).
8. Test mới `release/3.code/Testkit/datetime_py_tree_test.tkv` (6 case:
   strftime roundtrip ngày, strftime phần giờ:phút:giây, cộng
   `timedelta_days`, trừ `timedelta_hours`, `datetime_diff` roundtrip lại
   đúng ngày gốc, `datetime_utcnow()` cộng timedelta 0 ngày không đổi giá
   trị — dùng `==` so sánh 2 giá trị dtype 'datetime', hoạt động đúng vì
   generic compare-op dùng `il_type_str` không phân biệt tên dtype).
   6/6 PASS qua `python tkv.py build` NGAY LẦN BUILD ĐẦU (không lỗi
   codegen nào phải sửa lại).
9. Rebuild `tkvc.exe` thật (`build_tkvc.ps1`, chạy nền do >120s, theo dõi
   qua thông báo hoàn tất thay vì poll) — build sạch, không traceback.
10. Test qua `tkvc.exe` thật — 6/6 PASS. Chạy LẠI toàn bộ
    `native_test_suite.tkv` (16/16) + `namedtuple_test`/`defaultdict_test`/
    `counter_test`/`funcvar_test`/`inheritance_py_tree_test`/
    `async_await_py_tree_test`/`typecheck_py_tree_test` qua `tkvc.exe`
    thật — không regression.
11. Cập nhật `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` (Phase 4 mục
    `datetime` ✅, 3/4) và `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md`
    (đính chính dòng "hash thay vì Ticks that" — đã sửa từ trước, đánh
    dấu `datetime` full model DONE).

**File đã đổi (mục này)**: `compiler/il_features/datetime_type.py` (MỚI),
`compiler/il_codegen.py` (+1 dòng import), `compiler/typed_dsl_parser.py`
(`DTYPES` thêm `'datetime'`/`'timedelta'`), `release/3.code/compiler/
il_features/datetime_type.tkv` (MỚI, mirror), `release/3.code/compiler/
il_codegen.tkv` (+1 dòng import), `release/3.code/compiler/
typed_dsl_parser.tkv` (`DTYPES` tương tự), `release/3.code/dist/tkvc.exe`
(rebuild), `release/3.code/Testkit/datetime_py_tree_test.tkv` (MỚI),
`docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`/
`docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (cập nhật).

Đã commit `4f63716` ("feat(compiler): them kieu datetime/timedelta that
(Phase 4, hang muc 3)").

---

## 5. Việc đã làm NGAY SAU đó, cùng phiên — hợp nhất hàm "lấy giờ hiện tại"

Sau khi commit `4f63716`, người dùng chỉ ra: hiện có **4 hàm/kiểu trùng
nhau** để lấy thời điểm hiện tại — `datetime_now_utc()->str` (cũ),
`datetime_ticks()->i64` 0 tham số (cũ, có test THẬT dùng
`datetime_ticks_test.tkv`), `datetime_now()->str` giờ ĐỊA PHƯƠNG (chỉ
cây `.tkv`, `stdlib_bcl.tkv`, có test THẬT dùng
`pystdlib_expansion_test.tkv`), và `datetime_utcnow()->datetime` (mới,
commit `4f63716`). Dù không crash, đây là rủi ro nhầm lẫn/bug về sau —
**đúng nhận định của người dùng, không phải lỗi kỹ thuật đang xảy ra**.

1. Hỏi người dùng hướng hợp nhất (giữ tên cũ dùng chung 1 IL helper nội
   bộ, HAY xoá hẳn 3 hàm cũ chỉ giữ 1 hàm): người dùng chọn **xoá hẳn 3
   hàm cũ, chỉ giữ 1 hàm duy nhất**.
2. Người dùng yêu cầu tiếp: đổi tên `datetime_utcnow()` → **`datetime()`**
   (ngắn gọn hơn, hợp lý vì không còn trùng tên với hàm nào nữa sau khi
   xoá 3 hàm kia).
3. XOÁ HẲN `compiler/il_features/stdlib_datetime.py` +
   `release/3.code/compiler/il_features/stdlib_datetime.tkv` (chỉ chứa
   đúng 2 hàm bị xoá, không còn gì khác trong file) + dòng
   `import il_features.stdlib_datetime` trong `il_codegen.py`/`.tkv`.
4. XOÁ hàm `datetime_now()` + CIL helper `TkvDateTimeNow()` khỏi
   `release/3.code/compiler/il_features/stdlib_bcl.tkv` (giữ nguyên
   `re_replace`/`random_randint` — không liên quan, không đụng tới).
5. `datetime_type.py`: đổi tên `datetime_utcnow` → `datetime` (đăng ký
   builtin/assign-rhs-parser dùng tên `'datetime'`). Thêm HÀM MỚI thay
   thế `datetime_ticks()` 0 tham số cũ: **`datetime_ticks(d)`** (1 tham
   số, trích ticks từ 1 giá trị `datetime` ĐÃ CÓ — vì vật lý cả 2 đều là
   `int64`, codegen chỉ là `ctx['compile_expr'](args[0], scope, out,
   'i64', ctx)`, không sinh thêm IL nào — `_widen_if_needed('datetime',
   'i64', ...)` vốn đã là no-op, xác nhận qua đọc code trước khi viết).
6. SỬA 2 test THẬT đang dùng API cũ để không bị breaking change:
   - `release/3.code/Testkit/datetime_ticks_test.tkv`: `datetime_ticks()`
     x2 → `d1 = datetime(); d2 = datetime(); datetime_ticks(d1)`/
     `datetime_ticks(d2)`.
   - `release/3.code/test/verify/pystdlib_expansion_test.tkv`: chuỗi
     `.tkv` sinh động BÊN TRONG file Python này (`dt = datetime_now()`)
     → `dt = datetime()`. Lưu ý: khi thử CHẠY test harness này để xác
     minh, phát hiện lỗi `ModuleNotFoundError: No module named
     'tkv_compile'` — lỗi HẠ TẦNG CÓ SẴN từ trước (harness import
     `tkv_compile` như module `.py` nhưng thư mục đó chỉ có
     `tkv_compile.tkv`, không phải do sửa lần này gây ra) — NGOÀI PHẠM
     VI, không sửa, chỉ ghi lại.
7. `release/3.code/Testkit/datetime_py_tree_test.tkv` (test tôi viết
   phiên này): đổi `datetime_utcnow()` → `datetime()`, thêm 1 case mới
   `ticks_of_now_plausible` kiểm `datetime_ticks(d)` trả số hợp lý — 6
   case cũ → 7 case.
8. Build+test lại toàn bộ (cả `.py` tree và `tkvc.exe` thật rebuild lần
   2): `datetime_py_tree_test` 7/7 PASS, `datetime_ticks_test` 2/2 PASS
   (API mới), `native_test_suite` 16/16 + 6 test khác (namedtuple/
   defaultdict/counter/funcvar/inheritance/async_await/typecheck) không
   regression.
9. Sửa 1 docstring lạc hậu trong `datetime_type.py` (nhắc tên file
   `stdlib_datetime.py` đã bị xoá) — rebuild `tkvc.exe` LẦN 3 (chỉ đổi
   comment, không đổi hành vi, nhưng rebuild lại cho exe khớp CHÍNH XÁC
   với source, verify lại 1 test nhanh — PASS).
10. Cập nhật `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`/
    `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (mô tả API hợp nhất, xoá
    mọi nhắc đến `datetime_now_utc`/`datetime_utcnow`/`datetime_now()`
    cũ trong bảng so sánh).

**File đã đổi (mục này)**: XOÁ `compiler/il_features/stdlib_datetime.py` +
`release/3.code/compiler/il_features/stdlib_datetime.tkv`;
`compiler/il_codegen.py`/`release/3.code/compiler/il_codegen.tkv` (xoá 1
dòng import mỗi bên); `compiler/il_features/datetime_type.py` (đổi tên
`datetime_utcnow`→`datetime`, thêm `datetime_ticks(d)`, sửa 1 docstring)
+ `release/3.code/compiler/il_features/datetime_type.tkv` (mirror);
`release/3.code/compiler/il_features/stdlib_bcl.tkv` (xoá
`datetime_now()`/`TkvDateTimeNow()`); `release/3.code/dist/tkvc.exe`
(rebuild 2 lần); `release/3.code/Testkit/datetime_ticks_test.tkv` +
`release/3.code/test/verify/pystdlib_expansion_test.tkv` (sửa dùng API
mới); `release/3.code/Testkit/datetime_py_tree_test.tkv` (sửa + thêm 1
case, 6→7); `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`/
`docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (cập nhật).

Đã commit `8014746` ("refactor(compiler): hop nhat con duong lay
datetime hien tai thanh 1 ham").

---

## 7. Việc đã làm trong phiên này — mục CUỐI Phase 4: Decorators tùy biến

1. Trước khi code, dùng 2 agent (`creative-thinking-agent` +
   `critical-thinking-agent`) đánh giá giá trị/ROI của decorator tuỳ
   biến với TokenVector cụ thể (theo yêu cầu người dùng — không có kết
   nối trực tiếp tới Qwen3/Groq như người dùng gợi ý ban đầu, dùng 2
   agent tư duy sáng tạo+phản biện sẵn có thay thế, đã nói rõ với người
   dùng). Kết luận ban đầu của cả 2 agent: SKIP hợp lý — decorator không
   mở NĂNG LỰC BIỂU ĐẠT mới (`f = deco(f)` đã viết tay được), kiến trúc
   AOT/static-typed khiến 2 use-case giá trị nhất (cache, decorator có
   tham số) không vươn tới được về cấu trúc.
2. Người dùng BÁC kết luận đó bằng 1 câu hỏi mấu chốt: "Mục tiêu là
   TokenVector THAY THẾ Python, thì lựa chọn nào hợp lý?" — dưới tiêu
   chí "thay thế Python" (không chỉ dạy học), tương thích CÚ PHÁP Python
   thật (`@deco`) quan trọng hơn "tần suất xuất hiện trong sách" (tiêu
   chí agent dùng để đánh giá) — quyết định ĐẢO NGƯỢC: VẪN LÀM, dạng thu
   hẹp phạm vi (không phải bỏ qua).
3. Khảo sát cả 2 cây: xác nhận CẢ 2 chỉ nhận diện `@staticmethod`/
   `@property`/`@interface` như TỪ KHÓA đặc biệt (so tên trực tiếp
   trong `_extract_record_def`/lớp `ClassDef`), KHÔNG có decorator
   người dùng tự viết ở đâu cả — không port được, phải tự thiết kế mới.
   Phát hiện phụ: hàm TOP-LEVEL có decorator hiện bị ÂM THẦM BỎ QUA
   (`node.decorator_list` chưa từng được kiểm tra ở nhánh top-level của
   `_parse_program_ast`) — 1 lỗ hổng thật, sửa luôn cùng lúc (nay báo
   lỗi rõ ràng).
4. Thiết kế: desugar THUẦN Ở TẦNG AST/macro biên dịch
   (`tkv_compile.py`, KHÔNG đụng `il_codegen.py`/`il_core.py`/hạ tầng
   `func`-delegate runtime nào) — lý do kỹ thuật cốt lõi: `_body_source_lines`
   trích THẲNG văn bản nguồn theo `lineno`/`end_lineno` (không tái sinh
   từ AST đã sửa), nên không thể chỉ "đổi tên node AST rồi ast.unparse"
   — phải rename bằng REGEX trên VĂN BẢN THÔ, đúng kỹ thuật đã có sẵn ở
   `_hoist_nested_def` (Phase 2.x, "def long không bắt biến nào được
   nâng lên top-level") — tái dùng nguyên mẫu, không phát minh mới.
   `@deco` trước `def f(...): ...` desugar thành: đổi tên `f` GỐC thành
   1 tên ẨN (`__deco_<deco>_<f>`), rồi TÁCH than `wrapper` (hàm lồng bên
   trong `deco`) làm than hàm CÔNG KHAI mới mang tên `f`, với MỌI lời gọi
   dạng `<tham_số_bị_bắt>(...)` bên trong `wrapper` được đổi thành lời
   gọi tên ẩn đó (regex `\b<param>\s*\(` → `<hidden>(`, CHỈ áp dụng dạng
   LỜI GỌI, không phải mọi `\b<param>\b` — tránh rủi ro trùng khớp bên
   trong string literal, đúng kỷ luật đã dùng ở `_hoist_nested_def`).
5. **Thu hẹp phạm vi có ý thức** (đã trình bày ví dụ cụ thể, người dùng
   xác nhận trước khi code): `deco` CHỈ nhận đúng 1 tham số (không
   `@deco(x)`); thân `deco` CHỈ được gồm ĐÚNG 2 câu lệnh (`def wrapper`
   lồng + `return wrapper` — không logic nào khác, vì macro không bao
   giờ THỰC SỰ gọi `deco` lúc chạy); chữ ký `wrapper` PHẢI khớp CHÍNH
   XÁC (số lượng + kiểu tham số + kiểu trả về) với CẢ chữ ký hàm gốc `f`
   VÀ kiểu `func(...)->...` mà `deco` tự khai báo cho tham số/return của
   nó (kiểm tra đủ 3 chiều, báo lỗi rõ ràng nếu lệch bất kỳ chiều nào);
   không hỗ trợ decorator trên method trong class; không hỗ trợ xếp
   chồng nhiều decorator. Hàm dùng làm `@deco` bị LOẠI khỏi danh sách
   hàm biên dịch bình thường (chỉ là template biên dịch — chữ ký
   `func(...)->...` của nó vốn không hợp lệ cho 1 hàm THẬT nếu đi qua
   đường `parse_signature` thường).
6. File mới trong `tkv_compile.py`: `_func_type_signature(func_node)`
   (trích (list kiểu tham số, kiểu trả về) để so sánh chữ ký) và
   `_expand_custom_decorator(node, deco_node, source_lines)` (toàn bộ
   logic macro, validate + trích/đổi tên văn bản). Sửa vòng lặp chính
   của `_parse_program_ast`: pre-pass thu thập `top_level_funcs`
   (name→node) + `decorator_template_names` (tên hàm nào đang được dùng
   làm `@deco`), rồi trong vòng lặp: bỏ qua template, mở rộng
   decorator hợp lệ, báo lỗi rõ ràng cho decorator không khớp mẫu.
7. Áp dụng ĐÚNG patch tương tự (không phải copy nguyên file — cây `.tkv`
   đã có sẵn hỗ trợ `async def` từ TRƯỚC phiên này mà cây `.py` không
   có, nên 2 file không giống hệt nhau như trường hợp file mới hoàn
   toàn) vào `release/3.code/tkv_compile.tkv` — thêm đúng 2 hàm +
   sửa đúng đoạn vòng lặp tương ứng.
8. Test mới `release/3.code/Testkit/decorator_py_tree_test.tkv` (2 case:
   1 decorator log đơn giản `@logged` in ra rồi gọi hàm gốc, 1 decorator
   `@doubled` nhân đôi kết quả chồng lên 1 hàm khác `add_one` đã có phép
   cộng — xác nhận macro hoạt động đúng với NHIỀU decorator độc lập
   trong CÙNG 1 file). 2/2 PASS qua `python tkv.py build` NGAY LẦN BUILD
   ĐẦU (không lỗi codegen nào phải sửa lại). Kiểm tra thêm đường lỗi
   (chữ ký `wrapper` lệch kiểu trả về so với hàm gốc) qua 1 file tạm
   ngoài git — xác nhận thông báo lỗi rõ ràng, đúng vị trí, không sai
   âm thầm.
9. Rebuild `tkvc.exe` thật (`build_tkvc.ps1`, chạy nền, theo dõi qua
   thông báo hoàn tất) — build sạch, không traceback.
10. Test qua `tkvc.exe` thật — 2/2 PASS. Chạy LẠI toàn bộ
    `native_test_suite.tkv` (16/16) + 9 test khác của Phase 3/4
    (namedtuple/defaultdict/counter/funcvar/inheritance/async_await/
    typecheck/datetime/datetime_ticks) qua `tkvc.exe` thật — không
    regression.
11. Cập nhật `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` (Phase 4 mục
    Decorators ✅, **4/4 — PHASE 4 HOÀN TẤT TOÀN BỘ**) và
    `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (đánh dấu DONE, xoá dòng
    liệt kê decorator là MISSING).

**File đã đổi (mục này)**: `tkv_compile.py` (thêm
`_func_type_signature`/`_expand_custom_decorator`, sửa vòng lặp chính
`_parse_program_ast`); `release/3.code/tkv_compile.tkv` (patch tương tự,
không phải copy nguyên file); `release/3.code/dist/tkvc.exe` (rebuild);
`release/3.code/Testkit/decorator_py_tree_test.tkv` (MỚI);
`docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`/
`docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (cập nhật).

Đã commit `f6ab6ec` ("feat(compiler): them decorator tuy bien (Phase 4,
hang muc cuoi - 4/4)").

---

## 8. Việc đã làm trong phiên này — backlog: `logging` + `pickle`

1. Sau khi Phase 4 hoàn tất, người dùng hỏi "muốn làm gì tiếp" — đưa 2
   lựa chọn (`turtle`/`pickle`/`logging`/`pdb` hoặc dừng lại). Người
   dùng hỏi ý nghĩa từng thư viện trước khi quyết định — giải thích rõ
   (turtle=đồ hoạ rùa dạy học, pickle=serialize object, logging=ghi log
   có cấp độ, pdb=debugger dòng lệnh) kèm đánh giá mức độ hợp lý với
   TokenVector cụ thể (`pdb` gần như vô nghĩa với chương trình đã biên
   dịch tĩnh). Người dùng chọn làm `logging` + `pickle`.
2. Khảo sát cả 2 cây trước khi code: XÁC NHẬN không có hạ tầng nào cho
   `logging`/`pickle` ở đâu cả — tự thiết kế mới hoàn toàn.
3. Hỏi phạm vi trước khi code (Zero Assumptions — cả 2 module Python
   thật đều phức tạp hơn nhiều so với DSL hàm-tự-do của TokenVector):
   - `logging`: chỉ có 1 phương án hợp lý nên KHÔNG cần hỏi lựa chọn
     (trình bày trực tiếp) — hàm tự do theo cấp độ, không object.
   - `pickle`: hỏi giữa "hàm theo từng scalar dtype" (rẻ) và "hỗ trợ
     thêm record" (đắt hơn nhiều) — người dùng chọn phương án rẻ
     (scalar-only).
4. Thiết kế `logging` (`il_features/logging_feature.py`, cả 2 cây):
   `log_debug/info/warning/error/critical(msg)` + `log_set_level(n)`. In
   `<LEVEL>:root:<msg>` khớp `logging.basicConfig()` mặc định của Python
   thật. Ngưỡng mặc định WARNING=30 (đúng số thật của Python:
   DEBUG=10/INFO=20/WARNING=30/ERROR=40/CRITICAL=50) — không có hằng số
   `LOG_DEBUG` dạng identifier (tránh thêm cơ chế macro-hằng-số mới,
   truyền số nguyên trực tiếp). Cần 1 state (ngưỡng hiện tại) sống
   XUYÊN SUỐT chương trình — tái dùng NGUYÊN VẸN `ctx['extra_classes']`/
   `ctx['emitted_types']` (hạ tầng có sẵn từ `int_type.py`'s
   `ensure_class`, KHÔNG phát minh cơ chế mới): 1 class phụ `TkvLogging`
   với field `threshold` (private static) + 2 method `SetLevel`/
   `GetThreshold` (0 nghĩa "chưa đặt" → coi như 30 — tránh cần `.cctor`,
   pattern CHƯA từng dùng ở bất kỳ đâu trong dự án, giảm rủi ro).
5. Thiết kế `pickle` (`il_features/pickle_feature.py`, cả 2 cây):
   `pickle_dump_i32/i64/f64/str(v, path)` (VOID) +
   `pickle_load_i32/i64/f64/str(path)->X` (trả giá trị). Dùng
   `System.IO.BinaryWriter`/`BinaryReader` — định dạng nhị phân TỰ ĐỊNH
   NGHĨA (KHÔNG phải byte thật của CPython pickle protocol — 2 runtime
   KHÔNG đọc được file của nhau, CHẤP NHẬN được vì bài test đối chiếu
   CPython của dự án chỉ cần round-trip ĐÚNG trong CHÍNH 1 runtime).
   `pickle_load_X` cần 1 hidden local (lưu giá trị đọc được TRƯỚC khi
   đóng reader, vì `Close()` cần reader còn trên stack — dùng ĐÚNG quy
   ước `key = id(args)` đã có sẵn từ `counter_type.py`'s
   `_temps_most_common`/`push_most_common`, không phát minh quy ước mới).
6. Cả 2 dispatch qua `il_features/file_io.py`'s `codegen_call_stmt` —
   mở rộng elif chain có sẵn (giống `write_file`/`append_file` đã đăng
   ký từ trước) cho các hàm VOID (`log_X`, `pickle_dump_X` — không dùng
   `register_expr_builtin` vì không trả giá trị); `pickle_load_X` dùng
   `register_expr_builtin` bình thường (giống `datetime()`/
   `timedelta_days()` phiên này). Import 2 module mới KHÔNG TRỄ (ở đầu
   `file_io.py`, không phải trong hàm) — lý do: `file_io.py` được
   `il_codegen.py` nhập KHÔNG ĐIỀU KIỆN nên đây là điểm chắc chắn chạy 1
   lần lúc nạp module, đảm bảo `register_expr_builtin` bên trong
   `pickle_feature.py` (cho `pickle_load_X`) LUÔN chạy dù chương trình
   có dùng `log_X`/`pickle_dump_X` (dispatch qua elif) hay không.
7. Áp dụng patch TƯƠNG TỰ (không copy nguyên file) vào
   `release/3.code/compiler/il_features/file_io.tkv` — cây `.tkv` đã có
   1 nhánh `else` KHÁC (kiểm `EXPR_BUILTIN_DTYPE` thay vì `func_table`,
   từ 1 phase trước không liên quan) nên chỉ chèn ĐÚNG đoạn mới vào giữa,
   giữ nguyên nhánh `else` gốc của mỗi cây.
8. Test mới `release/3.code/Testkit/logging_pickle_py_tree_test.tkv` (5
   case: ngưỡng mặc định lọc DEBUG/INFO nhưng in WARNING, `log_set_level(10)`
   làm INFO hiện ra, round-trip pickle cho i32/f64/str). 5/5 PASS qua
   `python tkv.py build` NGAY LẦN BUILD ĐẦU (không lỗi codegen nào phải
   sửa lại) — output log đúng định dạng `WARNING:root:...`/`INFO:root:...`
   xác nhận trực quan.
9. Rebuild `tkvc.exe` thật (`build_tkvc.ps1`, chạy nền, theo dõi qua
   thông báo hoàn tất) — build sạch, không traceback.
10. Test qua `tkvc.exe` thật — 5/5 PASS. Chạy LẠI toàn bộ
    `native_test_suite.tkv` (16/16) + 10 test khác của Phase 3/4
    (namedtuple/defaultdict/counter/funcvar/inheritance/async_await/
    typecheck/datetime/datetime_ticks/decorator) qua `tkvc.exe` thật —
    không regression.
11. Cập nhật `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md` (`logging`✅/
    `pickle`✅, còn `turtle`/`pdb` hoãn) và
    `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (đánh dấu DONE).

**File đã đổi (mục này, CHƯA commit)**:
- `compiler/il_features/logging_feature.py` (MỚI)
- `compiler/il_features/pickle_feature.py` (MỚI)
- `compiler/il_features/file_io.py`: import 2 module mới, mở rộng elif
  chain trong `codegen_call_stmt`
- `release/3.code/compiler/il_features/logging_feature.tkv` (MỚI, mirror)
- `release/3.code/compiler/il_features/pickle_feature.tkv` (MỚI, mirror)
- `release/3.code/compiler/il_features/file_io.tkv`: patch tương tự
  (không phải copy nguyên file — nhánh `else` khác nhau giữa 2 cây)
- `release/3.code/dist/tkvc.exe`: rebuild
- `release/3.code/Testkit/logging_pickle_py_tree_test.tkv` (MỚI)
- `docs/PYTHON_GAP_IMPLEMENTATION_PLAN.md`,
  `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md`: cập nhật
- File này: ghi đè

**CHƯA commit** — chờ người dùng xác nhận.

---

## 9. Bug/vấn đề phát hiện ngoài lề (chưa thuộc phạm vi phiên này)

Kế thừa từ các phiên trước, CHƯA sửa:
- `print(list[int])` crash `InvalidCastException` (phiên 3).
- `int(<biểu thức kiểu int>)` thiếu nhánh ép kiểu `int`→`i32` (phiên 3).
- `gen_il_program` không nhận `record_methods_own` — bug tiềm ẩn CHƯA
  điều tra (phiên 4).
- `_resolve_func_ta`'s fallback "tên hàm top-level trần trụi" không hoạt
  động lúc codegen thật (phiên 5, phần `defaultdict`) — vẫn ảnh hưởng
  `Counter`/`map`/`filter`/`reduce`/`defaultdict`.
- `release/3.code/test/verify/pystdlib_expansion_test.tkv`: harness
  Python thật (đuôi `.tkv` gây nhầm) `import tkv_compile` như module
  `.py`, nhưng thư mục `release/3.code/` chỉ có `tkv_compile.tkv` (không
  có `.py`) — `ModuleNotFoundError` khi chạy `python <file>.tkv` trực
  tiếp. Phát hiện phiên 5 lúc xác minh sửa `datetime_now()`→`datetime()`
  bên trong file — KHÔNG phải do sửa lần này gây ra (lỗi hạ tầng có sẵn
  từ trước, đã có comment sửa đúng nhưng chưa CHẠY ĐƯỢC để xác nhận qua
  đường này — đã xác nhận qua `tkvc.exe` thật + `.py` tree thay thế).

**MỚI phát hiện phiên này (đã SỬA, không phải để lại)**: 2 bug thật
trong thiết kế `async`/`await` gốc của cây `.tkv` — xem mục 1.5-1.6 ở
trên. Ghi lại ở đây chỉ để nhấn mạnh bài học: **thiết kế có sẵn ở cây
`.tkv` không đồng nghĩa với "đã kiểm chứng đầy đủ"** — test gốc của nó
(`native_test_suite.tkv`'s `async_await`) chỉ phủ 1 trường hợp đơn giản
nhất, không phát hiện được bug precedence. Phiên sau khi PORT bất kỳ
tính năng nào từ `.tkv`, nên viết test PHONG PHÚ HƠN test gốc (không chỉ
lặp lại y hệt), giống cách phiên này bắt được 2 bug thật.

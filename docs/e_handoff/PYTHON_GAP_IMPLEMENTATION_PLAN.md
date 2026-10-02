# Kế hoạch triển khai gap Python vs TokenVector

**Nguồn**: `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` (bản đã full-read 5 sách +
verify từng dòng, 2026-08-11). File này là kế hoạch thực thi cụ thể rút ra từ đó,
chia nhỏ theo triết lý "chia để trị" — mỗi task = 1 file mới hoặc 1 addition nhỏ
vào file batch có sẵn, độc lập, tự test được, không phá cây hiện có.

**Nguyên tắc phân bổ AI provider** (theo CLAUDE.md mục 2):
- **Groq/Qwen3 local** — research cú pháp .NET IL cần dùng (vd `Regex.Split`,
  `String.Format`) trước khi viết, brainstorm edge case.
- **Claude (phiên này/phiên sau)** — logic codegen cốt lõi, quyết định kiến trúc,
  review cuối.
- Mỗi task PHẢI: search `code-librarian`/Obsidian Vault trước khi viết (tránh
  duplicate pattern), tự viết test bằng `Testkit/tkv_test_lib.tkv` sau khi xong,
  build lại `dist/tkvc.exe` + chạy `native_test_suite.tkv --entry run` (16 test
  hiện có) để đảm bảo KHÔNG regress trước khi coi task hoàn thành.

---

## ✅ Phase 0 — Sửa bug rẻ trước khi thêm tính năng (ưu tiên tuyệt đối, làm trước) — XONG (phiên 2)

| # | Task | File | Ghi chú |
|---|---|---|---|
| ✅ 0.1 | `datetime_ticks` trả về hash thay vì `.Ticks` thật | `compiler/il_features/stdlib_datetime.py` | Sai ngữ nghĩa âm thầm, có thể gây bug khó dò về sau nếu ai dùng để so sánh thời gian. Sửa 1 dòng, rủi ro thấp. |

**Lý do làm trước**: bug âm thầm, càng để lâu càng có nguy cơ code khác phụ
thuộc vào hành vi sai. Chi phí sửa gần như bằng 0.

---

## ✅ Phase 1 — Nhóm tần suất cao nhất trong 5 sách (giá trị/công sức tốt nhất) — XONG (phiên 2)

Thứ tự theo tần suất xuất hiện trong sách × chi phí triển khai thấp.

| # | Task | File mới/sửa | Input cần | Ước lượng |
|---|---|---|---|---|
| ✅ 1.1 | `.format()` string method (positional/keyword, index reorder, conversion code cơ bản) | `string_format.py` (mới) | Có chương riêng trong `HowtocodeinPython3.md` | Vừa — cần parser cho mini-spec `{0}`/`{name}`/`{:.2f}` — **keyword args thu hẹp phạm vi, chưa làm** |
| ✅ 1.2 | `%`-style string formatting (`"%s" % x`, `"%.2f" % x`) | `string_percent_format.py` (mới) | Idiom chủ đạo trong sách ML, có mục riêng trong `BasicOfPythonProgramming.md` | Vừa — tách biệt hoàn toàn với 1.1, không phụ thuộc nhau |
| ✅ 1.3 | `random.shuffle/sample/uniform/seed/randrange` | mở rộng `stdlib_random.py` | Sách ML + `Python Tutorial.md` | Nhỏ — pattern giống 3 hàm đã có — **CHỈ `uniform`/`randrange` làm; `shuffle`/`sample`/`seed` thu hẹp phạm vi, chưa làm (cần thiết kế riêng)** |
| ✅ 1.4 | `re.search/findall/split/compile/fullmatch` | mở rộng `stdlib_re.py` | `Python Tutorial.md` | Nhỏ-vừa — `.NET Regex` đã có sẵn API tương ứng — **CHỈ `search`/`fullmatch` làm; `findall`/`split`/`compile` thu hẹp phạm vi, chưa làm (cần thiết kế riêng)** |
| ✅ 1.5 | 2-arg `.find(sub,start)`, `.strip(chars)`, `.replace(old,new,count)` | sửa `string_methods_batch3.py`/liên quan | Đã ghi nhận trong `docs/BUGS_TODO.md` từ trước | Nhỏ, gộp 1 PR — **CHỈ `.find(sub,start)`/`.strip(chars)` làm; `.replace(...,count)` thu hẹp phạm vi, chưa làm** |

**Điều kiện dừng Phase 1**: 16/16 test cũ vẫn PASS + mỗi task mới có ít nhất
1 test trong `native_test_suite.tkv` hoặc file test riêng theo mẫu
`Testkit/example_lib_test.tkv`.

---

## ✅ Phase 2 — Nhóm đã có nền tảng, chỉ cần mở rộng (rủi ro thấp, tận dụng code sẵn) — XONG (phiên 2)

| # | Task | File | Ghi chú |
|---|---|---|---|
| ✅ 2.1 | `enumerate()`/`zip()` dạng expression độc lập (không chỉ trong header `for`), `zip` hỗ trợ 3+ list | mở rộng `stdlib_itertools.py:22,41` | Đã có macro cho for-header, đây là mở rộng không phải viết mới — **CHỈ `zip` trong for-header 2→N list làm; dạng expression độc lập cho cả 2 hàm CHƯA làm** |
| ✅ 2.2 | `lambda` mở rộng thành closure tổng quát | mở rộng `il_core.py:270-295` + `il_codegen.py:1296`, tái dùng pattern `closures.py` | Rủi ro cao hơn — đụng vào codegen lõi, cần test kỹ edge case (lambda lồng nhau, capture biến ngoài) — **capture biến tự do xong phiên này; lưu/gọi lại qua biến hoàn tất ở Phase 3.3 (phiên 3-4)** |
| ✅ 2.3 | `os.path.splitext/isfile/isdir` | mở rộng `stdlib_path.py` | Nhỏ, .NET có sẵn `Path.GetExtension`/`File.Exists`/`Directory.Exists` — **CHỈ `isfile`/`isdir` làm; `splitext` CHƯA làm** |
| ✅ 2.4 | `.update()` (dict), `.clear()` (list), `divmod()`, `math.pi`/`math.e`/`math.gcd` | file batch nhỏ gộp chung | Mỗi cái rẻ, gộp 1 task để đỡ overhead review — **`dict.update`/`math.pi`/`math.e`/`math.gcd` làm (`list.clear` hoá ra đã có sẵn từ trước); `divmod()` CHƯA làm** |

---

## ✅ Phase 3 — Cần quyết định thiết kế trước khi code (Zero Assumptions Policy) — 3/3 XONG (phiên 3-5)

Đây là 2 hạng mục **KHÔNG được code ngay** — phải dừng lại hỏi/quyết định trước,
vì phạm vi lớn và có nhiều lựa chọn kiến trúc khác nhau:

| # | Hạng mục | Câu hỏi cần trả lời trước khi code | Trạng thái |
|---|---|---|---|
| ✅ 3.1 | Kế thừa class / `super()` / `@property` | `record_feature.py` hiện chỉ là flat record. Có nên thêm inheritance đầy đủ (vtable, method override) hay chỉ hỗ trợ single-inheritance đơn giản? Ảnh hưởng đến toàn bộ codegen record — cần thiết kế riêng, không phải 1 file nhỏ. | **XONG (phiên 4)** — người dùng chọn "Full vtable + override"; cây `.tkv` đã có sẵn thiết kế này, port sang cây `.py` (không thiết kế lại). |
| ✅ 3.2 | `collections` module (`namedtuple`, `Counter`, `defaultdict`) | Có nên implement như syntax sugar trên record/dict có sẵn, hay như kiểu built-in mới? Phạm vi trung-lớn. | **XONG (phiên 5)** — người dùng chọn "kiểu built-in mới hoàn chỉnh", làm từng kiểu một. `namedtuple` (desugar tại tầng parse thành record thường). `defaultdict[K,V]` (đọc thiếu khóa tự gọi `factory` kiểu `func`, tái dùng hạ tầng Phase 3.3). `Counter[K]` + `most_common(n)` (đọc thiếu khóa trả 0 KHÔNG chèn key, `most_common` trả đúng `list[(K,i32)]` giống Python thật — cần mở rộng hạ tầng tuple sang vị trí biểu thức + `list[tuple]` + giải nén `k,v = lst[i]`, lần đầu dùng trong dự án). |
| ✅ 3.3 | `map()`/`filter()`/`functools.reduce()` | Có thể desugar về comprehension/loop có sẵn (rẻ) hay cần first-class function values thật (đụng vào lambda 2.2)? Quyết định này ảnh hưởng độ khó. | **XONG (phiên 3-4)** — người dùng chọn "first-class function values thật"; `f` chỉ nhận tên hàm/biến `func` đã khai báo (không nhận lambda trực tiếp, thu hẹp phạm vi có hỏi trước). |

**Không tự ý code các mục Phase 3** — trình bày phương án + hỏi người dùng trước
khi bắt đầu, theo đúng Zero Assumptions Policy.

---

## ✅ Phase 4 — Ưu tiên thấp, hoãn lại (tần suất thấp/niche trong 5 sách) — 4/4 XONG (phiên 5)

Người dùng yêu cầu bắt đầu Phase 4 ở phiên 5 (trước đó hoãn theo kế
hoạch). 4 hạng mục độc lập, đã trình bày chi tiết cho người dùng và để
người dùng chọn thứ tự (người dùng giao lại quyền chọn):

- ✅ **`async`/`await`** — XONG (phiên 5). Phát hiện quan trọng: cây
  `.tkv` tự-host ĐÃ CÓ SẴN thiết kế hoạt động (`async_await.tkv` + test
  PASS trong `native_test_suite.tkv`) — đúng pattern Phase 3.1, port
  thay vì thiết kế lại. Mô hình GIẢ-bất-đồng-bộ: hàm `async def` chạy
  ĐỒNG BỘ đến hết, kết quả bọc vào `Task<T>` ĐÃ HOÀN TẤT qua
  `Task.FromResult<T>()` trước `ret`; `await` chỉ gọi `.get_Result()`
  đồng bộ. KHÔNG có concurrency thật (ngoài phạm vi). **Bug thật tự phát
  hiện+sửa trong lúc port** (có SẴN cả ở cây `.tkv` gốc, chưa từng lộ vì
  test gốc chỉ dùng 1 `await` đơn lẻ): `await` dùng `self.parse_expr()`
  cho toán hạng — ưu tiên THẤP NHẤT — khiến `await f(5) + await f(10)`
  bị nuốt nhầm thành `await (f(5) + await f(10))`, sinh IL sai kiểu
  (`add.ovf` trên 1 tham chiếu `Task`), crash `NullReferenceException`
  lúc chạy. Sửa: `parse_factor()` thay `parse_expr()` (await bắt chặt
  như toán tử một ngôi, đúng Python thật) — sửa CẢ 2 cây. Bug thứ 2 liên
  quan: `_infer_dtype` thiếu nhánh cho tag `'await'`, khiến biến nhận
  kết quả await trong biểu thức phức hợp bị suy sai kiểu `'int'`
  (TkvInt) thay vì kiểu thật — sửa CẢ 2 cây.
- ✅ **`isinstance()`/`type()`/`issubclass()`** — XONG (phiên 5). Hỏi
  người dùng trước khi code (Zero Assumptions): TokenVector static-typed
  nên 2 hàm đầu vốn luôn quyết định được LÚC COMPILE — người dùng chọn
  "hỗ trợ cả scalar dtype đơn giản" (không chỉ record). Thiết kế: KHÔNG
  có check runtime thật — cả 3 hàm compile-fold thành hằng số ngay lúc
  biên dịch (`isinstance`/`issubclass` → `ldc.i4.0/1`, `type(obj)` →
  `ldstr "<dtype/record>"`). `isinstance(x, int/float/str)` so khớp
  `TypeAnn.dtype` (không có `bool` — TokenVector không có dtype bool
  riêng, dùng i32). `isinstance(obj, ClassName)`/`issubclass(A,B)` duyệt
  `record_bases` (hạ tầng có sẵn từ Phase 3.1, không thiết kế lại). File
  mới `il_features/typecheck.py` (cả 2 cây, KHÔNG có sẵn ở cây nào trước
  — khác pattern Phase 3.1/async, phải tự thiết kế từ đầu). Test mới
  `release/3.code/Testkit/typecheck_py_tree_test.tkv` (10/10 PASS qua cả
  `.py` tree và `tkvc.exe` thật), `native_test_suite.tkv` vẫn 16/16 không
  đổi.
- ✅ **`datetime` full object model** — XONG (phiên 5). Lưu ý phát hiện
  đầu phiên: bug `datetime_ticks` trả hash được ghi trong kế hoạch cũ
  **ĐÃ SỬA TỪ TRƯỚC** (commit `3423ef5`, không phải phiên này) — kế
  hoạch bị lạc hậu, đã đính chính. Hỏi người dùng trước khi code (Zero
  Assumptions): DSL hiện KHÔNG có "kiểu datetime" (chỉ 2 hàm tự do
  `datetime_now_utc()->str`/`datetime_ticks()->i64`) — người dùng CHỌN
  hướng "kiểu datetime riêng" (dtype/shape mới + method thật, giống
  Python hơn) thay vì phương án rẻ hơn "hàm tự do trên i64 ticks". Thiết
  kế: 2 DTYPE mới `'datetime'`/`'timedelta'` (`typed_dsl_parser.py`),
  VẬT LÝ đều là `int64` ticks (giống `System.DateTime.Ticks`/
  `System.TimeSpan.Ticks`) nhưng PHÂN BIỆT ở tầng kiểu (không gán lẫn,
  method dispatch riêng qua `_shape_key`=dtype, giống cách `'str'` đã
  hoạt động). `d.strftime(fmt)` (method thật qua `register_expr_method`)
  và `datetime_strptime(s, fmt)`/`timedelta_days/hours/minutes/seconds(n)`
  dịch ký hiệu định dạng Python (`%Y`/`%m`/...) sang .NET custom format
  NGAY LÚC BIÊN DỊCH (fmt bắt buộc là CHUỖI HẰNG — giống phong cách macro
  text-level của `.format()`/`%`-format, Phase 1.1/1.2). **Thu hẹp phạm
  vi có ý thức** (giống tinh thần Phase 3.2): `datetime + timedelta`
  KHÔNG dùng toán tử `+`/`-` tổng quát (rủi ro cao, phải sửa binop dùng
  chung cho MỌI dtype) — thay bằng 3 hàm tự do `datetime_add`/
  `datetime_sub`/`datetime_diff`, thực ra chỉ là `add`/`sub` int64
  THƯỜNG (vì cả 2 đều vật lý là ticks, không cần gọi BCL). **Phát hiện
  xung đột tên trước khi build**: cây `.tkv` ĐÃ CÓ SẴN `datetime_now()`
  (`stdlib_bcl.tkv`, trả `DateTime.Now.ToString()` dạng `str`, không
  test nào dùng) — đổi tên hàm mới thành `datetime_utcnow()` để tránh đè
  lên hàm cũ. File mới `il_features/datetime_type.py` (cả 2 cây, mirror
  y hệt).

  **Hợp nhất API (cùng phiên, theo yêu cầu người dùng sau khi thấy 4 hàm
  "lấy giờ hiện tại" trùng lặp gây rối)**: người dùng chỉ ra
  `datetime_now_utc()`/`datetime_ticks()` (cũ, `stdlib_datetime.py`),
  `datetime_now()` (chỉ cây `.tkv`, `stdlib_bcl.tkv`) và
  `datetime_utcnow()` (mới) là 4 cách trùng nhau để lấy thời điểm hiện
  tại — dễ gây lẫn lộn/bug sau này dù không crash. Hỏi lại và người dùng
  chọn **xoá hẳn 3 hàm cũ, chỉ giữ 1 hàm duy nhất**. Rồi người dùng yêu
  cầu tiếp: đổi tên `datetime_utcnow()` → **`datetime()`** (ngắn gọn, vì
  không còn trùng tên với ai nữa). Kết quả cuối: XOÁ HẲN
  `compiler/il_features/stdlib_datetime.py` (+ mirror `.tkv`, + dòng
  import trong `il_codegen.py`/`.tkv`) và hàm `datetime_now()` +
  `TkvDateTimeNow()` CIL helper trong `stdlib_bcl.tkv`. `datetime_ticks`
  đổi từ hàm 0 tham số (tự gọi `UtcNow`) thành **`datetime_ticks(d)`** (1
  tham số, trích ticks từ 1 giá trị `datetime` CÓ SẴN — vì vật lý đã là
  `int64`, chỉ cần đổi nhãn dtype `'datetime'`→`'i64'`, `_widen_if_needed`
  không sinh IL nào thêm). 2 test THẬT đang dùng API cũ được sửa theo
  API mới: `release/3.code/Testkit/datetime_ticks_test.tkv` (
  `datetime_ticks()` → `datetime()` + `datetime_ticks(d)`),
  `release/3.code/test/verify/pystdlib_expansion_test.tkv` (chuỗi
  `.tkv` sinh động bên trong: `datetime_now()` → `datetime()`).
  Test mới `release/3.code/Testkit/datetime_py_tree_test.tkv` (7/7 PASS
  qua cả `.py` tree và `tkvc.exe` thật, gồm strftime roundtrip,
  giờ:phút:giây, cộng/trừ timedelta, diff giữa 2 datetime, `datetime()`
  cộng timedelta 0 ngày không đổi giá trị, `datetime_ticks(d)` trả số
  hợp lý), `datetime_ticks_test.tkv` (2/2 PASS, API mới),
  `native_test_suite.tkv` vẫn 16/16 không đổi.
- ✅ **Decorators tùy biến** — XONG (phiên 5, hạng mục CUỐI của Phase 4).
  Không có sẵn ở cây `.tkv` nào (cả 2 cây chỉ nhận diện `@staticmethod`/
  `@property`/`@interface` như TỪ KHÓA đặc biệt, KHÔNG phải decorator
  người dùng tự viết) — phải tự thiết kế mới. Trước khi code: dùng 2
  agent (`creative-thinking-agent` + `critical-thinking-agent`) đánh giá
  giá trị/ROI (không có kết nối trực tiếp tới Qwen3/Groq như người dùng
  yêu cầu ban đầu — dùng 2 agent tư duy sáng tạo+phản biện sẵn có thay
  thế) — kết luận ban đầu "giá trị thấp, bỏ qua" bị người dùng bác vì
  MỤC TIÊU THẬT của TokenVector là **thay thế Python** (không chỉ dạy
  học) — dưới tiêu chí đó, tương thích cú pháp Python thật (`@deco`)
  quan trọng hơn "tần suất xuất hiện trong sách", nên quyết định VẪN LÀM
  (dạng thu hẹp phạm vi, không phải bỏ qua).

  Thiết kế: **desugar THUẦN Ở TẦNG AST/macro biên dịch** (`tkv_compile.py`
  /`.tkv`), KHÔNG dùng hạ tầng `func`-delegate/closure runtime nào —
  `@deco` trước `def f(...): ...` (hàm top-level) tương đương Python thật
  `f = deco(f)`, nhưng vì phạm vi bắt buộc `deco` phải là 1 TEMPLATE
  thuần tuý (thân `deco` CHỈ gồm đúng 2 câu lệnh: 1 `def wrapper(...):`
  lồng + `return wrapper`, không logic nào khác — nghĩa là `deco` KHÔNG
  BAO GIỜ thực sự được gọi lúc chạy), macro INLINE TRỰC TIẾP thân
  `wrapper` làm thân hàm công khai MỚI cho `f`: đổi tên hàm GỐC thành 1
  tên ẨN, đổi MỌI lời gọi tới tham số bị bắt (`f(...)`) trong thân
  `wrapper` thành lời gọi tên ẩn đó (dùng đúng kỹ thuật regex-rename theo
  dạng LỜI GỌI đã có sẵn từ `_hoist_nested_def`, Phase 2.x — không phát
  minh cơ chế mới). Kết quả hành vi giống hệt `f = deco(f)` thật (vì
  `deco` không làm gì khác ngoài trả về `wrapper`), không cần mô phỏng
  "chạy 1 lần lúc nạp module" (AOT tĩnh không có khái niệm đó).

  **Thu hẹp phạm vi có ý thức** (đã trình bày cụ thể cho người dùng qua
  ví dụ, được xác nhận trước khi code): `deco` chỉ nhận ĐÚNG 1 tham số,
  chữ ký `wrapper` PHẢI khớp CHÍNH XÁC (số lượng + kiểu tham số + kiểu
  trả về) với chữ ký hàm gốc VÀ với kiểu `func(...)->...` mà `deco` tự
  khai báo (kiểm tra đủ cả 3 chiều, báo lỗi rõ ràng nếu lệch) — không hỗ
  trợ decorator có tham số (`@deco(x)`), không hỗ trợ decorator trên
  method trong class, không hỗ trợ xếp chồng nhiều decorator. Hàm dùng
  làm `@deco` bị loại khỏi danh sách hàm biên dịch bình thường (chỉ là
  template biên dịch, không tự nó là 1 hàm — chữ ký `func(...)->...` của
  nó vốn không hợp lệ cho tham số/return của 1 hàm THẬT nếu đi qua đường
  thường). Sửa thêm 1 lỗ hổng liên đới phát hiện trong lúc code: trước
  đây decorator KHÔNG ĐƯỢC HỖ TRỢ trên hàm top-level bị ÂM THẦM BỎ QUA
  (không lỗi, không cảnh báo) — nay báo lỗi RÕ RÀNG nếu gặp decorator
  không khớp mẫu `@deco` hợp lệ.

  File sửa: `tkv_compile.py` + `release/3.code/tkv_compile.tkv` (thêm
  `_func_type_signature`/`_expand_custom_decorator`, sửa vòng lặp chính
  của `_parse_program_ast`). Test mới
  `release/3.code/Testkit/decorator_py_tree_test.tkv` (2/2 PASS qua cả
  `.py` tree và `tkvc.exe` thật NGAY LẦN BUILD ĐẦU — gồm 1 decorator log
  đơn giản và 1 decorator nhân đôi kết quả, chồng lên 1 hàm khác đã có
  phép cộng), đã kiểm tra thêm đường lỗi (chữ ký lệch → lỗi rõ ràng,
  không sai âm thầm). Không regression: `native_test_suite.tkv` (16/16)
  + toàn bộ 9 test khác của Phase 3/4 đều PASS.

  **→ PHASE 4 HOÀN TẤT 4/4 HẠNG MỤC** (`async`/`await`, `isinstance`/
  `type`/`issubclass`, `datetime`, decorators tùy biến).
- ✅ **`logging`** — XONG (phiên 5, người dùng yêu cầu sau khi giải
  thích ý nghĩa từng thư viện backlog). Thu hẹp phạm vi: hàm tự do theo
  cấp độ (`log_debug/info/warning/error/critical(msg)` +
  `log_set_level(n)`, KHÔNG có logger/handler/formatter object — DSL
  hàm-tự-do, không OOP module). In dạng `<LEVEL>:root:<msg>` khớp
  `logging.basicConfig()` mặc định của Python thật; ngưỡng mặc định
  WARNING=30 (dùng đúng giá trị số thật của Python: DEBUG=10/INFO=20/
  WARNING=30/ERROR=40/CRITICAL=50 — không có hằng số `LOG_DEBUG` dạng
  identifier, truyền số nguyên trực tiếp, tránh thêm cơ chế macro-hằng-số
  mới ngoài phạm vi). Cần 1 static field lưu ngưỡng hiện tại xuyên suốt
  chương trình — dùng `ctx['extra_classes']`/`ctx['emitted_types']` (hạ
  tầng tái dùng nguyên vẹn từ `int_type.py`'s `ensure_class`, không phát
  minh cơ chế mới): 1 class phụ `TkvLogging` với field `threshold` + 2
  static method `SetLevel`/`GetThreshold` (0 nghĩa là "chưa đặt" → coi
  như 30, tránh cần `.cctor` chưa từng dùng ở đâu trong dự án). File mới
  `il_features/logging_feature.py` (cả 2 cây).
- ✅ **`pickle`** — XONG (phiên 5, cùng lúc với `logging`). Thu hẹp phạm
  vi: CHỈ lưu/đọc 1 GIÁ TRỊ VÔ HƯỚNG (i32/i64/f64/str) qua file —
  `pickle_dump_i32(v, path)`/`pickle_load_i32(path)->i32` (tương tự
  i64/f64/str), KHÔNG hỗ trợ list/dict/record/nested object. Định dạng
  nhị phân dùng `System.IO.BinaryWriter`/`BinaryReader` — TỰ ĐỊNH NGHĨA,
  KHÔNG phải byte thật của CPython pickle protocol (2 runtime không đọc
  được file của nhau) — CHẤP NHẬN được vì bài test đối chiếu CPython chỉ
  cần round-trip ĐÚNG trong CHÍNH 1 runtime, không cần byte-for-byte
  giống nhau. File mới `il_features/pickle_feature.py` (cả 2 cây).
- File cả 2 tính năng đều dispatch qua `il_features/file_io.py`'s
  `codegen_call_stmt` (mở rộng elif chain có sẵn — giống cách
  `write_file`/`append_file` đã đăng ký, `log_X`/`pickle_dump_X` là hàm
  VOID nên KHÔNG dùng `register_expr_builtin`; `pickle_load_X` trả giá
  trị nên dùng `register_expr_builtin` bình thường, giống `datetime()`).
  Test mới `release/3.code/Testkit/logging_pickle_py_tree_test.tkv` (5/5
  PASS qua cả `.py` tree và `tkvc.exe` thật NGAY LẦN BUILD ĐẦU — xác
  nhận đúng hành vi lọc theo cấp độ + round-trip pickle 3 dtype),
  `native_test_suite.tkv` vẫn 16/16 không đổi.
- ⬜ `turtle`/`pdb` (niche, 1 sách mỗi cái, giá trị thấp so với effort —
  `pdb` gần như vô nghĩa với 1 chương trình đã biên dịch thành exe tĩnh
  (không có REPL/interactive runtime) — chỉ làm nếu được yêu cầu cụ thể
  lại).

---

## Tổng kết thứ tự thực hiện đề xuất cho phiên sau

1. ✅ Phase 0 (bug fix, ~5 phút) — XONG
2. ✅ Phase 1, task 1.1 → 1.5 tuần tự, mỗi task tự build+test trước khi qua task kế — XONG
3. ✅ Phase 2, task 2.1/2.3/2.4 trước (rủi ro thấp) → 2.2 (lambda) sau cùng vì đụng
   codegen lõi — XONG
4. ✅ Phase 3: 3.1 ✅, 3.3 ✅, 3.2 ✅ (`namedtuple`, `defaultdict`, `Counter`
   + `most_common(n)`) — TOÀN BỘ Phase 3 ĐÃ XONG (phiên 5)
5. ✅ Phase 4 (người dùng đã yêu cầu bắt đầu, phiên 5): `async`/`await` ✅,
   `isinstance`/`type`/`issubclass` ✅, `datetime` đầy đủ ✅, Decorators
   tùy biến ✅ — **TOÀN BỘ PHASE 4 (4/4) ĐÃ XONG (phiên 5)**.
6. ✅ Backlog niche (người dùng yêu cầu sau khi được giải thích ý nghĩa
   từng thư viện): `logging` ✅, `pickle` ✅ — cả 2 XONG (phiên 5).
   `turtle`/`pdb` vẫn hoãn (chỉ làm nếu được yêu cầu cụ thể lại —
   `pdb` gần như vô nghĩa với chương trình đã biên dịch thành exe tĩnh).

**→ Việc kế tiếp: chỉ còn `turtle`/`pdb` (niche, hoãn theo mặc định) nếu
người dùng yêu cầu — nếu không, KHÔNG còn hạng mục nào đang mở.**

Mỗi task kết thúc: cập nhật `docs/NEXT_SESSION_HANDOFF.md` với trạng thái
PASS/FAIL thật (không suy đoán), commit riêng theo convention hiện có
(`feat(compiler): ...` / `fix(compiler): ...`).

---

## ✅ Trạng thái thực tế (cập nhật 2026-08-11, phiên 5) — PHASE 0-4 TOÀN BỘ ĐÃ XONG

**Phase 0 ✅ + Phase 1 ✅ (1.1-1.5) + Phase 2 ✅ (2.1-2.4): TẤT CẢ ĐÃ XONG**
(phiên 2). **Phase 3.1 ✅ (kế thừa class) VÀ Phase 3.3 ✅ (first-class
function values + map/filter/reduce) ĐÃ XONG** (phiên 3-4). **Phase 3.2
✅ XONG HOÀN TOÀN (phiên 5)**: `namedtuple` — `Point = namedtuple("Point",
["x","y"])` ở top-level desugar NGAY tại tầng parse (`_extract_namedtuple_def`,
`tkv_compile.py`/`tkv_compile.tkv`) thành 1 record thường (field mặc định
kiểu `"i32"`, không có method/kế thừa) rồi tái dùng 100% pipeline record có
sẵn (`gen_record_types`/`record_feature.py`) — không có runtime wrapper
riêng. Đã port đồng thời cả 2 cây (không có sẵn ở cây nào trước đó), test
mới `release/3.code/Testkit/namedtuple_test.tkv` (3/3 PASS qua cả `.py` tree
và `tkvc.exe` thật), `native_test_suite.tkv` vẫn 16/16 không đổi. Lưu ý: cây
`.tkv` tự-host có resolver import THẬT riêng (khác cây `.py` chỉ bỏ qua
import) — `from collections import namedtuple` gây lỗi "module không tìm
thấy" ở cây `.tkv`, nên test file KHÔNG dùng câu import thật (ghi chú ngay
trong file test). **`defaultdict` ✅ XONG (phiên 5, cùng phiên với
`namedtuple`)** — kiểu shape mới `'defaultdict'` (`typed_dsl_parser.py`:
`defaultdict[K,V]`), vật lý dùng CHUNG `Dictionary<K,V>` với `dict` (xem
`il_type_str`) nhưng đọc `d[k]` khi THIẾU khóa sẽ tự gọi `factory` (bắt
buộc là 1 giá trị kiểu `func()->V` đã khai báo — tái dùng nguyên hạ tầng
first-class-function của Phase 3.3 qua `_resolve_func_ta`/
`compile_funcref_arg`, KHÔNG nhận tên hàm top-level trần trụi hay lambda
trực tiếp) rồi lưu+trả về, y hệt Python thật. File mới
`il_features/defaultdict_type.py` (cả 2 cây). Phạm vi thu hẹp có ý thức
(giống tinh thần `map`/`filter`): giá trị `V` chỉ vô hướng (không lồng
list/dict), khóa đọc `d[k]` chỉ nhận 1 biến/hằng số (không biểu thức phức
tạp, tránh biên dịch lại khóa 2 lần gây tác dụng phụ kép). Test mới
`release/3.code/Testkit/defaultdict_test.tkv` (4/4 PASS qua cả `.py` tree
và `tkvc.exe` thật), `native_test_suite.tkv` vẫn 16/16 không đổi.
**`Counter[K]` + `most_common(n)` ✅ XONG (phiên 5, cùng phiên)** — kiểu shape
mới `'counter'` (vật lý cũng `Dictionary<K,i32>`), KHÁC `defaultdict` ở hành
vi đọc thiếu khóa: trả `0` nhưng KHÔNG chèn key mới (đúng ngữ nghĩa Python
thật, không cần factory delegate). `most_common(c, n)` — sau khi được hỏi và
người dùng CHỌN trả đúng `list[(K,i32)]` giống Python thật (thay vì phương
án an toàn hơn "2 list song song") — cần mở rộng 3 điểm hạ tầng CHƯA TỪNG
dùng: (1) tuple LITERAL ở vị trí biểu thức (`newobj ValueTuple` giữa vòng
lặp), (2) khai báo local tường minh `list[(K,V)]` (mở rộng
`_lp_typed_local_decl`/Phase 3.3 vốn chỉ nhận `func`/`defaultdict`/`counter`),
(3) giải nén `k, v = lst[i]` khi `lst` là list-của-tuple (mở rộng
`tuple_assign`/`tuple_type.py` vốn chỉ nhận RHS là 1 lời gọi hàm trả tuple).
Thuật toán `most_common`: copy toàn bộ entries Dictionary ra 2
`List<K>`/`List<i32>` song song (dùng lại nguyên mẫu IL của
`codegen_for_in_dict_items`), rồi selection-sort THỦ CÔNG giảm dần theo
value (không có `List<T>.Sort()` với comparer theo value sẵn có). File mới
`il_features/counter_type.py` (cả 2 cây). Test mới
`release/3.code/Testkit/counter_test.tkv` (6/6 PASS, bao gồm kiểm tra thứ
tự sắp xếp đúng qua giải nén tuple, không chỉ độ dài list), `native_test_suite.tkv`
vẫn 16/16 không đổi — **TOÀN BỘ Phase 3 (3.1/3.2/3.3) nay đã XONG hoàn toàn.**
Phase 4 ⬜ (hoãn, chưa yêu cầu). Chi tiết đầy đủ từng bước (phạm vi thu hẹp,
bug phát hiện ngoài lề, số test PASS) xem `docs/NEXT_SESSION_HANDOFF.md`
(lưu ý: handoff là bàn giao/nhật ký phiên, KHÔNG phải kế hoạch — file này
mới là kế hoạch, luôn cập nhật lại đây sau mỗi phiên). Tổng kết nhanh:

- Phase 0: sửa `datetime_ticks`.
- Phase 1.1/1.2: `.format()`/`%`-format (macro text-level, giống f-string).
- Phase 1.3/1.4/1.5: `random.uniform/randrange`, `re_search/re_fullmatch`,
  `.find(sub,start)`/`.strip(chars)`.
- Phase 2.1: `zip()` trong for-header từ 2 lên N list.
- Phase 2.2: `path_isfile()`/`path_isdir()`.
- Phase 2.3: `dict.update()`, `math_pi()`/`math_e()`/`math_gcd()` (xác
  nhận `list.clear()` đã có sẵn từ trước, không phải gap thật).
- Phase 2.4 (Lựa chọn 3 người dùng chọn — lambda có biến tự do/closure
  thật): kiểm chứng qua probe `.il` độc lập trước
  (`scratch/probe_lambda_closure.il`, không track git — assemble+chạy
  bằng `ilasm.exe` trực tiếp, không qua compiler) rồi mới ghép vào
  `il_codegen.py`. Phát hiện + sửa 1 bug thật ngoài lề: tên class lambda
  từng bị trùng giữa các hàm khác nhau (dùng bộ đếm riêng từng hàm thay
  vì `id()` duy nhất toàn chương trình) — có thể khiến lambda ở hàm B
  "gọi nhầm" thân lambda của hàm A một cách ÂM THẦM (không báo lỗi) nếu
  không bị lộ ra bằng crash do sai chữ ký capture.
- **Phase 3.3** (người dùng chọn "first-class function values thật" —
  KHÔNG phải desugar về loop có sẵn): thêm cú pháp khai báo local có kiểu
  tường minh HOÀN TOÀN MỚI cho DSL (`f: "func(...)->..." = lambda/tên_hàm`
  — trước đó DSL không có cú phap khai báo kiểu tường minh nào cho local
  cả), tái dụng hạ tầng delegate `System.Func<>` có sẵn từ Phase 2.4 để
  cho phép lưu/gán lại/gọi lại nhiều lần. `map()`/`filter()`/`reduce()`
  xây trên nền đó — quyết định phạm vi (đã hỏi người dùng): `f` chỉ nhận
  tên hàm top-level hoặc biến kiểu `func` đã khai báo, KHÔNG nhận lambda
  trực tiếp tại chỗ gọi (lambda tự thân không mang kiểu). Mirror + rebuild
  `tkvc.exe` thật, phát hiện + sửa 1 regression thật khi test qua cây
  `.tkv` (nhánh mới ban đầu vỡ 1 tính năng closure-trả-về-từ-hàm đã có sẵn
  chỉ ở cây `.tkv`, không có ở cây `.py`).
- **Phase 3.1** (người dùng chọn "Full vtable + override"): PHÁT HIỆN cây
  `.tkv` tự-host đã có sẵn gần như toàn bộ thiết kế này từ trước (single
  inheritance thật + `@interface` mixin qua CIL interface + virtual
  dispatch/override + `super()`) — port NGUYÊN VẸN sang cây `.py` (không
  thiết kế lại), theo đúng lựa chọn "port, không tự thiết kế" người dùng
  chọn khi được hỏi. Phần thiếu thật ở cây `.py`: hỗ trợ nhiều base
  (`class Dog(Animal, Flyable, Swimmable):`), field/method-owner resolution
  qua BFS nhiều base, `super()` (phát hiện điểm dịch THẬT của
  `super().method()` nằm ở `string_join.py` chứ không phải
  `record_feature.py` như trực giác ban đầu — dễ port sai chỗ nếu không
  đọc kỹ parser).

- **Phase 3.2 (một phần) — `namedtuple`** (người dùng chọn "kiểu built-in
  mới hoàn chỉnh", không phải syntax sugar, và "từng kiểu một"): kiểm tra
  cả 2 cây trước (bài học Phase 3.1) — xác nhận KHÔNG có sẵn ở cây nào.
  Thiết kế: desugar `Name = namedtuple("Name", [...]/"...")` NGAY tại tầng
  parse (`_parse_program_ast`) thành field-list `(name, "i32")` rồi nạp
  thẳng vào CÙNG cấu trúc `record_defs`/`record_methods_raw`/`record_bases`/
  `record_interfaces` mà `class Foo:` bình thường tạo ra — 0 dòng codegen
  mới, tái dùng nguyên `gen_record_types`/`record_feature.py`. Ràng buộc
  cố ý: typename (tham số 1) phải TRÙNG tên biến gán (tránh 2 tên khác
  nhau gây nhầm lẫn khi đọc code — DSL không cần tính năng đó của Python
  thật). Bug/khác biệt phát hiện ngoài lề: cây `.tkv` tự-host có resolver
  `import`/`from...import` THẬT (khác cây `.py` chỉ bỏ qua) — `from
  collections import namedtuple` bị coi là cần tìm file `collections.tkv`
  và báo lỗi; test file né bằng cách không viết câu import thật (không
  phải bug cần sửa, hành vi cây `.tkv` là pre-existing, ngoài phạm vi).

- **Phase 3.2 (một phần) — `defaultdict`** (cùng phiên 5, sau `namedtuple`):
  kiểu shape MỚI `'defaultdict'` (`typed_dsl_parser.py`, cú pháp
  `defaultdict[K,V]`) — vật lý dùng CHUNG `Dictionary<K,V>` với `dict`
  (thêm `'defaultdict'` vào các nhánh `if type_ann.shape == 'dict':` cần
  thiết trong `il_type_str`/ghi qua chỉ số — hành vi GHI y hệt dict
  thường). CHỈ khác ở hành vi ĐỌC qua chỉ số (`d[k]`, file mới
  `il_features/defaultdict_type.py`): kiểm tra `ContainsKey` trước, nếu
  thiếu thì gọi `factory` (delegate `System.Func\`1<V>`, lưu vào 1 local
  ẩn riêng `__defaultdict_factory_<tên_biến>` khai báo lúc gán
  `defaultdict(factory)`) rồi `set_Item` trước khi `get_Item`. Quyết định
  thiết kế (đã hỏi người dùng): factory PHẢI là 1 giá trị kiểu `func()->V`
  ĐÃ khai báo tường minh trước (tái dùng nguyên `_resolve_func_ta`/
  `ctx['compile_funcref_arg']` từ Phase 3.3) — không nhận tên hàm
  top-level trần trụi (phát hiện: `_resolve_func_ta` dựa vào
  `except KeyError` để fallback sang tra `func_table` cho tên hàm
  top-level, nhưng `_Scope.__getitem__` thật ra ném `SyntaxError` chứ
  không phải `KeyError` — bug/gap tiềm ẩn CÓ SẴN từ Phase 3.3, chưa từng
  lộ ra vì mọi test map/filter/reduce trước giờ đều đi qua 1 biến kiểu
  `func` trung gian; KHÔNG sửa ở đây, ngoài phạm vi Phase 3.2 — ghi lại
  để phiên sau biết nếu cần factory nhận thẳng tên hàm top-level thì phải
  sửa gap này trước). Phạm vi thu hẹp có ý thức khác: giá trị `V` chỉ vô
  hướng (không lồng list/dict — auto-vivify-rồi-mutate kiểu
  `d[k].append(x)` cần thiết kế riêng phức tạp hơn, để lại sau); khóa đọc
  `d[k]` chỉ nhận 1 biến/hằng số (không biểu thức phức tạp, tránh biên
  dịch lại khóa 2 lần gây tác dụng phụ kép).

- **Phase 3.2 (phần cuối) — `Counter[K]` + `most_common(n)`** (sau khi
  người dùng được giải thích rõ đánh đổi giữa "2 list song song" (an toàn,
  ít rủi ro) và "`list[tuple]` giống Python thật" (rủi ro cần vá hạ tầng
  tuple-ở-vị-trí-biểu-thức chưa từng dùng) — CHỌN phương án 2). Đọc thiếu
  khóa trả `0` nhưng KHÔNG chèn key (khác `defaultdict`, không cần factory).
  `most_common`: copy Dictionary ra 2 list song song (tái dùng mẫu IL của
  `codegen_for_in_dict_items`), selection-sort thủ công giảm dần theo
  value, dựng `List<ValueTuple<K,i32>>` kết quả bằng `newobj` TRỰC TIẾP ở
  vị trí biểu thức (chưa từng làm trước đây — tuple trước giờ chỉ ở
  `return a,b`/`x,y=f()`). Mở rộng thêm 2 cơ chế để dùng được kết quả:
  khai báo local tường minh `list[(K,V)]` (thêm vào allowlist của
  `_lp_typed_local_decl`, Phase 3.3) và giải nén `k,v = lst[i]` (thêm 1
  nhánh mới vào `tuple_assign`/`fpw_tuple_assign` trong `tuple_type.py`,
  trước đó chỉ nhận RHS là 1 lời gọi hàm trả tuple). Bug tự phát hiện+sửa
  ngay trong lúc viết (chưa từng chạy, không phải regression): nhánh hoán
  đổi `vals[i]`/`vals[maxi]` trong selection-sort viết sai thứ tự toán
  hạng IL lúc đầu (copy-paste không cẩn thận từ nhánh `keys` bên cạnh) —
  phát hiện bằng cách đọc lại kỹ trước khi build, không phải qua debug
  runtime.

- **Phase 4 — `async`/`await`** (người dùng yêu cầu bắt đầu Phase 4,
  giao quyền chọn thứ tự — chọn `async`/`await` trước vì đã có sẵn thiết
  kế hoạt động ở cây `.tkv`, đúng pattern Phase 3.1): port `is_async`
  (`Signature`, `typed_dsl_parser.py`), parse `await`/`async def`
  (`il_core.py`, `tkv_compile.py`'s `_extract_signature_line`/
  `_parse_program_ast` mở rộng nhận `ast.AsyncFunctionDef`), bọc kiểu trả
  về `.method`/lời gọi thành `Task<T>` (`il_codegen.py`), bọc
  `Task.FromResult<T>()` trước `ret` (`control_flow.py`'s
  `codegen_return`), file mới `il_features/async_await.py`
  (`compile_await_expr` — `.get_Result()`). Mô hình GIẢ-bất-đồng-bộ
  (không state machine/continuation thật) — xem chi tiết ở mục Phase 4
  phía trên. **2 bug thật tự phát hiện+sửa trong lúc test** (CẢ 2 đều
  tồn tại SẴN ở thiết kế gốc cây `.tkv`, chưa từng lộ vì test gốc chỉ
  dùng 1 `await` đơn lẻ — sửa ĐỒNG THỜI cả 2 cây để giữ song song):
  (1) `await` dùng `parse_expr()` (ưu tiên thấp nhất) cho toán hạng thay
  vì `parse_factor()` (toán tử một ngôi), khiến `await f(5) + await
  f(10)` bị nuốt nhầm cấu trúc, sinh `add.ovf` trên 1 tham chiếu `Task`,
  `NullReferenceException` lúc chạy; (2) `_infer_dtype` thiếu nhánh cho
  tag `'await'`, khiến biến nhận kết quả `await` trong biểu thức phức
  hợp bị suy sai kiểu thành `'int'` (TkvInt) thay vì kiểu thật. Test mới
  `release/3.code/Testkit/async_await_py_tree_test.tkv` (3/3 PASS qua cả
  2 cây, gồm case combine 2 `await` trong 1 biểu thức — case bắt được cả
  2 bug trên), `native_test_suite.tkv` (gồm `async_await` gốc) vẫn 16/16.

- **Phase 4 — `isinstance()`/`type()`/`issubclass()`** (hỏi người dùng
  trước khi code — chọn "hỗ trợ cả scalar dtype đơn giản", không chỉ
  record): KHÔNG có sẵn ở cây `.tkv` nào (khác pattern async — phải tự
  thiết kế từ đầu, không port). Cả 3 hàm compile-fold thành hằng số ngay
  lúc biên dịch (không runtime check thật, đúng tinh thần static-typed
  của DSL): `isinstance`/`issubclass` → `ldc.i4.0`/`ldc.i4.1`, `type(obj)`
  → `ldstr "<dtype/record>"`. `isinstance(x, int/float/str)` so khớp
  `TypeAnn.dtype` (`int`↔{`i32`,`i64`,`int`}, `float`↔{`f32`,`f64`},
  `str`↔{`str`}; không có `bool` vì TokenVector không có dtype bool riêng
  — dùng `i32` cho boolean). `isinstance(obj, ClassName)`/
  `issubclass(A,B)` duyệt `record_bases` (tái dùng hạ tầng kế thừa có sẵn
  từ Phase 3.1, không thiết kế lại — hàm `_is_record_subclass` BFS qua
  chain kế thừa, kể cả đa kế thừa). File mới `il_features/typecheck.py`
  (cả 2 cây). Test mới
  `release/3.code/Testkit/typecheck_py_tree_test.tkv` (10/10 PASS qua cả
  `.py` tree và `tkvc.exe` thật, gồm scalar int/str đúng+sai, record
  isinstance chính lớp/lớp cha/anh em sai, issubclass đúng/sai/chính nó,
  `type()` trả tên record), `native_test_suite.tkv` vẫn 16/16 không đổi.

- **Phase 4 — `datetime` full object model** (hỏi người dùng trước khi
  code — chọn "kiểu datetime riêng" thay vì hàm tự do trên i64 ticks
  thô): 2 DTYPE mới `'datetime'`/`'timedelta'` (`typed_dsl_parser.py`),
  vật lý đều là `int64` ticks nhưng phân biệt ở tầng kiểu (dùng
  `_shape_key`=dtype cho method dispatch, giống cách `'str'` đã hoạt
  động — `d.strftime(fmt)` qua `register_expr_method`). `datetime_utcnow()`
  (ticks UTC thật — tái dùng nguyên mẫu IL đã có ở `stdlib_datetime.py`,
  không viết lại), `datetime_strptime(s, fmt)`, `timedelta_days/hours/
  minutes/seconds(n)` dịch ký hiệu Python (`%Y`/`%m`/`%d`/`%H`/`%M`/`%S`/
  `%B`/`%b`/`%A`/`%a`/`%I`/`%p`/`%%`) sang .NET custom format string NGAY
  LÚC BIÊN DỊCH (`fmt` bắt buộc CHUỖI HẰNG, không hỗ trợ biến — macro
  text-level, giống `.format()`/`%`-format Phase 1.1/1.2). Thu hẹp phạm
  vi có ý thức: `datetime +/- timedelta` KHÔNG dùng toán tử `+`/`-` tổng
  quát (né sửa binop dùng chung cho mọi dtype, rủi ro cao) — thay bằng 3
  hàm tự do `datetime_add`/`datetime_sub`/`datetime_diff`, thực chất chỉ
  là `add`/`sub` int64 THƯỜNG (không cần gọi BCL vì cả 2 đã cùng đơn vị
  ticks). Phát hiện xung đột tên NGAY khi khảo sát cây `.tkv` trước khi
  code (đúng bài học đã ghi ở Phase 4 async — không tin mù quáng, luôn
  đọc kỹ trước): `.tkv` đã có SẴN `datetime_now()` (`stdlib_bcl.tkv`, trả
  `str` theo giờ ĐỊA PHƯƠNG, không phải UTC/ticks, không test nào dùng) —
  đổi tên hàm mới thành `datetime_utcnow()` để không đè hàm cũ. File mới
  `il_features/datetime_type.py` (cả 2 cây, mirror y hệt — không phụ
  thuộc hạ tầng riêng cây nào). Test mới
  `release/3.code/Testkit/datetime_py_tree_test.tkv` (6/6 PASS qua cả 2
  cây: strftime roundtrip ngày/giờ, cộng/trừ timedelta, diff giữa 2
  datetime roundtrip lại đúng, `datetime_utcnow()` cộng timedelta 0 ngày
  không đổi giá trị), `native_test_suite.tkv` vẫn 16/16 không đổi. Ghi
  chú sửa lỗi lạc hậu: bug `datetime_ticks` trả hash (từng ghi trong kế
  hoạch là "chưa sửa") THỰC RA đã sửa ở commit `3423ef5` TỪ TRƯỚC phiên
  này — kế hoạch bị lạc hậu, không phải bug mới phát hiện phiên 5.

- **Phase 4 — Decorators tùy biến** (hạng mục CUỐI của Phase 4, sau khi
  cân nhắc giá trị/effort qua 2 agent creative+critical, người dùng bác
  kết luận ban đầu "bỏ qua" vì mục tiêu thật của TokenVector là THAY THẾ
  Python, không chỉ dạy học — tương thích cú pháp `@deco` quan trọng hơn
  tần suất sách): desugar THUẦN Ở TẦNG AST/macro biên dịch
  (`tkv_compile.py`/`.tkv`, KHÔNG dùng `func`-delegate/closure runtime).
  `@deco` trước 1 hàm top-level tương đương `f = deco(f)` — vì phạm vi
  bắt buộc `deco` là 1 TEMPLATE thuần tuý (thân chỉ gồm `def wrapper` lồng
  + `return wrapper`, không logic khác — `deco` KHÔNG BAO GIỜ thực sự
  được gọi lúc chạy), macro inline trực tiếp thân `wrapper` làm thân hàm
  công khai mới, đổi tên hàm gốc thành tên ẩn, đổi lời gọi tới tham số bị
  bắt bằng kỹ thuật regex-rename-theo-dạng-lời-gọi đã có sẵn từ
  `_hoist_nested_def`. Thu hẹp phạm vi: không tham số cho decorator, chữ
  ký phải khớp chính xác (kiểm cả 3 chiều: hàm gốc/wrapper/khai báo
  `func(...)->...` của `deco`), không hỗ trợ method/xếp chồng. Sửa thêm 1
  lỗ hổng liên đới: decorator không hỗ trợ trên hàm top-level trước đây bị
  ÂM THẦM BỎ QUA — nay báo lỗi rõ ràng. Test mới
  `release/3.code/Testkit/decorator_py_tree_test.tkv` (2/2 PASS qua cả 2
  cây NGAY LẦN BUILD ĐẦU), `native_test_suite.tkv` vẫn 16/16 không đổi —
  **PHASE 4 (4/4 HẠNG MỤC) NAY ĐÃ XONG HOÀN TOÀN.**

- **`logging` + `pickle`** (backlog niche, người dùng yêu cầu sau khi
  được giải thích ý nghĩa từng thư viện — chọn 2/4, bỏ `turtle`/`pdb`):
  `logging` → 5 hàm tự do theo cấp độ + `log_set_level(n)`, in
  `<LEVEL>:root:<msg>` khớp `logging.basicConfig()` mặc định, ngưỡng mặc
  định WARNING=30 (đúng số thật của Python). Cần state xuyên chương
  trình → tái dùng nguyên vẹn `ctx['extra_classes']`/`ctx['emitted_types']`
  (hạ tầng có sẵn từ `int_type.py`), thêm 1 class phụ `TkvLogging`.
  `pickle` → CHỈ scalar (i32/i64/f64/str), `pickle_dump_X(v,path)`/
  `pickle_load_X(path)->X` qua `BinaryWriter`/`BinaryReader`, định dạng
  TỰ ĐỊNH NGHĨA (không phải byte thật CPython pickle — chấp nhận được,
  chỉ cần round-trip đúng trong CHÍNH 1 runtime). Cả 2 dispatch qua
  `il_features/file_io.py`'s `codegen_call_stmt` (mở rộng elif chain có
  sẵn, giống `write_file`/`append_file`). File mới
  `il_features/logging_feature.py` + `il_features/pickle_feature.py`
  (cả 2 cây). Test mới
  `release/3.code/Testkit/logging_pickle_py_tree_test.tkv` (5/5 PASS qua
  cả `.py` tree và `tkvc.exe` thật NGAY LẦN BUILD ĐẦU), `native_test_suite.tkv`
  vẫn 16/16 không đổi.

**Tổng cộng đến hiện tại: 23 file test mới trong `Testkit/`
(`logging_pickle_py_tree_test.tkv` là file mới nhất), tất cả PASS 100%,
`native_test_suite.tkv` 16/16 không đổi qua toàn bộ quá trình (cả 5 phiên).
Phase 3 (3.1/3.2/3.3) VÀ Phase 4 (4/4 hạng mục) ĐỀU ĐÃ HOÀN TẤT 100%.**

**Còn lại chưa làm (theo đúng kế hoạch gốc)**:
- Các mục nhỏ từng bị thu hẹp phạm vi có ý thức (ghi trong từng commit,
  không lặp lại ở đây): `random.shuffle/sample/seed`,
  `re.findall/split/compile`, `.replace(old,new,count)`, `.format()`
  keyword args, `zip()`/`enumerate()` ở vị trí biểu thức độc lập,
  `os.path.splitext()`, `divmod()`, `map()`/`filter()`/`reduce()` nhận
  lambda trực tiếp (hiện chỉ nhận tên hàm/biến `func` đã khai báo).
- 2 bug phát hiện ngoài lề phiên 3 (không thuộc phạm vi kế hoạch gốc,
  ghi vào `docs/NEXT_SESSION_HANDOFF.md` mục 3 để theo dõi riêng):
  `print(list[int])` crash, `int(<int>)` thiếu nhánh ép kiểu `int`→`i32`.

## Phase 5 — Kế hoạch chi tiết các mục còn thiếu (chưa code, lập kế hoạch
trước theo Zero Assumptions Policy, cập nhật phiên 5, 2026-08-11)

Sau khi Phase 0-4 xong 100%, so sánh lại với 5 sách Python cho câu hỏi
"đã đạt mục tiêu TokenVector thay thế Python chưa" → **chưa hoàn toàn**.
Dưới đây là kế hoạch cụ thể cho từng mục còn thiếu, xếp theo tần suất
sách (cao → thấp). Thứ tự thực hiện đề xuất cho (các) phiên sau: 5.1 →
5.3 → 5.4 → 5.5 (5.2 đã xác nhận XONG, không cần code thêm).

### 5.1 `*args`/`**kwargs` — ưu tiên cao nhất, cần xác minh trước khi code
- **Trạng thái**: CHƯA XÁC NHẬN chắc chắn — grep sơ bộ ra 0 kết quả thật
  (1 match "chưa hỗ trợ *args" chỉ là docstring trong `stdlib_path.py`,
  không phải cài đặt). Việc đầu tiên của phiên sau: đọc kỹ
  `compiler/typed_dsl_parser.py` (hàm parse chữ ký `def`) và
  `compiler/il_codegen.py`'s `gen_il_function` để xác nhận CHẮC CHẮN có
  hay không, không suy đoán từ grep.
- **Nếu thật sự chưa có**: đây là thay đổi ở lõi ký hiệu hàm (`Signature`
  class, `_func_type_signature`, tham số/local slot trong
  `gen_il_function`) — rủi ro cao hơn các mục khác vì DSL dùng kiểu tĩnh
  (mỗi tham số có `-> "i32"` riêng) trong khi Python `*args`/`**kwargs`
  vốn là tập hợp động, độ dài bất kỳ. **Câu hỏi thiết kế bắt buộc hỏi
  người dùng trước khi code** (Zero Assumptions Policy): thu hẹp phạm vi
  thế nào — ví dụ chỉ hỗ trợ `*args: list[T]` đồng nhất 1 kiểu (không hỗ
  trợ `**kwargs` động), tương tự cách `map()`/`filter()` đã thu hẹp
  "chỉ nhận hàm đã khai báo kiểu, không nhận lambda tự do" ở Phase 3.3.
- Freq sách: cao — `BasicOfPythonProgramming.md`/`Python Tutorial.md`/
  `HowtocodeinPython3.md` đều có mục dành riêng.
- File dự kiến sửa (cả 2 cây): `compiler/typed_dsl_parser.py`,
  `compiler/il_codegen.py`, `tkv_compile.py` (parse
  `ast.arguments.vararg`/`kwarg`).

### 5.2 `collections` (`namedtuple`/`Counter`/`defaultdict`) — ĐÃ XONG,
chỉ là doc cũ ghi sai trạng thái
- Xác nhận lại phiên 5 (2026-08-11): **CẢ 3 ĐÃ CÓ CÀI ĐẶT THẬT**, không
  còn là "STILL OPEN" như doc trước đó ghi nhầm:
  - `namedtuple` — cú pháp thật `namedtuple("Name", [...])`/`"a b"`,
    nhận diện qua `_extract_namedtuple_def` (`tkv_compile.py:644`, gọi
    tại `:873`), test `namedtuple_test.tkv` xác nhận dùng cú pháp CPython
    thật (không phải bản rút gọn).
  - `Counter`/`defaultdict` — `compiler/il_features/counter_type.py`,
    test `counter_test.tkv`/`defaultdict_test.tkv`.
- Không cần code thêm. Việc còn lại chỉ là cập nhật
  `docs/PYTHON_VS_TOKENVECTOR_COMPARISON.md` dòng 191/254-256 (hiện ghi
  "❌ MISSING"/"STILL OPEN" — sai, cần sửa thành DONE) ở phiên khi có ai
  đó chỉnh sửa doc đó (không phải việc gấp, chỉ là dọn nợ tài liệu).

### 5.3 `itertools` thật (dạng biểu thức độc lập, không chỉ macro `for`)
- Hiện `enumerate`/`zip` chỉ hoạt động như macro mở rộng trong header
  `for` (`stdlib_itertools.py:22,41`), không phải hàm trả giá trị dùng
  được ở biểu thức bất kỳ (vd `list(enumerate(x))`, gán vào biến).
- **Câu hỏi thiết kế cần hỏi trước khi code**: có thêm kiểu trả về
  `list[tuple[...]]`/kiểu ghép cho `enumerate`/`zip` dạng biểu thức
  không (chi phí thiết kế kiểu lồng nhau), hay tiếp tục giữ dạng
  macro-only và chỉ mở rộng thêm các hàm itertools khác (`chain`,
  `product`) theo đúng dạng macro tương tự (rẻ hơn nhưng vẫn không phải
  itertools "thật" theo nghĩa CPython).
- Freq sách: thấp-vừa — chỉ "Python Tutorial.md mentions only".
- File dự kiến: `compiler/il_features/stdlib_itertools.py`.

### 5.4 `sys` module (`sys.argv`/`sys.exit`/`sys.path`)
- Hoàn toàn chưa có, chưa từng động tới.
- `sys.exit(code)` — rẻ, map thẳng `Environment.Exit(int32)`.
- `sys.argv` — cần đọc `il_codegen.py`'s codegen cho entry-point
  (`Main`) trước khi thiết kế, vì cần map vào `string[] args` của `Main`
  trong IL — ảnh hưởng tới cách chương trình biên dịch ra được gọi từ
  dòng lệnh, cần xác nhận không phá vỡ các chương trình hiện có không
  dùng `sys.argv` (entry point không tham số).
- `sys.path` — thấp giá trị, có thể bỏ qua hoặc trả về danh sách rỗng.
- Freq sách: vừa — `Python Tutorial.md`/`HowtocodeinPython3.md`/
  `BasicOfPythonProgramming.md` đều nhắc tới nhưng không phải chương
  riêng biệt.
- File dự kiến: `compiler/il_features/stdlib_sys.py` (file mới).

### 5.5 Batch các mục nhỏ đã thu hẹp phạm vi (độc lập, không chặn mục
tiêu chính, làm khi rảnh — mỗi mục 1 task nhỏ riêng)
- `random.shuffle/sample/seed` — cần thiết kế RNG engine bền (persistent
  state xuyên suốt chương trình) — tái dùng pattern static-class helper
  vừa dùng cho `logging` (`TkvLogging`, `compiler/il_features/
  logging_feature.py`'s `ensure_class`/`extra_classes`) để giữ seed/state.
- `re.findall/split/compile` — cần quyết định kiểu trả về
  (`list[str]`/"compiled regex object") trước khi code.
- `.replace(old,new,count)` — rẻ, thêm tham số thứ 3 optional vào
  `STR_METHODS`.
- `.format()` keyword args — mở rộng `string_format.py` (hiện chỉ hỗ trợ
  positional).
- `os.path.splitext()` — rẻ, thêm 1 hàm vào `stdlib_path.py`.
- `divmod()` — rẻ, thêm vào `_MATH_FUNCS` hoặc hardcode tương tự `abs`.

### Xác nhận KHÔNG làm (đã quyết định từ trước, ghi lại lý do để khỏi
phải hỏi lại mỗi phiên)
- `match`/`case`, walrus `:=` — không sách nào trong 5 sách dùng, ra
  ngoài phạm vi theo đúng phương pháp "chỉ làm cái sách thật sự cần".
- `turtle` — cần GUI canvas, ra ngoài phạm vi 1 compiler AOT-compile ra
  console/`.exe` tĩnh.
- `pdb` — vô nghĩa với chương trình đã biên dịch thành `.exe` tĩnh (không
  có REPL/interactive runtime để debug tương tác).

**Thứ tự đề xuất phiên sau**: bắt đầu 5.1 (`*args`/`**kwargs`) — đọc kỹ
code trước, hỏi người dùng câu hỏi thiết kế thu hẹp phạm vi, rồi mới
code. Nếu 5.1 tốn nhiều thời gian hơn dự kiến, có thể làm 5.5 (các mục
rẻ) song song/xen kẽ trước khi quay lại 5.1.

## Phase 6 — Rà soát bổ sung, KHÔNG trùng Phase 5 (phiên 5, 2026-08-11)

Người dùng yêu cầu rà soát kỹ lần nữa, cẩn thận, không sót — dùng agent
đọc trực tiếp `compiler/il_features/*.py` (không suy đoán từ tên file)
để tìm gap NGOÀI Phase 5. Kết quả: 10 gap thật sự, xếp theo mức độ quan
trọng (chương trình Python thực tế gặp thường xuyên đến hiếm).

### Mức cao (thường gặp trong code Python thật)

- **6.1 `global` statement** — CHƯA có đường parse/codegen nào xử lý
  `global x` trong hàm để gán lại biến module-level (chỉ có
  `closures.py` tự động bắt biến tự do khi ĐỌC/mutate-in-place, không
  xử lý gán lại tường minh qua từ khóa `global`). Rất phổ biến (counter,
  cờ config toàn cục). Effort trung bình — cần thêm cơ chế lưu trữ
  module-level + sửa codegen cho lệnh gán khi có `global`.
- **6.2 Hệ thống multi-file module** — KHÔNG có cơ chế resolve
  `import mymodule` / `from mymodule import x` cho file NGƯỜI DÙNG tự
  viết. Cây `.tkv` có bộ resolver import thật nhưng chỉ dùng để tự-host
  chính nó, không expose ra như 1 tính năng chung; cây `.py` bỏ qua
  hoàn toàn dòng import của file khác. Bất kỳ chương trình Python thực
  tế nào chia nhiều file đều KHÔNG biên dịch được. Effort lớn — cần
  thiết kế namespace/module thật, ảnh hưởng tới cách sinh entry point
  `.exe`. **Đây là gap lớn nhất còn lại đối với mục tiêu "thay thế
  Python"** — hầu hết dự án Python thật (ngoài script 1 file) đều chia
  module.
- **6.3 `raise` trần (re-raise) và `raise X from Y`** — `_RAISE_RE` ở
  `control_flow.py` chỉ khớp `raise Type(...)`, không có nhánh cho
  `raise` trần bên trong `except` (re-raise nguyên bản) hay exception
  chaining `from`. Rất phổ biến trong code xử lý lỗi thật. Effort
  trung bình — cần theo dõi "exception hiện tại" xuyên qua cấu trúc
  `.try/.catch` IL lồng nhau.
- **6.4 `input()` cho stdin tương tác** — hoàn toàn chưa có, không tìm
  thấy dấu vết nào trong toàn bộ `compiler/`. Cần cho bất kỳ chương
  trình CLI tương tác nào — thiếu thì "thay thế Python" cho mảng
  scripting/giáo dục vẫn yếu. Effort nhỏ — map thẳng
  `Console.ReadLine()`.

### Mức trung bình

- **6.5 Nạp chồng toán tử qua dunder method** — không tìm thấy
  `__eq__`/`__len__`/`__getitem__`/`__add__`/`__str__`/`__repr__` được
  hook vào dispatch; chỉ có `__init__` qua constructor của record. Lớp
  người dùng không override được `==`, indexing, `len()`, phép toán số
  học, hay tùy biến output của `print()`/`str()`. Phổ biến trong OOP
  Python idiomatic. Effort lớn — đụng vào dispatch toán tử và codegen
  `str()`/`print` trên diện rộng.
- **6.6 Context manager tùy biến (`__enter__`/`__exit__`)** — chỉ có
  `with open(...)` được đặc cách xử lý trong `control_flow.py`/
  `file_io.py`; không có protocol `with obj:` tổng quát cho lớp người
  dùng tự định nghĩa. Effort trung bình-lớn.
- **6.7 Iterator protocol tùy biến (`__iter__`/`__next__`)** — `for`
  chỉ chạy được trên list/dict/range/str dựng sẵn; lớp người dùng tự
  cài iterator protocol không thể dùng trong vòng `for`. Effort
  trung bình-lớn.
- **6.8 `frozenset`, `bytes`, `bytearray`, `complex`** — hoàn toàn
  không có, không tìm thấy dấu vết nào (`set` thường thì đã có, các
  kiểu "họ hàng" bất biến/byte thì chưa). Tần suất thấp-vừa nhưng là
  gap thật. Effort nhỏ-vừa mỗi kiểu (`frozenset` có thể tái dùng
  `set_type.py`; `bytes`/`bytearray` cần biểu diễn vật lý mới).
- **6.9 Bắt message/thuộc tính của exception KIỂU DỰNG SẴN qua `as e`**
  — `fpw_try` (trong `control_flow.py`) chủ động giới hạn
  `except E as e:` chỉ hoạt động với lớp exception NGƯỜI DÙNG TỰ ĐỊNH
  NGHĨA (ghi rõ trong code: "chỉ hỗ trợ với loại lỗi TỰ ĐỊNH NGHĨA").
  Bắt kiểu dựng sẵn như `except ValueError as e: print(e)` không lấy
  được message. Pattern phổ biến. Effort trung bình.

### Mức thấp / niche (chưa xác nhận là bug, cần test riêng)

- **6.10 MRO đa kế thừa khi có kim cương (diamond inheritance)** — kế
  hoạch Phase 3.1 ghi hỗ trợ multi-base qua duyệt BFS, nhưng CHƯA có
  bằng chứng thứ tự resolve đúng theo C3-linearization thật của Python
  khi 2 lớp cha có chung tổ tiên (trường hợp "kim cương"). Chưa xác
  nhận lỗi — cần viết 1 test riêng để kiểm tra, không phải gap đã xác
  nhận.
- `complex` numbers — không có, nhưng đúng phạm vi gốc của dự án (5
  sách tham chiếu hiếm dùng số phức), ưu tiên thấp theo tiêu chí chính
  dự án đã đặt ra.

### Không phát hiện lỗi ngữ nghĩa ẩn nào khác

Rà soát không tìm thêm hành vi "ngầm sai" nào ngoài những gì đã tự ghi
nhận trước đó (vd `int` overflow ném lỗi thay vì Python's unbounded int
— đây là đánh đổi thiết kế CÓ CHỦ Ý, đã ghi chú trong `int_type.py`,
không phải bug ẩn). Các phần sau đã xác nhận ĐÚNG, tốt hơn giả định ban
đầu của audit: ternary expression, so sánh cơ bản, `set`, `assert`,
exception tự định nghĩa có chuỗi kế thừa, nhiều `except` theo đúng thứ
tự khai báo, và `finally`.

**Thứ tự ưu tiên tổng hợp cho phiên sau (gộp Phase 5 + Phase 6)**:
6.2 (multi-file module — gap lớn nhất, ảnh hưởng rộng nhất tới mục tiêu
"thay Python") và 5.1 (`*args`/`**kwargs`) nên xếp ngang hàng ưu tiên
cao nhất; sau đó 6.1/6.3/6.4 (đều effort nhỏ-vừa, giá trị cao); rồi tới
6.5-6.9; 6.10 chỉ cần viết test xác minh trước khi quyết định có phải
làm hay không.

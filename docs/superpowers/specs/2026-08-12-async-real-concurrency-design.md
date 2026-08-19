# Async Real Concurrency — Design

## Bối cảnh

`async def`/`await` hiện tại (`compiler/il_features/async_await.py`,
`compiler/il_features/control_flow.py`'s `codegen_return`) là **vỏ đồng
bộ**: hàm `async def` chạy đồng bộ tới hết, kết quả bọc vào
`Task.FromResult<T>()` ngay trước `ret`; `await` chỉ gọi
`.get_Result()` trên 1 Task đã hoàn tất sẵn. Không có concurrency thật.

`docs/PYTHON_GAP_CHECKLIST.md` (mục 10, nghiên cứu Qwen3/Groq 2026-08-11)
xác định đây là ưu tiên #3 trong nhóm "giới hạn kiến trúc Loại 2" — .NET
IL có thread/Task OS thật (không GIL như CPython), effort thấp vì hạ
tầng có sẵn.

**Phát hiện quan trọng khi kiểm tra cây `.tkv` tự-host trước (bắt buộc
theo nguyên tắc chép/convert)**: `release/3.code/compiler/il_features/threading_feature.tkv`
đã có sẵn `thread_spawn`/`thread_join`/`thread_sleep` — dùng
`Task.Factory.StartNew<T>()` (KHÔNG phải `Task.Run<T>()`, xác minh THẬT
qua probe `.il` độc lập ghi trong file: `ilasm.exe` của project này lắp
ráp đối với `mscorlib` v4.0.30319, chưa có `Task.Run` — chỉ có từ .NET
4.5). Cây `.py` **hoàn toàn chưa có** module này — gap thật, cần chép
trước (Task 0), không phải thiết kế mới.

`thread_spawn(fn_name)` hiện tại chỉ hỗ trợ hàm target **0 tham số**
(`ldftn` thẳng tới static method, không có closure) — không đủ cho
`async def foo(params...)`. Phần closure-wrapping (mục "Kiến trúc" bên
dưới) là thiết kế mới thật sự cho gap này.

## Mục tiêu

`async def foo(params...) -> T:` (top-level và record method) chạy
THẬT SONG SONG trên 1 luồng ThreadPool khác, không còn đồng bộ giả.
`await` vẫn là 1 blocking join thật (không phải continuation/suspend
như C# `async` compiler-generated — bất khả thi vì compiler này phát
IL thô qua `ilasm.exe`, không qua `csc`) nhưng hàm callee THẬT SỰ chạy
song song với caller cho tới điểm `await` đó.

## Kiến trúc

### Task 0 — Port `threading_feature.py` (chép nguyên văn, không thiết kế)
Chép `release/3.code/compiler/il_features/threading_feature.tkv` sang
`compiler/il_features/threading_feature.py`, đổi `Task.Run` → xác nhận
lại đã dùng `Task.Factory.StartNew` (bản `.tkv` đã đúng, không cần sửa
gì thêm — chỉ dịch cú pháp `.tkv`→`.py` nếu có khác biệt cú pháp DSL tự
host, nếu không có gì khác biệt thì copy y hệt). Đăng ký qua
`register_expr_builtin` như bản gốc. Không đổi API/hành vi.

### Async function/method → closure tự chứa (tái dùng hạ tầng closures.py)

**Hàm 0 tham số (không `self`):**
Sinh 1 method static ẩn `{name}__body()->T` (thân hàm THẬT, kiểu trả về
`T` thô, KHÔNG bọc `Task.FromResult`). Method public `{name}()` trở
thành:
```
ldnull
ldftn {il_ret} {class_name}::{name}__body()
newobj instance void class [mscorlib]System.Func`1<{il_ret}>::.ctor(object, native int)
call class [mscorlib]System.Threading.Tasks.Task`1<!!0> [mscorlib]System.Threading.Tasks.Task::get_Factory()
... (StartNew<T> qua TaskFactory, giống compile_thread_spawn)
ret
```
Cụ thể dùng API `Task.Factory.StartNew<T>(Func<T>)` — CHÍNH XÁC pattern
đã có trong `compile_thread_spawn` (threading_feature.py, Task 0) — tái
dùng, không phát minh lại.

**Hàm/method có tham số và/hoặc `self` (record method):**
Sinh 1 class closure `{name}__AsyncBody` — TÁI DÙNG toàn bộ hạ tầng
`closures.py`/`gen_il_function(..., is_closure_method=True,
closure_captures=[...])` đã có cho nested `def`:
- 1 field mỗi tham số (mode `'direct'`, `il_type_str` của tham số đó —
  KHÔNG cần cell/boxed vì đây là bản sao giá trị tại thời điểm gọi,
  không phải chia sẻ/mutate qua tham chiếu ra ngoài).
- Nếu là record method: thêm field `'self'` (kiểu `self_type_ann`,
  cũng mode `'direct'`) — `closure_captures` đã hỗ trợ sẵn tên `'self'`
  qua `kind='closure_field'` (xem `_Scope`/`_load_var_ref` hiện có,
  không cần sửa).
- `.ctor` nhận đủ tham số (+ `self` nếu có) theo đúng 1 thứ tự cố định,
  gán field — giống hệt `_gen_closure_class_il` hiện có.
- Instance method `Invoke()->T` (0 tham số DSL) chứa thân hàm THẬT,
  sinh qua `gen_il_function(..., is_closure_method=True,
  closure_captures=..., pre_parsed_stmts=stmts)` — TÁI DÙNG NGUYÊN VĂN
  đường sinh code đã dùng cho nested-def closures, không viết codegen
  mới.
- Tại điểm khai báo `{name}(params...)`: `newobj` tạo instance closure
  (nạp params + self lên stack theo đúng thứ tự ctor), `ldftn`+`newobj
  Func<T>::.ctor` trỏ tới `Invoke`, gọi `Task.Factory.StartNew<T>`, `ret`
  giá trị `Task<T>` trả về (không bọc thêm gì nữa).

### `codegen_return`'s `is_async` branch — XÓA
`control_flow.py`'s `codegen_return` hiện có 2 nhánh `if
ctx.get('is_async')` bọc `Task.FromResult<T>()` trước `ret`/`leave`.
Sau thiết kế này, method `Invoke()`/`{name}__body()` là hàm THƯỜNG trả
`T` thô — `Task<T>` chỉ xuất hiện đúng 1 lần, tại điểm gọi
`Task.Factory.StartNew`. Xóa cả 2 nhánh (đơn giản hóa, không còn field
`ctx['is_async']` cần thiết trong `codegen_return` nữa — vẫn giữ
`ctx['is_async']` ở `gen_il_function` top-level để dispatch đúng nhánh
sinh closure-wrapper mới so với hàm thường).

### `await` — GIỮ NGUYÊN
`async_await.py`'s `compile_await_expr` không đổi — `callvirt ...
get_Result()` vẫn đúng ngữ nghĩa: join thật trên 1 `Task<T>` đang chạy
THẬT trên ThreadPool (trước đây Task đã hoàn tất sẵn nên get_Result()
không bao giờ thật sự block; giờ có thể block thật nếu callee chưa
xong — đúng hành vi `await` Python mong đợi).

## Phạm vi

- Top-level `async def` VÀ record method `async def self` (đã xác nhận
  với người dùng).
- Nested `async def` bên trong 1 hàm khác — NGOÀI phạm vi (không có
  test/hỗ trợ hiện tại, giữ nguyên chưa hỗ trợ).
- Tham số kiểu container (list/dict/set/tuple/record) dùng mode
  `'direct'` giống hệt cách `closures.py` xử lý capture kiểu tham
  chiếu — KHÔNG cần cell/boxed.
- Không hỗ trợ đọc lại exception nếu closure body ném lỗi qua biên
  Task (giới hạn có ý thức, giống threading_feature.tkv hiện tại — nếu
  worker ném exception, `.get_Result()` sẽ ném `AggregateException` bọc
  ngoài, KHÔNG unwrap — hành vi mặc định của .NET Task, không cần code
  thêm, nhưng thông báo lỗi cho DSL user sẽ khác Python thật).

## Kiểm chứng

- Test mới `threading_feature_py_tree_test.tkv` (Task 0, port
  nguyên văn thread_spawn/join/sleep) — xác nhận chạy đúng qua `.py`
  tree VÀ `tkvc.exe` thật.
- Test mới `async_concurrency_py_tree_test.tkv`: 2 lệnh gọi `async def`
  (mỗi hàm gọi `thread_sleep(300)` rồi trả về 1 giá trị đơn giản), gọi
  cả 2 KHÔNG `await` ngay (lưu 2 biến `Task`), sau đó `await` cả 2 rồi
  in kết quả (xác nhận đúng giá trị, không phải đo thời gian TRONG
  DSL — codebase hiện KHÔNG có API đo thời gian nào, xác nhận qua
  `native_test_suite.tkv`'s test `thread_spawn`/`thread_join` hiện có
  chỉ kiểm tra GIÁ TRỊ trả về, không đo thời gian). Việc đo thời gian
  song song thật (bằng chứng regression-guard chính) thực hiện Ở TẦNG
  HARNESS bên ngoài: script Python bọc `time.time()` quanh lời gọi
  `.exe` đã biên dịch, so sánh 1 biến thể "2 async gọi song song" với 1
  biến thể "2 lệnh gọi tuần tự thường (không async)" — assert biến thể
  song song có wall-clock GẦN 300ms (1 lần sleep), biến thể tuần tự GẦN
  600ms (2 lần sleep cộng dồn). Đây là task cụ thể sẽ viết ở Plan (không
  phải part của chính file `.tkv` test).
- Record-method async: 1 test method `async def compute(self, x: i32)
  -> i32:` trên 1 record đơn giản, xác nhận `self.field` đọc đúng bên
  trong `Invoke()` (qua `closure_field`).
- Regression toàn bộ Testkit/`native_test_suite` (đặc biệt file test
  `async_await` hiện có) không đổi qua cả `.py` tree và `tkvc.exe` thật
  (rebuild qua `build_tkvc.ps1`).
- Cả 2 cây `.py`/`.tkv` cùng sửa đồng bộ (theo đúng tiền lệ dự án).

## Ngoài phạm vi (ghi lại để khỏi hỏi lại)
- Continuation/suspend thật kiểu C# `async` compiler-generated — bất
  khả thi với kiến trúc phát IL thô qua `ilasm.exe` hiện tại.
- Unwrap `AggregateException` về đúng exception gốc khi `await` 1 Task
  bị lỗi — giữ hành vi mặc định .NET, không thêm xử lý.
- Nested `async def`.

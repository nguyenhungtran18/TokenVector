# random.shuffle/sample/seed — Design

## Bối cảnh

`compiler/il_features/stdlib_random.py` hiện có `random()`/`randint()`/
`uniform()`/`randrange()`/`choice()` — mỗi lời gọi tạo MỚI 1
`System.Random()` (`newobj instance void [mscorlib]System.Random::.ctor()`
ngay tại điểm gọi), KHÔNG có state chia sẻ nào giữa các lời gọi. Vì vậy
`random.seed(n)` KHÔNG THỂ hỗ trợ được với thiết kế hiện tại — không có
gì để "seed". Đây là mục đầu tiên trong batch 5.5 của
`docs/PYTHON_GAP_CHECKLIST.md`, đã ghi chú sẵn hướng đi ("cần thiết kế
RNG engine bền — persistent state — dùng lại pattern `TkvLogging`
static-class helper").

**Không có gì để chép ở cây `.tkv`** — cả 2 cây dùng chung
`stdlib_random.py`/`.tkv` với thiết kế "tạo Random mới mỗi lần gọi" y
hệt nhau (gap thật, thiết kế mới).

## Mục tiêu

Thêm `seed(n)`/`shuffle(lst)`/`sample(lst, k)`, và làm cho `seed()` THẬT
SỰ có tác dụng (mọi lời gọi random sau đó dùng chung 1 RNG engine đã
seed).

## Kiến trúc

### 1. `TkvRandom` — static helper class dùng chung (tái dùng mẫu `TkvLogging`)

Class mới, sinh 1 lần/chương trình qua `ensure_class(ctx)` (giống hệt
`logging_feature.py`'s `ensure_class`, dùng `ctx['extra_classes']`/
`ctx['emitted_types']` để dedupe):

```
.class public auto ansi beforefieldinit TkvRandom extends [mscorlib]System.Object
{
  .field private static class [mscorlib]System.Random rng
  .method public static class [mscorlib]System.Random Instance() cil managed
  {
    // neu rng == null: rng = new Random(); tra ve rng
  }
  .method public static void SetSeed(int32 n) cil managed
  {
    // rng = new Random(n)
  }
}
```

`Instance()` khởi tạo LƯỜI (lazy) — nếu `seed()` KHÔNG BAO GIỜ được gọi,
hành vi giống hệt hiện tại (seed ngầm theo `TickCount` của .NET, tại lần
gọi `random`/`randint`/... ĐẦU TIÊN trong chương trình, không phải mỗi
lần gọi — đây là điểm THAY ĐỔI DUY NHẤT so với hành vi cũ, xem mục "Thay
đổi hành vi" bên dưới).

### 2. 5 hàm random hiện có chuyển sang dùng `TkvRandom::Instance()`

`compile_random`/`compile_randint`/`compile_uniform`/`compile_randrange`/
`compile_choice` (`stdlib_random.py`) — thay MỌI `newobj instance void
[mscorlib]System.Random::.ctor()` bằng `call class [mscorlib]System.Random
TkvRandom::Instance()`. Không đổi logic gọi method sau đó
(`NextDouble()`/`Next(...)`) — chỉ đổi NGUỒN lấy instance.

### 3. `seed(n: i32)` — statement, không phải expression

```
call void TkvRandom::SetSeed(int32)
```
(giống mẫu `log_set_level`'s statement-style dispatch qua
`SYS_STMT_CODEGEN`/`LOG_STMT_CODEGEN`-tương-tự, KHÔNG phải
`register_expr_builtin`).

### 4. `shuffle(lst)` — Fisher-Yates SINH INLINE tại điểm gọi (KHÔNG dùng generic method tự viết)

**Sửa lại so với ý tưởng ban đầu (đã probe thật qua `ilasm.exe`, phát
hiện rủi ro thật trước khi chốt thiết kế)**: dự định ban đầu là 1
`TkvRandom::Shuffle<T>` generic method DÙNG CHUNG cho mọi dtype. Probe
độc lập (viết tay 1 file `.il` tối giản, gọi 1 generic method tự định
nghĩa qua cú pháp `call void class Helper::Shuffle<int32>(...)`) cho
thấy: `ilasm.exe` ASSEMBLE THÀNH CÔNG không báo lỗi, nhưng chạy THẬT ném
`MissingMethodException` — token generic-method-call không được mã hóa
đúng với cú pháp ilasm "ngây thơ" này. Codebase hiện tại CHƯA TỪNG tự
định nghĩa 1 generic method nào (mọi chỗ dùng generic trước giờ, kể cả
`Func\`1<T>`/`Task.Factory.StartNew<T>` ở plan Concurrency, đều GỌI
generic method CÓ SẴN của BCL, không phải tự viết) — đây là rủi ro CHƯA
XÁC MINH được trong thời gian cho phép của spec này.

**Quyết định**: BỎ generic method tự viết. `shuffle(lst)` sinh IL Fisher-
Yates NGAY TẠI ĐIỂM GỌI (không qua method dùng chung), dùng kiểu `List<T>`
CỤ THỂ đã biết tại compile-time qua `il_list_type(dtype, records)` — Y
HỆT cách `compile_choice` (đã hoạt động đúng, không rủi ro) tính
`list_type` hiện nay. Thuật toán: vòng lặp `for i in [len-1 .. 1]: j =
TkvRandom::Instance().Next(0, i+1); swap lst[i], lst[j]` — sinh trực
tiếp bằng `ldloc`/`callvirt get_Item`/`set_Item`/nhãn nhảy (`br`/`blt`),
giống các vòng lặp thủ công khác đã có trong `il_codegen.py`'s
`codegen_for`. `shuffle(lst)` yêu cầu `lst` là 1 BIẾN list đơn (giống
giới hạn hiện có của `choice(lst)`, KHÔNG hỗ trợ biểu thức phức tạp).

### 5. `sample(lst, k)` — CÙNG cách tiếp cận, sinh inline, trả list MỚI

Partial Fisher-Yates sinh INLINE (không generic method tự viết, lý do
giống mục 4): tạo 1 `List<T>` MỚI (bản sao `lst` qua `.ctor(IEnumerable)`
hoặc vòng lặp `Add` thủ công), xáo trộn `k` phần tử đầu bằng CÙNG thuật
toán mục 4, rồi cắt (`GetRange(0, k)`) lấy `k` phần tử đầu trả về —
KHÔNG sửa `lst` gốc (khớp ngữ nghĩa Python `random.sample` không mutate
list nguồn). Nếu `k > len(lst)`: để `GetRange`/truy cập chỉ số tự ném
lỗi `ArgumentException` của .NET (không tự viết exception message riêng
— giới hạn có ý thức, khác `ValueError` của Python thật nhưng chấp nhận
được, đúng tiền lệ dự án với các exception-type mismatch khác).

## Thay đổi hành vi (breaking, có chủ đích)

Trước đây: MỖI lời gọi `random()`/`randint()`/... tạo 1 `Random()` MỚI —
2 lời gọi RẤT GẦN NHAU (cùng `TickCount` ~15ms) CÓ THỂ trả cùng 1 giá trị
(bug đã ghi nhận trong docstring cũ). Sau thay đổi: CHỈ 1 `Random`
instance DÙNG CHUNG cho toàn chương trình (khởi tạo lười ở lần gọi đầu) —
sửa LUÔN bug này như 1 tác dụng phụ có lợi, không phải hồi quy.

## Phạm vi

- `shuffle`/`sample` CHỈ nhận 1 BIẾN list đơn làm tham số đầu (giống giới
  hạn `choice()` hiện có) — không biểu thức phức tạp.
- Không làm `random.seed()` không tham số (Python cho phép, seed theo
  system entropy) — CHỈ hỗ trợ `seed(n: i32)` bắt buộc có tham số (đủ cho
  test/reproducibility, use-case chính của seed trong code thật).
- Không hỗ trợ `random.choices()` (có trọng số, khác `choice()` số ít) —
  ngoài phạm vi batch 5.5 hiện tại.

## Kiểm chứng

- Test mới: `seed(42)` gọi 2 lần liên tiếp với CÙNG seed → cùng dãy giá
  trị `randint`/`random` (xác nhận seed thật sự có tác dụng, không phải
  chỉ không lỗi).
- `shuffle(lst)` — xác nhận list bị THAY ĐỔI TẠI CHỖ (cùng biến, thứ tự
  đổi, tổng/multiset phần tử không đổi).
- `sample(lst, k)` — xác nhận trả về đúng `k` phần tử, list gốc KHÔNG
  đổi, không trùng lặp phần tử (trừ khi list gốc có trùng).
- Regression toàn bộ `Testkit/*.tkv` qua `.py` tree — 5 hàm random cũ
  không đổi hành vi quan sát được (trừ điểm "Thay đổi hành vi" đã nêu,
  không có test nào phụ thuộc bug TickCount cũ).
- Cả 2 cây (`compiler/il_features/stdlib_random.py`/`.tkv`) sửa đồng bộ.

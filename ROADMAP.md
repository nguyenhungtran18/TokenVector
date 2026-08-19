# TokenVector - Lộ trình "Python tiến hóa thành TokenVector"

**LỊCH SỬ (checklist quá trình phát triển) — xem [README.md](README.md) và
[USAGE_GUIDE.md](USAGE_GUIDE.md) để biết tính năng hiện có đầy đủ nhất,
file này có thể thiếu các hạng mục hoàn tất gần đây (generator lazy,
web/DB, package ecosystem — xong 2026-07-29).**


Thứ tự ưu tiên (Critical Path → Core → Edge Case), mỗi bước verify bằng
compile+run THẬT đối chiếu CPython thật (kỷ luật đã áp dụng xuyên suốt),
không lý thuyết.

## Đã xong ✅
1. Nhiều hàm/1 chương trình gọi lẫn nhau (`gen_il_program`)
2. String thật (literal, nối chuỗi, `str()`, so sánh `==`/`!=`)
3. `while` + gán lại tham số (`starg.s`)
4. **List động** (`[]`, `.append()`, `[i]`, `len()` — dùng `List<T>` có sẵn,
   dtype phần tử suy từ `.append()` đầu tiên; xem STATUS.md để biết 2 bug
   thật đã sửa — regex `range(len(...))` và placeholder generic `!0`)
5. **Dict động** (`{}`, `d[k]=v`, `d[k]`, `key in d`, `len(d)` — dùng
   `Dictionary<K,V>` có sẵn, `!0`/`!1` cho khóa/giá trị; suy dtype chịu
   được gán tự tham chiếu — xem STATUS.md)
6. **break/continue** (mở rộng `for`/`while` có sẵn qua `loop_stack`; phát
   hiện + né giới hạn thật `/` trên i32 ≠ Python `/` — xem STATUS.md)
7. **try/except** (bare `except:` — mine cú pháp `.try`/`catch`/`leave`
   THẬT bằng 2 probe `.il` viết tay trước khi đụng codegen; cơ chế
   epilogue cho `return` bên trong try/except — xem STATUS.md)
8. **Self-host** (viết lại logic inference MLP của chính
   `tokenvector_compile.py` bằng DSL thô — không dùng macro
   dense/normalize/argmax — 150/150 khớp sklearn thật — xem STATUS.md)
9. **Đổi `.py` → `.tkv`** (`py_transpile.py`→`tkv_compile.py`, mọi file
   mẫu/test đổi đuôi; icon/metadata `.exe` để sau — xem STATUS.md)

## 🎉 ROADMAP HOÀN TẤT 9/9 — xem "Không làm" bên dưới cho phạm vi đã loại trừ

## Refactor nội bộ (không mở rộng ngôn ngữ)
10. **`il_codegen.py` → dispatch-table + tách theo `il_features/*.py`**
    (2026-07-28, 9 bước, xem `TokenVector/STATUS.md` phần Phase 1): 2855
    dòng → 1578 dòng, mỗi tính năng (list/set/dict/tuple/comprehension/
    string/operators/file_io/record/control_flow) có file riêng, dùng
    chung 1 registry (`il_dispatch.py`). API công khai không đổi. Đây là
    tiền đề kỹ thuật cho các tính năng mới bên dưới — thêm 1 tính năng
    ngôn ngữ giờ chỉ cần thêm 1 file `il_features/*.py` mới, không phải
    sửa 5 hàm if/elif khổng lồ như trước.

## Nghiên cứu Qwen3 2026-07-28 (`qwen3_research_reply_python_parity.md`) —
kết luận cho "tiến gần hơn thay Python", đã dùng để xếp lại ưu tiên bên
dưới (xem file gốc nếu cần lại lý luận đầy đủ, đây chỉ là tóm tắt hành động):
- **Closures**: kỹ thuật "display class" (giống C#) — sinh class ẩn giữ
  biến bị capture, tích hợp vào bước desugar AST trước codegen, không
  đụng dispatch-table chính. Độ khó trung bình-cao. Tiền đề cho decorator
  tổng quát + lambda/callback.
- **Decorator**: CÓ đường tắt rẻ — special-case `@staticmethod`/
  `@classmethod`/`@property` bằng AST transform thuần, KHÔNG cần chờ
  closure. Chỉ phủ ~20-30% use case thật (decorator tuỳ biến vẫn cần
  closure), nhưng đủ rẻ để làm trước closures nếu muốn quick win.
- **Generator/`yield`**: sinh class ẩn implement `IEnumerator<T>` (state
  machine tự sinh, giống C# compiler desugar) — CIL hỗ trợ native, khả
  thi nhưng khó hơn try/except đáng kể (phải phân tích luồng điều khiển
  tìm điểm resume + quản lý vòng đời object).
- **Kế thừa/đa hình**: bắt buộc đổi record từ `struct` (value type) sang
  `class` (reference type) + `callvirt` — phá vỡ mô hình "1 biến 1 dtype
  cố định" hiện tại, đây là thay đổi kiến trúc lớn nhất trong 4 tính
  năng, rủi ro cao nhất cho hiệu năng (heap alloc + GC thay vì stack).
- **`exec`/`eval`/kiểu động tuỳ ý**: **bức tường kiến trúc thật, không
  phải thiếu công sức** — mâu thuẫn trực tiếp với "suy dtype tĩnh lúc
  compile, không runtime riêng". Xác nhận loại bỏ VĨNH VIỄN (không phải
  "chưa làm", mà là "sẽ không bao giờ làm trong kiến trúc này").

## Cân nhắc kiến trúc (chưa quyết, có thể bàn tiếp nếu làm việc mới)
- **Có nên thay parser regex tự viết (`_ASSIGN_RE`, `_IF_RE`,...) bằng
  duyệt thẳng `ast` của Python?** Giảm code tự duy trì, nhưng là refactor
  lớn, rủi ro phá vỡ các test đang PASS. Chưa cấp thiết (mọi test đều
  đang PASS với parser regex hiện tại) — chỉ cân nhắc nếu có việc mới cần
  cú pháp phức tạp hơn nhiều so với regex có thể xử lý tốt.

## Việc còn để sau (không phải nợ của roadmap này)
- Icon/metadata `.exe` mang tên "TokenVector" (khả thi qua `ilasm
  /win32icon:...`, cần 1 file `.ico` thật chưa có — xem STATUS.md Bước 9).
- **Thư viện dùng chung (`.dll`)** (owner đề xuất 2026-07-28): tách các
  hàm TokenVector-tự-biên-dịch dùng CHUNG bởi nhiều chương trình `.tkv`
  khác nhau ra 1 file `.dll` riêng — các `.exe` khác chỉ `.assembly
  extern` tham chiếu + gọi vào, KHÔNG nhúng bản sao riêng của hàm đó.
  CLR đã tự lazy-load `.dll` khi thực sự gọi (cùng cơ chế .NET dùng cho
  `mscorlib`/`System.Core` hiện tại — đây là lý do `.exe` chỉ 4-6KB dù
  gọi nhiều API .NET, KHÔNG cần làm gì thêm cho phần đó). Phần CẦN làm
  thêm nếu theo hướng này: chỉ đáng giá khi có NHIỀU chương trình nhỏ
  dùng lại cùng 1 hàm (vd bộ 12 hàm toán học nếu đóng gói thành nhiều
  `.exe` riêng lẻ) — nếu mục tiêu vẫn là "1 chương trình → 1 `.exe` độc
  lập" (cách dùng hiện tại), lợi ích gần như không đáng kể. Chưa có kế
  hoạch cụ thể, ghi lại để xem xét khi có use-case rõ ràng.

## Không làm VĨNH VIỄN (xác nhận qua nghiên cứu 2026-07-28, không phải "chưa tới lượt")
- **`exec`/`eval` động, kiểu động tuỳ ý** — bức tường kiến trúc thật với
  mô hình static-dtype-lúc-compile + không runtime riêng (CLR duy nhất).
  Muốn hỗ trợ phải nhúng mini-interpreter (vd DLR của .NET), mâu thuẫn
  trực tiếp với mục tiêu cốt lõi của TokenVector.
- **`async`/`await`** — tương tự generator (state machine) nhưng cần
  thêm runtime coroutine/Task scheduling mạnh; chi phí/lợi ích quá kém so
  với các tính năng khác trong danh sách.

## Không làm (chưa tới lượt trong roadmap này, không phải "sẽ không làm")
- Decorator tổng quát (custom decorator nhận hàm bậc cao) — có đường tắt
  rẻ cho vài decorator built-in, xem mục "Nghiên cứu Qwen3" ở trên.
- Generator/`yield`, closures/hàm first-class, kế thừa/đa hình class —
  đều khả thi kỹ thuật (xem mục "Nghiên cứu Qwen3"), thứ tự ưu tiên
  triển khai xem task list.
- ~~Class/OOP~~ — **ĐÃ LÀM PHẦN LỚN** (2026-07-28): class dạng record
  (field + method thật, không kế thừa) đã xong, xem STATUS.md. Chỉ còn
  kế thừa/đa hình ngoài phạm vi hiện tại.

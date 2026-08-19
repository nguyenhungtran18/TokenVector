# .replace(old, new, count) — Design

## Bối cảnh

`compile_str_method_replace` (`compiler/il_features/string_methods_batch2.py:54`)
hiện chỉ nhận đúng 2 tham số, dispatch qua `TkvStr::Replace(string,string,string)`
(`compiler/il_features/tkvstr.py`) — helper tự viết vì `System.String::Replace`
của .NET ném `ArgumentException` khi `old=""`, còn Python coi hợp lệ (chèn
`new` xen giữa mỗi ký tự, kể cả đầu/cuối chuỗi). Đây là mục thứ 2 trong
batch 5.5b của `docs/PYTHON_GAP_CHECKLIST.md`.

## Mục tiêu

Thêm tham số thứ 3 optional `count` cho `.replace(old, new, count)` —
chỉ thay thế TỐI ĐA `count` lần khớp đầu tiên (tính từ trái sang), khớp
đúng ngữ nghĩa `str.replace()` của Python.

## Kiến trúc

### 1. `TkvStr::ReplaceCount(string src, string old, string new, int32 count)`

Helper mới trong `compiler/il_features/tkvstr.py`, thêm cạnh `Replace` đã
có (dùng `_m()` để sinh IL, cùng phong cách nhãn/vòng lặp).

**3 nhánh, theo thứ tự ưu tiên:**

1. **`count < 0`** → coi như KHÔNG giới hạn — gọi lại
   `TkvStr::Replace(src, old, new)` hiện có, TÁI DÙNG nguyên logic đã có
   (kể cả nhánh `old=""` của `Replace`). Khớp ngữ nghĩa Python: `count`
   âm nghĩa là thay hết, giống không truyền `count`.
2. **`old == ""`** → chèn `new` TRƯỚC mỗi ký tự của `src`, dừng sau khi
   đã chèn đủ `count` lần (kể cả gap SAU ký tự cuối nếu `count >
   len(src)`). Ví dụ xác nhận ngữ nghĩa: Python
   `'aaa'.replace('', '-', 2)` → `'-a-aa'` (chèn ở gap đầu và gap sau ký
   tự đầu, DỪNG — không chèn gap thứ 3). Dùng `StringBuilder`, vòng lặp
   chỉ số `i` chạy `[0, min(count, len(src)))`, mỗi bước
   `sb.Append(new); sb.Append(src[i])`; nếu `count > len(src)` thì thêm 1
   lần `sb.Append(new)` nữa SAU vòng lặp (gap cuối); cuối cùng
   `sb.Append(src.Substring(min(count, len(src))))` nối phần đuôi chưa
   động tới.
3. **`old != ""` và `count >= 0`** → vòng lặp tìm khớp bằng
   `String::IndexOf(string, int32)` (overload có tham số vị trí bắt đầu,
   đã có sẵn trong .NET, chưa từng dùng trong codebase — xác nhận chữ ký
   qua reflection trước khi dùng). Thuật toán:
   ```
   pos = 0; replaced = 0; sb = new StringBuilder()
   while replaced < count:
       idx = src.IndexOf(old, pos)
       if idx < 0: break
       sb.Append(src.Substring(pos, idx - pos))
       sb.Append(new)
       pos = idx + old.Length
       replaced = replaced + 1
   sb.Append(src.Substring(pos))
   return sb.ToString()
   ```
   `count == 0` → vòng lặp không chạy lần nào, trả nguyên `src` (qua
   `sb.Append(src.Substring(0))`).

### 2. Tầng DSL — `compile_str_method_replace` chấp nhận 2 hoặc 3 tham số

Sửa `compiler/il_features/string_methods_batch2.py`:
- `len(args) == 2` → giữ NGUYÊN hành vi cũ (gọi `TkvStr::Replace`), KHÔNG
  đổi gì.
- `len(args) == 3` → compile tham số thứ 3 dạng `i32`, gọi
  `TkvStr::ReplaceCount(string,string,string,int32)`.
- `len(args)` khác → `SyntaxError` như cũ (đổi thông báo lỗi cho khớp "2
  hoặc 3 tham số").

## Phạm vi

- Chỉ sửa `.replace(old, new, count)` — không đụng các method string
  khác trong cùng file (`upper`/`lower`/`strip`/`join`).
- Không hỗ trợ `count` là biểu thức phức tạp bất thường nào khác `i32` —
  dùng chung đường compile_expr sẵn có, không giới hạn thêm.

## Kiểm chứng

- Test mới: mở rộng file test string method hiện có (hoặc tạo mới trong
  `Testkit/`) — xác nhận:
  - `count` dương nhỏ hơn tổng số khớp (chỉ thay đúng N lần đầu, giữ
    nguyên phần còn lại).
  - `count` bằng 0 → không đổi gì.
  - `count` âm → thay HẾT (giống gọi `.replace(old, new)` không count).
  - `old=""` với `count` cụ thể → khớp ví dụ Python đã nêu ở trên
    (`'aaa'.replace('', '-', 2)` → `'-a-aa'`).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — `.replace(old, new)`
  2 tham số không đổi hành vi.
- Cả 2 cây (`compiler/il_features/{tkvstr,string_methods_batch2}.py`/`.tkv`)
  sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.

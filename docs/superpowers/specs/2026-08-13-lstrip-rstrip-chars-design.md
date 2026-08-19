# `.lstrip(chars)`/`.rstrip(chars)` — Design

## Bối cảnh

`.strip(chars)` đã hỗ trợ tham số `chars` tuỳ chọn từ 2026-08-11
(`string_methods_batch2.py:35-51`, `compile_str_method_strip`) —
`Trim(char[])` qua `chars.ToCharArray()`. `.lstrip()`/`.rstrip()`
(`string_methods_batch3.py:101-124`) hiện CHỈ nhận dạng KHÔNG tham số
(`ldnull` cứng trước `TrimStart(char[])`/`TrimEnd(char[])`) — truyền
bất kỳ tham số nào đều `raise SyntaxError`.

## Mục tiêu

`.lstrip(chars)`/`.rstrip(chars)` hoạt động giống hệt `.strip(chars)`
— bỏ TẤT CẢ ký tự có trong `chars` ở ĐẦU (`lstrip`)/CUỐI (`rstrip`)
chuỗi.

## Kiến trúc

Sửa `compile_str_method_lstrip`/`compile_str_method_rstrip`
(`string_methods_batch3.py`) — mirror ĐÚNG pattern
`compile_str_method_strip` đã có: nhận `len(args) in (0, 1)`, nếu có
1 tham số → `compile_expr(args[0], ..., 'str', ctx)` rồi
`callvirt instance char[] ...String::ToCharArray()` TRƯỚC
`TrimStart(char[])`/`TrimEnd(char[])` (thay vì `ldnull` cứng); nếu
0 tham số → giữ nguyên `ldnull` như hiện tại.

## Phạm vi

- Chỉ thêm tham số `chars` tuỳ chọn — không thay đổi hành vi 0-tham-số hiện có.

## Kiểm chứng

- Test: `"  xxHello Worldxx  ".lstrip(" x")` → `"Hello Worldxx  "`.
  `"  xxHello Worldxx  ".rstrip(" x")` → `"  xxHello World"`.
  Dạng 0-tham-số cũ vẫn PASS (regression).
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.

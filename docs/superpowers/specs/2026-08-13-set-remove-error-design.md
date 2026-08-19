# set.remove() ném lỗi khi thiếu phần tử — Design

## Bối cảnh

`compiler/il_features/set_methods_batch2.py` hiện có `set.remove(x)`/
`set.discard(x)` — CẢ HAI cùng dùng chung `_codegen_set_remove_like`,
ánh xạ `HashSet<T>::Remove(T)` (trả `bool`, BỊ CỐ Ý bỏ qua qua `pop`).
Đây là giới hạn đã ghi nhận trong docstring file: Python thật
`remove()` ném `KeyError` khi thiếu phần tử, `discard()` KHÔNG ném gì —
hiện tại cả 2 đều im lặng (hành vi giống `discard()` thật, `remove()`
là "giới hạn chưa giả lập `KeyError`"). Đây là mục CUỐI của batch 5.5b.

## Mục tiêu

`set.remove(x)` ném lỗi khi `x` không có trong set (khớp Python thật);
`set.discard(x)` giữ NGUYÊN hành vi im lặng hiện có.

## Kiến trúc

Tách `_codegen_set_remove_like` thành 2 nhánh theo `stmt['kind']`
(`'set_remove'` vs `'set_discard'` — đã có sẵn phân biệt qua
`register_stmt_codegen('set_remove', ...)`/`register_stmt_codegen('set_discard', ...)`,
2 kind gọi CHUNG 1 hàm hiện tại, giờ hàm đó tự rẽ nhánh theo `stmt['kind']`):

```
load_var_ref(name)
compile_expr(value_node)
callvirt bool HashSet<T>::Remove(!0)
if kind == 'set_discard':
    pop                          # GIU NGUYEN hanh vi cu, khong doi
else:  # 'set_remove'
    brtrue REMOVE_OK
    newobj instance void [mscorlib]System.Collections.Generic.KeyNotFoundException::.ctor()
    throw
  REMOVE_OK:
```

Không cần local ẩn — chỉ thêm 1 nhánh rẽ (`brtrue`/`throw`) ngay sau
`callvirt Remove`, không đụng first-pass/`_fpw_set_remove_like`.

## Giới hạn đã biết, có chủ đích

Ném `System.Collections.Generic.KeyNotFoundException` (loại exception
CLR gần nghĩa nhất với `KeyError` của Python — .NET không có exception
tên `KeyError`), KHÔNG tự viết message chứa giá trị phần tử thiếu (khác
Python thật `KeyError: <value>`) — chấp nhận sai khác nhỏ về loại/nội
dung exception, giống tiền lệ đã chấp nhận trước đó (`sample()`'s
`ArgumentException`, `TkvStr::RFind`'s hành vi lệch nhỏ).

## Kiểm chứng

- Test mới: `set.remove(x)` với `x` CÓ trong set — không ném lỗi, set
  giảm đúng 1 phần tử. `set.remove(x)` với `x` KHÔNG có — ném lỗi (xác
  nhận qua exit code khác 0/exception message khi chạy trực tiếp, hoặc
  bọc `try`/`except` nếu DSL hỗ trợ bắt exception loại `Exception`
  chung — kiểm tra cú pháp `try`/`except` hiện có trước khi viết test).
  `set.discard(x)` với `x` KHÔNG có — KHÔNG ném lỗi (giữ hành vi cũ,
  regression check).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — mọi chỗ dùng
  `set.remove()`/`set.discard()` hiện có (nếu có) không đổi hành vi khi
  phần tử TỒN TẠI (chỉ đổi hành vi khi phần tử THIẾU).
- Cả 2 cây (`compiler/il_features/set_methods_batch2.py`/`.tkv`) sửa
  đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
